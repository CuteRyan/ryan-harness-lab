#!/bin/bash
# Claude Code PreToolUse hook entry: DAST production 환경 차단
#
# 본체 = pretooluse-dast-prod-guard.py
# 근거 출처:
# - StackHawk ZAP guide (2026-03-04): "Active scans should always be run
#   against a pre-production build of the application."
# - NIST SP 800-115 (2008-09): "the potential exists for unexpected system halts
#   and other denial of service conditions."
# - namesilo CI/CD (2025): env prefix 없음 = production
# - agents/dast-analyzer.md: production 환경 테스트 절대 금지
#
# Day 20 turn 12 신설 (#026, PM 협의 PASS + audit PASS with conditions)

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || true
type harness_timer_start &>/dev/null && harness_timer_start
trap 'type harness_timer_stop &>/dev/null && harness_timer_stop "pretooluse-dast-prod-guard" || true' EXIT

INPUT=$(cat)

PY_SCRIPT="$SCRIPT_DIR/pretooluse-dast-prod-guard.py"
[ ! -f "$PY_SCRIPT" ] && PY_SCRIPT="$HOME/.claude/hooks/pretooluse-dast-prod-guard.py"
if [ ! -f "$PY_SCRIPT" ]; then
  exit 0
fi

echo "$INPUT" | python "$PY_SCRIPT"
exit $?
