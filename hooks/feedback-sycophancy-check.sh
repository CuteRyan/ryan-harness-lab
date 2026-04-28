#!/bin/bash
# Claude Code PostToolUse hook: /feedback 종합 보고서 sycophancy/환각/누락 검출
# - 매칭: docs/feedback/*-종합.md (Write/Edit/MultiEdit)
# - 차단형 X / 표시형 O (항상 exit 0)
# - 검출 0건이면 출력 0줄 (소음 최소화)
# - 검출 ≥1건: stdout에 카테고리별 짧게 표시 → 메인 Claude가 자기 검수
# - 본체는 동봉 Python 스크립트(feedback-sycophancy-check.py)에서 처리

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || exit 0
harness_timer_start
trap 'harness_timer_stop "feedback-sycophancy-check"' EXIT

INPUT=$(cat)

# stdin JSON 파싱
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

# Write/Edit/MultiEdit만 대상
case "$TOOL_NAME" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 매칭 패턴: docs/feedback/.*-종합\.md$
NORM_PATH=$(echo "$FILE_PATH" | tr '\\' '/')
if ! echo "$NORM_PATH" | grep -qE 'docs/feedback/[^/]*-종합\.md$'; then
  exit 0
fi

# 종합 보고 파일 미존재 시 silent skip
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# 키워드 사전
KEYWORDS_FILE="$SCRIPT_DIR/data/sycophancy-keywords.txt"
[ ! -f "$KEYWORDS_FILE" ] && KEYWORDS_FILE="$HOME/.claude/hooks/data/sycophancy-keywords.txt"
if [ ! -f "$KEYWORDS_FILE" ]; then
  harness_log "feedback-sycophancy-check" "skip" "no keywords file"
  exit 0
fi

# Python 본체
PY_SCRIPT="$SCRIPT_DIR/feedback-sycophancy-check.py"
[ ! -f "$PY_SCRIPT" ] && PY_SCRIPT="$HOME/.claude/hooks/feedback-sycophancy-check.py"
if [ ! -f "$PY_SCRIPT" ]; then
  harness_log "feedback-sycophancy-check" "skip" "no py script"
  exit 0
fi

# Python 호출 — stdout이 검출 결과
python "$PY_SCRIPT" --report "$FILE_PATH" --keywords "$KEYWORDS_FILE" 2>/dev/null || true

# 항상 exit 0 (차단 X)
exit 0
