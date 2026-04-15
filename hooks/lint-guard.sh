#!/bin/bash
# Claude Code PreToolUse hook: git commit 전 ruff 린팅 자동 실행
# tests/ 또는 .py 파일이 있는 프로젝트에서 ruff가 설치되어 있으면 동작

# stdin에서 JSON 읽기
INPUT=$(cat)
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

# git commit 명령이 아니면 통과
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# 프로젝트 루트 찾기 (git root)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  exit 0
fi

# .py 파일이 하나도 없으면 통과 (Python 프로젝트가 아님)
PY_COUNT=$(find "$GIT_ROOT" -maxdepth 3 -name "*.py" -not -path "*/venv/*" -not -path "*/.venv/*" 2>/dev/null | head -1)
if [ -z "$PY_COUNT" ]; then
  exit 0
fi

# ruff 찾기 (venv 우선)
RUFF=""
if [ -f "$GIT_ROOT/venv/Scripts/ruff.exe" ]; then
  RUFF="$GIT_ROOT/venv/Scripts/ruff.exe"
elif [ -f "$GIT_ROOT/.venv/Scripts/ruff.exe" ]; then
  RUFF="$GIT_ROOT/.venv/Scripts/ruff.exe"
elif [ -f "$GIT_ROOT/venv/bin/ruff" ]; then
  RUFF="$GIT_ROOT/venv/bin/ruff"
elif [ -f "$GIT_ROOT/.venv/bin/ruff" ]; then
  RUFF="$GIT_ROOT/.venv/bin/ruff"
elif command -v ruff &>/dev/null; then
  RUFF="ruff"
else
  # ruff 미설치 — 통과 (차단하지 않음)
  exit 0
fi

# staged된 .py 파일만 대상
cd "$GIT_ROOT"
STAGED_PY=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.py$')
if [ -z "$STAGED_PY" ]; then
  exit 0
fi

# ruff check 실행 (staged .py 파일만)
echo "[hook] git commit 전 ruff 린팅 실행 중..." >&2
LINT_OUTPUT=$($RUFF check $STAGED_PY 2>&1)
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "[hook] ruff 린팅 실패 — 수정 후 커밋하세요:" >&2
  echo "$LINT_OUTPUT" | head -20 >&2
  exit 1
fi

echo "[hook] ruff 린팅 통과" >&2
exit 0
