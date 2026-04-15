#!/bin/bash
# Claude Code PreToolUse hook: .py 파일 Edit 시 venv 존재 확인
# venv가 없으면 경고 (차단은 아닌 soft guard)

# stdin에서 JSON 읽기
INPUT=$(cat)
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

# 파일 경로가 없으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Windows 백슬래시 → 슬래시 정규화
FILE_PATH=$(echo "$FILE_PATH" | tr '\\' '/')

# .py 파일이 아니면 통과
if [[ "$FILE_PATH" != *.py ]]; then
  exit 0
fi

# 프로젝트 루트 찾기 (pyproject.toml 또는 .git 기준)
CHECK_DIR=$(dirname "$FILE_PATH")
PROJECT_ROOT=""

while [ "$CHECK_DIR" != "/" ] && [ "$CHECK_DIR" != "." ]; do
  if [ -d "$CHECK_DIR/.git" ] || [ -f "$CHECK_DIR/pyproject.toml" ]; then
    PROJECT_ROOT="$CHECK_DIR"
    break
  fi
  CHECK_DIR=$(dirname "$CHECK_DIR")
done

# 프로젝트 루트를 못 찾으면 통과
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

# venv 존재 확인 (venv/ 또는 .venv/)
if [ -d "$PROJECT_ROOT/venv" ] || [ -d "$PROJECT_ROOT/.venv" ]; then
  exit 0
fi

# venv 없음 — 경고 (exit 0으로 차단하지 않되 메시지 표시)
echo "[hook] 경고: venv가 없습니다 — $PROJECT_ROOT" >&2
echo "[hook] 코딩 규칙: 모든 프로젝트는 반드시 venv를 생성하고 작업할 것" >&2
echo "[hook] 생성 명령: python -m venv \"$PROJECT_ROOT/venv\"" >&2
exit 0
