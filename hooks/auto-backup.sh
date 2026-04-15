#!/bin/bash
# Claude Code PreToolUse hook: Edit 전 자동 백업
# 수정 대상 파일을 프로젝트 .backups/ 폴더에 자동 복사
# 매 수정 전 덮어쓰기로 백업 — 항상 "직전 수정 전" 상태 1개만 유지

# stdin에서 JSON 읽기 (Claude Code 훅은 stdin으로 전달)
INPUT=$(cat)
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

# 파일 경로가 없거나 파일이 존재하지 않으면 통과 (새 파일)
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Windows 백슬래시 → 슬래시 정규화
FILE_PATH=$(echo "$FILE_PATH" | tr '\\' '/')

# git 프로젝트 루트 찾기 → .backups/ 위치 결정
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  # git 프로젝트가 아니면 파일과 같은 디렉토리 기준
  BACKUP_DIR="$(dirname "$FILE_PATH")/.backups"
else
  BACKUP_DIR="$GIT_ROOT/.backups"
fi

# .backups/ 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# 백업 파일명: 원본파일명.bak.확장자 (원본 확장자 유지, 항상 덮어쓰기)
BASENAME=$(basename "$FILE_PATH")
EXT="${BASENAME##*.}"
NAME="${BASENAME%.*}"
if [ "$EXT" = "$BASENAME" ]; then
  # 확장자 없는 파일
  BACKUP_PATH="$BACKUP_DIR/${BASENAME}.bak"
else
  # 확장자 유지: example.bak.md
  BACKUP_PATH="$BACKUP_DIR/${NAME}.bak.${EXT}"
fi

cp "$FILE_PATH" "$BACKUP_PATH"

# .gitignore에 .backups/ 추가 (없으면)
if [ -n "$GIT_ROOT" ]; then
  GITIGNORE="$GIT_ROOT/.gitignore"
  if [ -f "$GITIGNORE" ]; then
    grep -q "^\.backups/" "$GITIGNORE" 2>/dev/null || echo ".backups/" >> "$GITIGNORE"
  fi
fi

exit 0
