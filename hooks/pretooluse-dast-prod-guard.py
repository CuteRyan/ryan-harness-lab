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
- namesilo CI/CD 가이드 (2025, https://www.namesilo.com/blog/en/domain-names/domain-naming-conventions-ci-cd):
  "If your staging environment sometimes uses staging.example.com and sometimes
  example.com/stage, you're setting yourself up for confusion—and possibly downtime."
  → exclude_patterns 의 staging/dev/test/qa/uat/preview/preprod 정확 prefix 의무 정합
- agents/dast-analyzer.md 권한 범위: "production 환경 테스트 절대 금지"
- 2026-05-07 Day 21 turn 1 #028 (a) 라이브 검증 PASS — 4 검증 全 PASS (verifier-4 v2 spawn,
  옵션 E subagent_lookup helper 적용 후) = production URL 차단 + staging URL exclude 통과

근거 룰:
- 본 프로젝트 2026-05-06 Day 20 turn 12 #026 신설 (PM 협의 PASS + audit PASS)
- exclude_patterns: dast-analyzer 외부 리서치 의무 도메인 (R-19 정합) = portswigger/owasp/cve/nvd/zaproxy
- 본 프로젝트 2026-05-07 Day 21 turn 1 #028 (a) 진단 PASS — agent_type 의미 발견 + 옵션 E 적용

subagent_type 식별 (Day 21 turn 1 옵션 E):
- stdin 의 agent_type 은 spawn name (임의값) 가 들어오므로 frontmatter name 과 다름
- Team config (~/.claude/teams/*/config.json) 의 members[].agentType 에서 정확한 식별값 추출
"""

import sys
import io
import json
import os

# 한글 메시지 깨짐 방지 (#029 R-15 후속, Day 21 turn 2)
os.environ.setdefault("PYTHONIOENCODING", "utf-8")
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")
except (AttributeError, ValueError):
    pass

# helper import (subagent 식별 + URL 차단 검사)
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

WATCHED_TOOLS = ("WebFetch",)
DAST_AGENTS = ("dast-analyzer",)


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

    # (4)~(6) helper 호출 = exclude 우선 + production 매칭 + 보수적 디폴트
    blocked, matched_pattern, exclude_matched = check_url(url)
    if exclude_matched:
        sys.stderr.write(
            "[pretooluse-dast-prod-guard] PASS via exclude "
            "(agent_type=dast-analyzer, url={}, pattern={})\n".format(
                url, exclude_matched
            )
        )
        return 0
    if not blocked:
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
