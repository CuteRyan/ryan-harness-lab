#!/bin/bash
# Claude Code PreToolUse hook entry: DAST production 차단 (Bash 영역)
#
# 본체 = pretooluse-dast-prod-guard-bash.py
# 자매 hook = pretooluse-dast-prod-guard.sh (WebFetch 영역)
#
# 근거: 본 프로젝트 Day 21 turn 2 #028 (d) — Bash matcher 확장
# 한글 fix 정합: #029 R-15 (PYTHONIOENCODING + io.TextIOWrapper 양 hook 공통)

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || true
type harness_timer_start &>/dev/null && harness_timer_start
trap 'type harness_timer_stop &>/dev/null && harness_timer_stop "pretooluse-dast-prod-guard-bash" || true' EXIT

INPUT=$(cat)

PY_SCRIPT="$SCRIPT_DIR/pretooluse-dast-prod-guard-bash.py"
[ ! -f "$PY_SCRIPT" ] && PY_SCRIPT="$HOME/.claude/hooks/pretooluse-dast-prod-guard-bash.py"
if [ ! -f "$PY_SCRIPT" ]; then
  exit 0
fi

echo "$INPUT" | python "$PY_SCRIPT"
exit $?
