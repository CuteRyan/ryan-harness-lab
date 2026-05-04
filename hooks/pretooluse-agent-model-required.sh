#!/bin/bash
# Claude Code PreToolUse hook: Agent/Task spawn 시 model 파라미터 강제
#
# 근거 (외부 출처 — rules/research-mandatory.md §3 인용 형식):
# - Issue #26923 (CLOSED, 2026-02-19~03-03, anthropics/claude-code):
#   "Agents that ran despite BLOCKED: 19 (100%)" — exit 2 가 Task 서브에이전트 호출 차단 못함
#   https://github.com/anthropics/claude-code/issues/26923
# - Issue #40580 (OPEN, 2026-03-29, anthropics/claude-code):
#   "Hook receives correct JSON input ... But the tool call proceeds anyway"
#   https://github.com/anthropics/claude-code/issues/40580
#
# 차단 메커니즘 (세계 1호 검증):
# - exit 2 단독 폐기 (위 버그로 무시됨, stdout JSON 도 함께 무시)
# - permissionDecision: deny JSON + exit 0 우회 (Issue #26923 reporter 미검증 가설)
#
# 본체는 동봉 Python 스크립트 (pretooluse-agent-model-required.py) 가 처리

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || true
type harness_timer_start &>/dev/null && harness_timer_start
trap 'type harness_timer_stop &>/dev/null && harness_timer_stop "pretooluse-agent-model-required" || true' EXIT

INPUT=$(cat)

PY_SCRIPT="$SCRIPT_DIR/pretooluse-agent-model-required.py"
[ ! -f "$PY_SCRIPT" ] && PY_SCRIPT="$HOME/.claude/hooks/pretooluse-agent-model-required.py"
if [ ! -f "$PY_SCRIPT" ]; then
  # 본체 미존재 시 silent skip — 다른 훅·도구에 영향 없음
  exit 0
fi

# Python 본체 호출 — 검사 + 차단 출력은 .py 가 담당
echo "$INPUT" | python "$PY_SCRIPT"
exit $?
