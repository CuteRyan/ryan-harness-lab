#!/usr/bin/env python
"""/feedback 3단계 정보 제공형 훅 본체.

종합 보고서를 읽어 7개 카테고리 의심 항목을 stdout으로 표시한다.
메인 Claude(또는 사용자)는 표시된 항목을 1개씩 다시 검토한다.

exit code 항상 0 (차단 X). 검출 0건이면 출력 0줄.
"""
from __future__ import annotations

import argparse
import io
import os
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    except Exception:
        pass


TOOLS = ["codex", "gemini", "claude-sub", "claude_sub", "claude"]

CRITICAL_MARK = re.compile(r"^\s*\[(?:치명|높음)\]")
COMBINED_MARK = re.compile(r"^\s*\[(?:반영|유보|반박)\]")
REBUTTAL_MARK = re.compile(r"^\s*\[반박\]")
ACCEPTED_MARK = re.compile(r"\[반영\]")

CODE_REF_WITH_LINE = re.compile(
    r"([\w./\\-]+\.(?:py|ps1|sh|md|json|js|ts|tsx|jsx|go|java|rs|rb|php|c|cpp|h|hpp|cs))"
    r":(\d+)(?:-(\d+))?",
    re.IGNORECASE,
)


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8")
    except Exception:
        try:
            return Path(path).read_text(encoding="utf-8-sig")
        except Exception:
            return ""


def load_keywords(path):
    out = []
    try:
        for line in Path(path).read_text(encoding="utf-8").splitlines():
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            out.append(s)
    except Exception:
        pass
    return out


def slug_from_combined(file_path):
    """종합 보고 파일명 → 슬러그 (날짜·도구·"-종합" 제외)."""
    name = Path(file_path).stem
    if name.endswith("-종합"):
        name = name[: -len("-종합")]
    parts = name.split("_", 2)
    if len(parts) >= 3 and re.match(r"^\d{4}-\d{2}-\d{2}$", parts[0]):
        if parts[1].lower() in TOOLS:
            return parts[2]
        return "_".join(parts[1:])
    return name


def find_first_round_reports(combined_path):
    """같은 슬러그의 1차 보고들 찾기. 같은 디렉토리, -종합.md 제외."""
    combined = Path(combined_path)
    slug = slug_from_combined(combined_path)
    if not slug:
        return {}
    folder = combined.parent
    if not folder.is_dir():
        return {}
    reports = {}
    for f in folder.glob("*.md"):
        if f.name.endswith("-종합.md"):
            continue
        if slug not in f.name:
            continue
        name_lower = f.name.lower()
        for tool in ["codex", "gemini", "claude-sub", "claude_sub"]:
            if f"_{tool}_" in name_lower or name_lower.startswith(f"{tool}_"):
                key = tool.replace("_", "-")
                reports.setdefault(key, str(f))
                break
    return reports


def extract_critical_items(text):
    items = []
    for i, line in enumerate(text.splitlines(), 1):
        if CRITICAL_MARK.match(line):
            items.append((i, line.strip()))
    return items


def detect_sycophancy_keywords(text, keywords):
    hits = []
    lines = text.splitlines()
    seen = set()
    for kw in keywords:
        kw_lower = kw.lower()
        for i, line in enumerate(lines, 1):
            if kw_lower in line.lower():
                key = (kw, i)
                if key in seen:
                    continue
                seen.add(key)
                hits.append((kw, i, line.strip()[:80]))
    return hits


def detect_hallucination(text, project_root):
    hits = []
    seen = set()
    for m in CODE_REF_WITH_LINE.finditer(text):
        file_ref = m.group(1).replace("\\", "/")
        line_start = int(m.group(2))
        line_end = int(m.group(3)) if m.group(3) else line_start
        key = (file_ref, line_start, line_end)
        if key in seen:
            continue
        seen.add(key)
        if os.path.isabs(file_ref):
            abs_path = file_ref
        else:
            abs_path = os.path.join(project_root, file_ref)
        if not os.path.isfile(abs_path):
            hits.append((file_ref, line_end, "미존재"))
            continue
        try:
            with open(abs_path, encoding="utf-8", errors="ignore") as f:
                line_count = sum(1 for _ in f)
        except Exception:
            continue
        if line_end > line_count:
            hits.append((file_ref, line_end, f"실제 {line_count}줄"))
    return hits


def _extract_tokens(line):
    tokens = []
    for m in CODE_REF_WITH_LINE.finditer(line):
        tokens.append(f"{m.group(1)}:{m.group(2)}")
    if tokens:
        return tokens
    words = re.findall(r"[\w가-힣]{4,}", line)
    stop = {"치명", "높음", "코드", "근거", "확인", "검토", "Critical", "High"}
    return [w for w in words if w not in stop][-2:]


def detect_omission(combined_text, first_round_reports):
    hits = []
    combined_lower = combined_text.lower()
    for tool, path in first_round_reports.items():
        text = read_text(path)
        if not text:
            continue
        for line_no, line in extract_critical_items(text):
            tokens = _extract_tokens(line)
            if not tokens:
                continue
            found = any(t.lower() in combined_lower for t in tokens)
            if not found:
                hits.append((tool, line_no, line[:80], tokens))
    return hits


def detect_sycophancy_transfer(combined_text, first_round_reports, keywords):
    hits = []
    combined_lower = combined_text.lower()
    has_accepted = bool(ACCEPTED_MARK.search(combined_text))
    if not has_accepted:
        return hits
    for tool, path in first_round_reports.items():
        text = read_text(path)
        if not text:
            continue
        text_lower = text.lower()
        kw_count = 0
        for kw in keywords:
            kw_count += text_lower.count(kw.lower())
        if kw_count < 5:
            continue
        if tool.lower() in combined_lower:
            hits.append((tool, kw_count))
    return hits


