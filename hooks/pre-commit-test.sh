#!/bin/bash
# Claude Code PreToolUse hook: git commit 전 pytest 자동 실행
# tests/ 디렉토리가 있는 프로젝트에서만 동작

# stdin에서 JSON 읽기 (Claude Code 훅은 stdin으로 전달)
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

# tests/ 디렉토리가 없으면 통과
if [ ! -d "$GIT_ROOT/tests" ]; then
  exit 0
fi

# venv python 찾기
if [ -f "$GIT_ROOT/venv/Scripts/python.exe" ]; then
  PYTHON="$GIT_ROOT/venv/Scripts/python.exe"
elif [ -f "$GIT_ROOT/.venv/Scripts/python.exe" ]; then
  PYTHON="$GIT_ROOT/.venv/Scripts/python.exe"
elif [ -f "$GIT_ROOT/venv/bin/python" ]; then
  PYTHON="$GIT_ROOT/venv/bin/python"
elif [ -f "$GIT_ROOT/.venv/bin/python" ]; then
  PYTHON="$GIT_ROOT/.venv/bin/python"
else
  # venv 없으면 통과 (시스템 python으로 테스트 안 함)
  exit 0
fi

# pytest 실행
cd "$GIT_ROOT"
echo "[hook] git commit 전 pytest 실행 중..." >&2
$PYTHON -m pytest tests/ -x -q 2>&1 | tail -5 >&2
RESULT=${PIPESTATUS[0]}

if [ $RESULT -ne 0 ]; then
  echo "[hook] pytest 실패 — 테스트 통과 후 커밋하세요" >&2
  exit 1
fi

exit 0
