#!/bin/bash
# Claude Code PreToolUse hook: docs/ 파일 수정 시 체크리스트 존재 강제
# 체크리스트(.doc-checklist.md) 없이는 docs/ 하위 파일 Edit 불가
# 더블 체크 미완료 시 체크리스트 삭제 불가

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || true
if command -v harness_timer_start >/dev/null 2>&1; then
  harness_timer_start
  trap 'harness_timer_stop "doc-checklist-guard"' EXIT
fi

# stdin에서 JSON 읽기 (Claude Code 훅은 stdin으로 전달)
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
fi

# 파일 경로가 없으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Windows 백슬래시 → 슬래시 정규화 (case 패턴 매칭용)
FILE_PATH=$(echo "$FILE_PATH" | tr '\\' '/')

# docs/ 하위 파일인지 확인 (docs/, .claude/rules/ 포함)
IS_DOC=false
case "$FILE_PATH" in
  */docs/*) IS_DOC=true ;;
  */rules/*.md) IS_DOC=true ;;
  */.claude/rules/*) IS_DOC=true ;;
esac

if [ "$IS_DOC" = false ]; then
  exit 0
fi

# .doc-checklist.md 자체를 수정하는 건 허용 (체크리스트 작성/업데이트)
case "$FILE_PATH" in
  */.doc-checklist.md) exit 0 ;;
esac

# 프로젝트 루트 찾기 — 파일 경로 기준으로 탐색한다.
# cwd 기준 git rev-parse를 쓰면 additionalDirectories 작업에서 다른 프로젝트 루트가 잡힐 수 있다.
CHECK_DIR=$(dirname "$FILE_PATH")
PROJECT_ROOT=$(harness_project_root_for_path "$FILE_PATH")

if [ -z "$PROJECT_ROOT" ]; then
  case "$FILE_PATH" in
    */docs/*) PROJECT_ROOT=$(echo "$FILE_PATH" | sed 's|/docs/.*||') ;;
    */rules/*) PROJECT_ROOT=$(echo "$FILE_PATH" | sed 's|/rules/.*||') ;;
    */.claude/rules/*) PROJECT_ROOT=$(echo "$FILE_PATH" | sed 's|/.claude/rules/.*||') ;;
    *) exit 0 ;;
  esac
fi

CHECKLIST="$PROJECT_ROOT/.doc-checklist.md"

if command -v harness_tiny_edit_allowed >/dev/null 2>&1 && harness_tiny_edit_allowed "$TOOL_NAME" "$OLD_STRING" "$NEW_STRING"; then
  harness_log "doc-checklist-guard" "tiny-exempt" "$FILE_PATH"
  exit 0
fi

# 체크리스트 존재 확인
if [ ! -f "$CHECKLIST" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "BLOCKED: 문서 수정 전 체크리스트 필수" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2
  echo "이유: 문서 간 계약 위반 방지 (교차 검증 필수)" >&2
  echo "" >&2
  echo "다음 단계:" >&2
  echo "  1. .doc-checklist.md 생성 (프로젝트 루트)" >&2
  echo "  2. 포함: 작업 내용 + 연관 문서 + 교차 검증 + 더블 체크" >&2
  echo "  상세 절차: docs/workflows/document-work.md" >&2
  echo "" >&2
  echo "파일: $FILE_PATH" >&2
  echo "체크리스트 위치: $CHECKLIST" >&2
  exit 1
fi

if ! harness_validate_checklist "$CHECKLIST" "doc"; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "BLOCKED: 문서 체크리스트 품질 검증 실패" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2
  echo "이유: $CHECKLIST_ERROR" >&2
  echo "" >&2
  echo "필수 조건:" >&2
  echo "  - 승인 마커: status: approved / approved: true / - [x] 승인" >&2
  echo "  - 섹션: 작업 범위, 연관 문서, 교차 검증, 더블 체크" >&2
  echo "  - 체크박스 항목 3개 이상" >&2
  echo "  - 한 단어짜리 형식 항목 금지" >&2
  echo "" >&2
  echo "파일: $FILE_PATH" >&2
  echo "체크리스트 위치: $CHECKLIST" >&2
  exit 1
fi

exit 0