def detect_weak_rebuttal(combined_text):
    hits = []
    lines = combined_text.splitlines()
    blocks = []
    cur_start = None
    cur_lines = []
    for i, line in enumerate(lines, 1):
        if REBUTTAL_MARK.match(line):
            if cur_start is not None:
                blocks.append((cur_start, cur_lines))
            cur_start = i
            cur_lines = [line]
        elif cur_start is not None:
            if COMBINED_MARK.match(line) or i > cur_start + 25:
                blocks.append((cur_start, cur_lines))
                cur_start = None
                cur_lines = []
            else:
                cur_lines.append(line)
    if cur_start is not None:
        blocks.append((cur_start, cur_lines))
    for start, blk in blocks:
        joined = "\n".join(blk)
        if not CODE_REF_WITH_LINE.search(joined):
            first = blk[0].strip()[:80] if blk else ""
            hits.append((start, first))
    return hits


def detect_conflict_ignored(combined_text, first_round_reports):
    if len(first_round_reports) < 2:
        return []
    tool_critical_refs = {}
    for tool, path in first_round_reports.items():
        text = read_text(path)
        refs = set()
        if text:
            for line in text.splitlines():
                if CRITICAL_MARK.match(line):
                    for m in CODE_REF_WITH_LINE.finditer(line):
                        refs.add(f"{m.group(1)}:{m.group(2)}")
        tool_critical_refs[tool] = refs
    all_tools = list(tool_critical_refs.keys())
    if not any(tool_critical_refs.values()):
        return []
    union = set().union(*tool_critical_refs.values())
    hits = []
    for ref in sorted(union):
        markers = [t for t in all_tools if ref in tool_critical_refs[t]]
        if 1 <= len(markers) < len(all_tools):
            if ref not in combined_text:
                missing = [t for t in all_tools if t not in markers]
                hits.append((ref, markers, missing))
    return hits[:5]


def detect_weak_critique(first_round_reports):
    hits = []
    for tool, path in first_round_reports.items():
        text = read_text(path)
        if not text:
            continue
        for line_no, line in extract_critical_items(text):
            if not CODE_REF_WITH_LINE.search(line):
                hits.append((tool, line_no, line[:80]))
    return hits


def find_project_root(combined_path):
    p = Path(combined_path).resolve()
    cur = p.parent
    while cur != cur.parent:
        if (cur / "docs" / "feedback").is_dir() or (cur / ".git").is_dir() or (cur / "CLAUDE.md").is_file():
            return str(cur)
        cur = cur.parent
    return str(p.parent)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", required=True)
    parser.add_argument("--keywords", required=True)
    args = parser.parse_args()

    combined_text = read_text(args.report)
    if not combined_text:
        return 0

    keywords = load_keywords(args.keywords)
    if not keywords:
        return 0

    project_root = find_project_root(args.report)
    first_round_reports = find_first_round_reports(args.report)

    cat1 = detect_sycophancy_keywords(combined_text, keywords)
    cat2 = detect_hallucination(combined_text, project_root)
    cat3 = detect_omission(combined_text, first_round_reports) if first_round_reports else []
    cat4 = detect_sycophancy_transfer(combined_text, first_round_reports, keywords) if first_round_reports else []
    cat5 = detect_weak_rebuttal(combined_text)
    cat6 = detect_conflict_ignored(combined_text, first_round_reports) if first_round_reports else []
    cat7 = detect_weak_critique(first_round_reports) if first_round_reports else []

    total = len(cat1) + len(cat2) + len(cat3) + len(cat4) + len(cat5) + len(cat6) + len(cat7)
    if total == 0:
        return 0

    out = sys.stdout
    out.write(f"[feedback-check] 의심 항목 {total}건 (차단 아님 — 위 항목 1개씩 다시 검토 의무)\n")
    if cat1:
        preview = ", ".join(f'"{kw}" (line {ln})' for kw, ln, _ in cat1[:3])
        more = f" 외 {len(cat1)-3}건" if len(cat1) > 3 else ""
        out.write(f"  [1] sycophancy: {preview}{more}\n")
    if cat2:
        preview = ", ".join(f"{f}:{ln}->{note}" for f, ln, note in cat2[:3])
        more = f" 외 {len(cat2)-3}건" if len(cat2) > 3 else ""
        out.write(f"  [2] 환각: {preview}{more}\n")
    if cat3:
        preview = "; ".join(f"{tool} L{ln} '{line[:30]}...'" for tool, ln, line, _ in cat3[:3])
        more = f" 외 {len(cat3)-3}건" if len(cat3) > 3 else ""
        out.write(f"  [3] 누락: {preview}{more}\n")
    if cat4:
        preview = ", ".join(f"{tool}(키워드 {n}건)" for tool, n in cat4)
        out.write(f"  [4] 전이: {preview} 1차 + 종합 [반영] 처리 의심\n")
    if cat5:
        out.write(f"  [5] 약한반박: 종합 [반박] 항목 중 코드 인용 0건 = {len(cat5)}건\n")
    if cat6:
        preview = "; ".join(f"{ref} (only {','.join(m)})" for ref, m, _ in cat6[:2])
        more = f" 외 {len(cat6)-2}건" if len(cat6) > 2 else ""
        out.write(f"  [6] 충돌: {preview}{more}\n")
    if cat7:
        preview = "; ".join(f"{tool} L{ln}" for tool, ln, _ in cat7[:3])
        more = f" 외 {len(cat7)-3}건" if len(cat7) > 3 else ""
        out.write(f"  [7] 약한비판: 1차 [치명] 중 코드 인용 0건 = {preview}{more}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
