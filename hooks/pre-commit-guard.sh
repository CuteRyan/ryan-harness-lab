#!/bin/bash
# Claude Code PreToolUse hook: git commit 전 lint/test 통합 실행
# - staged Python 파일이 있으면 ruff check
# - tests/가 있고 venv python이 있으면 pytest
# - 도구가 없으면 차단하지 않고 통과

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || true
if command -v harness_timer_start >/dev/null 2>&1; then
  harness_timer_start
  trap 'harness_timer_stop "pre-commit-guard"' EXIT
fi

INPUT=$(cat)
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  exit 0
fi

PROJECT_ROOT="$GIT_ROOT"
cd "$GIT_ROOT" || exit 0

STAGED_PY=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.py$')

find_venv_tool() {
  local name="$1"
  for path in \
    "$GIT_ROOT/venv/Scripts/${name}.exe" \
    "$GIT_ROOT/.venv/Scripts/${name}.exe" \
    "$GIT_ROOT/venv/bin/${name}" \
    "$GIT_ROOT/.venv/bin/${name}"
  do
    if [ -f "$path" ]; then
      echo "$path"
      return 0
    fi
  done
  command -v "$name" 2>/dev/null
}

find_python() {
  for path in \
    "$GIT_ROOT/venv/Scripts/python.exe" \
    "$GIT_ROOT/.venv/Scripts/python.exe" \
    "$GIT_ROOT/venv/bin/python" \
    "$GIT_ROOT/.venv/bin/python"
  do
    if [ -f "$path" ]; then
      echo "$path"
      return 0
    fi
  done
  return 1
}

if [ -n "$STAGED_PY" ]; then
  RUFF=$(find_venv_tool ruff)
  if [ -n "$RUFF" ]; then
    echo "[hook] git commit 전 ruff 린팅 실행 중..." >&2
    LINT_OUTPUT=$($RUFF check $STAGED_PY 2>&1)
    LINT_RESULT=$?
    if [ $LINT_RESULT -ne 0 ]; then
      echo "[hook] ruff 린팅 실패 — 수정 후 커밋하세요:" >&2
      echo "$LINT_OUTPUT" | head -20 >&2
      exit 1
    fi
    echo "[hook] ruff 린팅 통과" >&2
  fi
fi

if [ -d "$GIT_ROOT/tests" ]; then
  PYTHON=$(find_python)
  if [ -n "$PYTHON" ]; then
    echo "[hook] git commit 전 pytest 실행 중..." >&2
    $PYTHON -m pytest tests/ -x -q 2>&1 | tail -5 >&2
    TEST_RESULT=${PIPESTATUS[0]}
    if [ $TEST_RESULT -ne 0 ]; then
      echo "[hook] pytest 실패 — 테스트 통과 후 커밋하세요" >&2
      exit 1
    fi
  fi
fi

exit 0
