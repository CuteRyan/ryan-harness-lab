#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Claude Code PreToolUse hook — DAST production 환경 차단.

검사 순위:
1. tool_name in ("WebFetch",) 가 아니면 즉시 통과
2. agent_type not in ("dast-analyzer",) 이면 즉시 통과 (R-12 차원 분리: SAST/compliance/security-reviewer 무관)
3. tool_input.url 부재 시 통과
4. EXCLUDE_PATTERNS 매칭 (allowlist 우선) → 통과
5. PRODUCTION_PATTERNS 매칭 → 차단 (permissionDecision:deny + exit 0 우회, Issue #26923)
6. 매칭 X → 통과 (보수적 디폴트)

근거 출처:
- StackHawk ZAP guide (2026-03-04): "Active scans should always be run against
  a pre-production build of the application."
- NIST SP 800-115 (2008-09): "Any time that a test or tester directly interacts
  with a system or network, the potential exists for unexpected system halts
  and other denial of service conditions."
- namesilo CI/CD 가이드 (2025): env prefix 없음 = production
- agents/dast-analyzer.md 권한 범위: "production 환경 테스트 절대 금지"

근거 룰:
- 본 프로젝트 2026-05-06 Day 20 turn 12 #026 신설 (PM 협의 PASS + audit PASS)
- exclude_patterns: dast-analyzer 외부 리서치 의무 도메인 (R-19 정합) = portswigger/owasp/cve/nvd/zaproxy
- 본 프로젝트 2026-05-07 Day 21 turn 1 #028 (a) 진단 PASS — agent_type 의미 발견 + 옵션 E 적용

subagent_type 식별 (Day 21 turn 1 옵션 E):
- stdin 의 agent_type 은 spawn name (임의값) 가 들어오므로 frontmatter name 과 다름
- Team config (~/.claude/teams/*/config.json) 의 members[].agentType 에서 정확한 식별값 추출
"""

import sys
import json
import re
import os

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

WATCHED_TOOLS = ("WebFetch",)
DAST_AGENTS = ("dast-analyzer",)

# GAP-A: .kr 단독 TLD 추가 (auditor 권장)
PRODUCTION_PATTERNS = [
    re.compile(r"^https?://api\.[\w-]+\.(com|io|net|co\.kr)/"),
    re.compile(r"^https?://prod\."),
    re.compile(r"^https?://www\."),
    re.compile(r"^https?://([\w-]+)\.(com|io|net|co\.kr|org)/"),
    re.compile(r"^https?://[\w.-]+\.kr/"),
]

# GAP-B: dast-analyzer 외부 리서치 도메인 (R-19 정합) 명시 추가
EXCLUDE_PATTERNS = [
    re.compile(r"(staging|stage|dev|test|qa|uat|preview|preprod)\."),
    re.compile(r"\.(internal|local|test|localhost)"),
    re.compile(r"^https?://(127\.0\.0\.1|localhost|0\.0\.0\.0)"),
    re.compile(r"^https?://10\.|^https?://172\.(1[6-9]|2\d|3[01])\.|^https?://192\.168\."),
    re.compile(r"portswigger\.net"),
    re.compile(r"owasp\.org"),
    re.compile(r"cve\.mitre\.org"),
    re.compile(r"nvd\.nist\.gov"),
    re.compile(r"zaproxy\.org"),
]


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool_name = data.get("tool_name", "") or ""
    if tool_name not in WATCHED_TOOLS:
        return 0

    # subagent_type 식별 (Day 21 turn 1 옵션 E):
    #   1차: agent_id 정확 매칭 / 2차: name 매칭 / 3차: stdin agent_type fallback
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
    url = str(tool_input.get("url", "") or "")
    if not url:
        return 0

    # (4) exclude_patterns 우선 평가 (allowlist)
    for pat in EXCLUDE_PATTERNS:
        if pat.search(url):
            sys.stderr.write(
                "[pretooluse-dast-prod-guard] PASS via exclude "
                "(agent_type=dast-analyzer, url={}, pattern={})\n".format(
                    url, pat.pattern
                )
            )
            return 0

    # (5) production_patterns 매칭
    matched_pattern = None
    for pat in PRODUCTION_PATTERNS:
        if pat.search(url):
            matched_pattern = pat.pattern
            break

    # (6) 매칭 X = 통과 (보수적 디폴트)
    if not matched_pattern:
        sys.stderr.write(
            "[pretooluse-dast-prod-guard] PASS "
            "(agent_type=dast-analyzer, url={}, no production match)\n".format(url)
        )
        return 0

    # (7) 차단
    reason = (
        "[BLOCKED] DAST production environment access is restricted (R-DAST-PROD).\n"
        "got: tool_name=WebFetch, agent_type=dast-analyzer, url={}\n"
        "matched production pattern: {}\n\n"
        "Reason (sources):\n"
        "- StackHawk ZAP guide (2026-03-04): \"Active scans should always be run "
        "against a pre-production build of the application.\"\n"
        "- NIST SP 800-115 (2008-09): \"Any time that a test or tester directly "
        "interacts with a system or network, the potential exists for unexpected "
        "system halts and other denial of service conditions.\"\n"
        "- presets/security.yaml dast-analyzer focus_areas: production 절대 금지\n\n"
        "Override 3 옵션:\n"
        "(1) URL 을 staging/dev/test/local 환경으로 변경\n"
        "    (예: api.example.com -> staging.api.example.com)\n"
        "(2) presets/security.yaml enforcement.exclude_patterns 에 명시 추가\n"
        "    (주인님 컨펌 의무, R-5 정합)\n"
        "(3) settings.json matcher 제거 (영구 비활성화, 권장 X)\n"
    ).format(url, matched_pattern)

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
        "[pretooluse-dast-prod-guard] Workaround: permissionDecision:deny "
        "+ exit 0 (Issue #26923, turn 7-8 PASS).\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
