#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Claude Code PreToolUse hook — PM agent 의 R-19 면제 예외 영역 외부 리서치 차단.

검사 순위:
1. tool_name in ("WebSearch", "WebFetch") 가 아니면 즉시 통과
2. subagent_type != "pm" 이면 즉시 통과 (메인·다른 agent·미식별 全 통과 = 방어적)
   * subagent_type 식별: stdin 의 agent_type 은 spawn name (임의값) 가 들어오므로
     Team config 에서 agent_id 매칭하여 frontmatter agentType 추출 (옵션 E, Day 21 turn 1)
3. INTERNAL_META_KEYWORDS 매칭 0건이면 통과 (외부 사실 인용 영역으로 간주)
4. 매칭 1+건이면 차단 = permissionDecision:deny + exit 0 우회 (Issue #26923 검증 PASS)

근거 룰:
- ~/.claude/rules/research-mandatory.md section 1 (의무 조건) + section 4 (면제 예외)
- ~/.claude/agents/pm.md 핵심 행동 규칙 5번 + 외부 리서치 면제 예외 섹션
- 본 프로젝트 2026-05-05 Day 20 turn 10 R-19 신설 (사용자 정정 사례)
- 본 프로젝트 2026-05-06 Day 20 turn 12 R-20 정합 (β 변형 + Haiku 글로벌 금지)
- 본 프로젝트 2026-05-07 Day 21 turn 1 #028 (a) 진단 PASS — agent_type 의미 발견 + 옵션 E 적용

알려진 외부 버그 (rules/research-mandatory.md section 3 인용 형식):
- Issue #26923 (CLOSED, 2026-02-19~03-03): exit 2 가 Task 서브에이전트 호출 차단 못함
- Issue #40580 (OPEN, 2026-03-29): subagent PreToolUse 훅 exit code 무시
→ 본 훅은 permissionDecision: deny + exit 0 우회 패턴
   (turn 7 #018 + turn 8 #019 라이브 검증 PASS, fallback C+ 영구 적용)
"""

import sys
import io
import json
import re
import os

# 한글 메시지 깨짐 방지 (#029 R-15 후속, Day 21 turn 2)
os.environ.setdefault("PYTHONIOENCODING", "utf-8")
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")
except (AttributeError, ValueError):
    pass

# subagent_type 식별 helper (Day 21 turn 1 #028 옵션 E)
_HOOK_DIR = os.path.dirname(os.path.abspath(__file__))
_LIB_DIR = os.path.join(_HOOK_DIR, "lib")
if _LIB_DIR not in sys.path:
    sys.path.insert(0, _LIB_DIR)
try:
    from subagent_lookup import lookup_subagent_type
except ImportError:
    def lookup_subagent_type(agent_id="", spawn_name="", fallback=""):  # noqa: ARG001
        return fallback

WATCHED_TOOLS = ("WebSearch", "WebFetch")

# 면제 예외 영역 키워드 외부 파일 (Day 21 turn 1 #028 b — sycophancy-keywords.txt 양식 차용)
# 우선순위: hooks/data/pm-research-guard-keywords.txt → fallback hardcoded
_KEYWORDS_FILE = os.path.join(_HOOK_DIR, "data", "pm-research-guard-keywords.txt")

_HARDCODED_FALLBACK = [
    "HANDOFF",
    ".checklist.md",
    "체크리스트",
    "정합 grep",
    "세션 인계",
    "운영 정리",
    "메모리 정리",
    ".todo.md",
    "HISTORY.md",
]


def _load_keywords():
    """외부 파일 우선 + 부재 시 hardcoded fallback. 운영 sync 부담 최소화."""
    if not os.path.isfile(_KEYWORDS_FILE):
        sys.stderr.write(
            "[pretooluse-pm-research-guard] WARN: keywords file not found "
            "({}); using hardcoded fallback.\n".format(_KEYWORDS_FILE)
        )
        return list(_HARDCODED_FALLBACK)
    try:
        with open(_KEYWORDS_FILE, encoding="utf-8") as f:
            keywords = []
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                keywords.append(line)
        return keywords if keywords else list(_HARDCODED_FALLBACK)
    except Exception:
        return list(_HARDCODED_FALLBACK)


INTERNAL_META_KEYWORDS = _load_keywords()

# 추가 regex = "Day NN turn NN" 양식 (본 프로젝트 history 고유)
INTERNAL_META_REGEX = re.compile(r"Day \d+ turn \d+")


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0  # 입력 파싱 실패 = silent pass (다른 훅 영향 없음)

    # (1) Tool 무관 시 통과
    tool_name = data.get("tool_name", "") or ""
    if tool_name not in WATCHED_TOOLS:
        return 0

    # (2) PM agent 가 아니면 통과 (메인·다른 agent·미식별 全 통과 = 방어적)
    # subagent_type 식별 (Day 21 turn 1 옵션 E):
    #   1차: agent_id 정확 매칭 (Team config agentId, 가능성 낮음 — 내부 식별자 차이)
    #   2차: name 매칭 (stdin agent_type == config name = spawn 시 name 파라미터)
    #   3차: stdin agent_type fallback (Team 컨텍스트 부재 시)
    agent_id = data.get("agent_id", "") or ""
    raw_agent_type = data.get("agent_type", "") or ""
    subagent_type = lookup_subagent_type(
        agent_id=agent_id,
        spawn_name=raw_agent_type,
        fallback=raw_agent_type,
    )
    if subagent_type != "pm":
        return 0

    # (3) tool_input 합산 키워드 검색
    tool_input = data.get("tool_input") or {}
    search_text = " ".join([
        str(tool_input.get("query", "") or ""),
        str(tool_input.get("url", "") or ""),
        str(tool_input.get("prompt", "") or ""),
    ])

    matched = [kw for kw in INTERNAL_META_KEYWORDS if kw in search_text]
    if INTERNAL_META_REGEX.search(search_text):
        matched.append("Day NN turn NN")

    # (4) 매칭 0건 = 외부 사실 인용 영역 = 통과
    if not matched:
        sys.stderr.write(
            "[pretooluse-pm-research-guard] PASS "
            "(tool={}, subagent_type=pm, matched=0)\n".format(tool_name)
        )
        return 0

    # (5) 매칭 1+건 = R-19 위반 의심 = 차단
    reason = (
        "[BLOCKED] PM external research is restricted to external fact "
        "citations only (R-19).\n"
        "got: tool_name={}, subagent_type=pm, matched_keywords={}.\n\n"
        "R-19 (~/.claude/rules/research-mandatory.md section 4 + agents/pm.md):\n"
        "- 외부 리서치 의무 영역: 라이브러리·모범 사례·통계·공식 문서·CVE·표준\n"
        "- 면제 예외 영역: HANDOFF·history·체크리스트·정합 grep·운영 정리\n"
        "- 매칭 키워드 = 면제 예외 영역 시사 = R-19 위반 의심\n\n"
        "Override 3 옵션:\n"
        "(1) 사장(메인 Claude) 직접 WebSearch (PM 우회)\n"
        "(2) PM 키워드 회피 prompt 재시도 (예: HANDOFF -> session note format)\n"
        "(3) settings.json matcher 제거 (영구 비활성화)\n"
    ).format(tool_name, matched)

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
        "[pretooluse-pm-research-guard] Workaround: permissionDecision:deny "
        "+ exit 0 (Issue #26923, turn 7-8 PASS).\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
