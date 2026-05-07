#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Claude Code PreToolUse hook — DAST production 환경 차단 (Bash 영역).

본 hook 은 pretooluse-dast-prod-guard.py (WebFetch) 의 자매 hook.
Bash 명령(curl/wget/nmap/nikto/sqlmap/zap-cli)에 production URL/도메인이
들어가면 차단. 비-DAST 명령(ls/git/python 등) + non-DAST agent 는 즉시 통과.

검사 순위:
1. tool_name != "Bash" → 통과
2. agent_type != "dast-analyzer" → 통과 (R-12 차원 분리)
3. command 시작이 DAST_TOOLS 가 아니면 통과 (false positive 방지)
4. command 에서 URL/도메인 추출 → exclude 우선 → production 매칭 → 차단

근거:
- 본 프로젝트 Day 21 turn 2 #028 (d) — Bash matcher 확장 (옵션 B + R-22 helper 추출)
- 한글 메시지 UTF-8 강제 (#029 R-15 후속 정합)
- Issue #26923 + #40580 우회 패턴 (permissionDecision: deny + exit 0)
"""

import sys
import io
import os
import json
import re

# 한글 메시지 깨짐 방지 (#029 R-15 후속, 양 hook 공통)
os.environ.setdefault("PYTHONIOENCODING", "utf-8")
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")
except (AttributeError, ValueError):
    pass

# helper import
_HOOK_DIR = os.path.dirname(os.path.abspath(__file__))
_LIB_DIR = os.path.join(_HOOK_DIR, "lib")
if _LIB_DIR not in sys.path:
    sys.path.insert(0, _LIB_DIR)
try:
    from subagent_lookup import lookup_subagent_type
    from dast_url_check import check_url
except ImportError:
    def lookup_subagent_type(agent_id="", spawn_name="", fallback=""):  # noqa: ARG001
        return fallback

    def check_url(url):  # noqa: ARG001
        return False, None, None

DAST_AGENTS = ("dast-analyzer",)
DAST_TOOLS = ("curl", "wget", "nmap", "nikto", "sqlmap", "zap-cli", "httpie")

URL_RE = re.compile(r"https?://[^\s'\"`<>]+")
DOMAIN_RE = re.compile(
    r"\b([a-z0-9][\w-]*(?:\.[a-z0-9][\w-]*)*\.[a-z]{2,})\b",
    re.IGNORECASE,
)


def is_dast_command(command):
    parts = command.strip().split()
    if not parts:
        return False
    cmd = parts[0].split("/")[-1].split("\\")[-1]
    return cmd in DAST_TOOLS


def extract_targets(command):
    """URL/도메인 추출. 중복 제거. 도메인은 https:// 보정."""
    targets = []
    seen = set()
    for url in URL_RE.findall(command):
        u = url.rstrip(".,;:")
        if u not in seen:
            targets.append(u)
            seen.add(u)
    for m in DOMAIN_RE.finditer(command):
        d = m.group(1).lower()
        normalized = "https://" + d + "/"
        already_in_url = any(d in t.lower() for t in targets)
        if normalized not in seen and not already_in_url:
            targets.append(normalized)
            seen.add(normalized)
    return targets


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool_name = data.get("tool_name", "") or ""
    if tool_name != "Bash":
        return 0

    agent_id = data.get("agent_id", "") or ""
    raw_agent_type = data.get("agent_type", "") or ""
    subagent_type = lookup_subagent_type(
        agent_id=agent_id,
        spawn_name=raw_agent_type,
        fallback=raw_agent_type,
    )
    if subagent_type not in DAST_AGENTS:
        return 0

    tool_input = data.get("tool_input") or {}
    command = str(tool_input.get("command", "") or "")
    if not command:
        return 0

    if not is_dast_command(command):
        sys.stderr.write(
            "[pretooluse-dast-prod-guard-bash] PASS "
            "(non-DAST command, agent_type=dast-analyzer, cmd_start={})\n".format(
                command.split()[0] if command.strip() else ""
            )
        )
        return 0

    targets = extract_targets(command)
    if not targets:
        sys.stderr.write(
            "[pretooluse-dast-prod-guard-bash] PASS (no URL/domain extracted)\n"
        )
        return 0

    blocked_targets = []
    for target in targets:
        blocked, matched_pattern, _exclude_matched = check_url(target)
        if blocked:
            blocked_targets.append((target, matched_pattern))

    if not blocked_targets:
        sys.stderr.write(
            "[pretooluse-dast-prod-guard-bash] PASS "
            "(targets={}, all exclude or no production match)\n".format(targets)
        )
        return 0

    targets_summary = "\n".join(
        "  - {} (pattern: {})".format(t, p) for t, p in blocked_targets
    )
    reason = (
        "[BLOCKED] DAST production 환경 Bash 접근 차단 (R-DAST-PROD-BASH).\n"
        "got: tool_name=Bash, agent_type=dast-analyzer\n"
        "blocked targets:\n{}\n\n"
        "Reason (sources):\n"
        "- StackHawk ZAP guide (2026-03-04): \"Active scans should always be run "
        "against a pre-production build of the application.\"\n"
        "- NIST SP 800-115 (2008-09): \"the potential exists for unexpected "
        "system halts and other denial of service conditions.\"\n"
        "- presets/security.yaml dast-analyzer focus_areas: production 절대 금지\n\n"
        "Override 3 옵션:\n"
        "(1) URL/도메인을 staging/dev/test 환경으로 변경\n"
        "(2) presets/security.yaml enforcement.exclude_patterns 에 명시 추가\n"
        "(3) settings.json Bash matcher 에서 본 hook 제거 (영구 비활성화, 권장 X)\n"
    ).format(targets_summary)

    response = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    sys.stdout.write(json.dumps(response, ensure_ascii=False))
    sys.stdout.write("\n")
    sys.stderr.write(reason + "\n")
    sys.stderr.write(
        "[pretooluse-dast-prod-guard-bash] Workaround: permissionDecision:deny "
        "+ exit 0 (Issue #26923, turn 7-8 PASS).\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
