#!/bin/bash
# Claude Code PreToolUse hook entry: PM agent R-19 외부 리서치 가드레일
#
# 본체 = pretooluse-pm-research-guard.py
# 근거 룰:
# - ~/.claude/rules/research-mandatory.md section 1 (의무) + section 4 (면제 예외)
# - ~/.claude/agents/pm.md 핵심 행동 규칙 5번
# - 2026-05-05 Day 20 turn 10 R-19 신설 (사용자 정정 사례)
# - 2026-05-06 Day 20 turn 12 본 hook 신설 (#027)
#
# 차단 메커니즘 (turn 7 #018 + turn 8 #019 라이브 검증 PASS):
# - permissionDecision: deny JSON + exit 0 우회 (Issue #26923 reporter 가설)

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || true
type harness_timer_start &>/dev/null && harness_timer_start
trap 'type harness_timer_stop &>/dev/null && harness_timer_stop "pretooluse-pm-research-guard" || true' EXIT

INPUT=$(cat)

PY_SCRIPT="$SCRIPT_DIR/pretooluse-pm-research-guard.py"
[ ! -f "$PY_SCRIPT" ] && PY_SCRIPT="$HOME/.claude/hooks/pretooluse-pm-research-guard.py"
if [ ! -f "$PY_SCRIPT" ]; then
  # 본체 미존재 시 silent skip — 다른 훅·도구에 영향 없음
  exit 0
fi

# Python 본체 호출 — 검사 + 차단 출력은 .py 가 담당
echo "$INPUT" | python "$PY_SCRIPT"
exit $?
