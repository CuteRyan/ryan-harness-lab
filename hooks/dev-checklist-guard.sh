#!/bin/bash
# dev-checklist-guard.sh
# 개발 체크리스트 강제 — 코드/설정 파일 Edit/Write 시 .dev-checklist.md 없으면 차단
#
# 목적: 하네스 엔지니어링 원칙 — 작업 전 체크리스트 필수
# 예외: 체크리스트 자체, 문서 파일, .backups/, CLAUDE.md, MEMORY.md, .gitignore,
#       __init__.py, conftest.py, setup.py, settings.json(훅 설정)

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || true
if command -v harness_timer_start >/dev/null 2>&1; then
  harness_timer_start
  trap 'harness_timer_stop "dev-checklist-guard"' EXIT
fi

# stdin에서 tool_input JSON 읽기 (Claude Code 훅은 stdin으로 전달)
INPUT=$(cat)
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  OLD_STRING=$(echo "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null)
  NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
  OLD_STRING=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('old_string',''))" 2>/dev/null)
  NEW_STRING=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('new_string',''))" 2>/dev/null)
  if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
  fi
fi

# 파일 경로가 없으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Windows 백슬래시 → 슬래시 정규화
FILE_PATH=$(echo "$FILE_PATH" | tr '\\' '/')

# === 예외 파일/경로 (체크리스트 불필요) ===

# 체크리스트 파일 자체 수정은 통과
if [[ "$FILE_PATH" == *".dev-checklist.md"* || "$FILE_PATH" == *".doc-checklist.md"* ]]; then
  exit 0
fi

# .backups/ 내 파일은 통과 (백업 작업)
if [[ "$FILE_PATH" == *"/.backups/"* || "$FILE_PATH" == *".backups/"* ]]; then
  exit 0
fi

# 인프라/설정/메타 파일은 통과
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  __init__.py|conftest.py|setup.py|.gitignore|.env|.env.example|CLAUDE.md|MEMORY.md|settings.json|review_prompt.md)
    exit 0
    ;;
esac

# 문서 파일은 doc-checklist-guard.sh가 담당한다.
# docs/ 작업에서 dev/doc 체크리스트를 모두 요구하면 작업 비용만 늘어난다.
case "$FILE_PATH" in
  *.md|*.rst|*.txt|*.doc|*.docx|*/docs/*|*/rules/*|*/.claude/rules/*)
    exit 0
    ;;
esac

# memory/ 디렉토리 파일은 통과 (메모리 관리)
if [[ "$FILE_PATH" == */memory/* || "$FILE_PATH" == */.claude/* ]]; then
  exit 0
fi

# 프로젝트 루트 찾기 — 파일 경로 기준
PROJECT_ROOT=""
CHECK_DIR=$(dirname "$FILE_PATH")
CHECKLIST=$(harness_find_upward "$CHECK_DIR" ".dev-checklist.md")
PROJECT_ROOT=$(harness_project_root_for_path "$FILE_PATH")

# 프로젝트 루트를 못 찾으면 — CWD를 루트로 사용
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$PWD"
fi

# 체크리스트가 없으면 프로젝트 루트 위치를 기준으로 안내
if [ -z "$CHECKLIST" ] && [ -f "$PROJECT_ROOT/.dev-checklist.md" ]; then
  CHECKLIST="$PROJECT_ROOT/.dev-checklist.md"
fi

if command -v harness_tiny_edit_allowed >/dev/null 2>&1 && harness_tiny_edit_allowed "$TOOL_NAME" "$OLD_STRING" "$NEW_STRING"; then
  harness_log "dev-checklist-guard" "tiny-exempt" "$FILE_PATH"
  exit 0
fi

if [ -n "$CHECKLIST" ]; then
  if harness_validate_checklist "$CHECKLIST" "dev"; then
    exit 0
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "BLOCKED: 개발 체크리스트 품질 검증 실패"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "이유: $CHECKLIST_ERROR"
  echo ""
  echo "필수 조건:"
  echo "  - 승인 마커: status: approved / approved: true / - [x] 승인"
  echo "  - 섹션: 구현 항목, 수정 대상 파일, 검증 항목, 더블 체크"
  echo "  - 체크박스 항목 3개 이상"
  echo "  - 한 단어짜리 형식 항목 금지"
  echo ""
  echo "파일: $FILE_PATH"
  echo "체크리스트 위치: $CHECKLIST"
  exit 2
fi

# 차단!
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "BLOCKED: 코드 수정 전 체크리스트 필수"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "이유: 하네스 엔지니어링 — 의도→실행→검증 순환 필수"
echo "  규칙: ~/.claude/rules/dev-checklist.md"
echo ""
echo "다음 단계:"
echo "  1. .dev-checklist.md 생성 (프로젝트 루트)"
echo "  2. 포함: 구현 항목 + 수정 파일 + 검증 항목 + 더블 체크"
echo "  3. 주인님 승인 후 코드 수정"
echo "  상세 절차: docs/workflows/dev-checklist.md"
echo ""
echo "파일: $FILE_PATH"
echo "체크리스트 위치: $PROJECT_ROOT/.dev-checklist.md"
exit 2
