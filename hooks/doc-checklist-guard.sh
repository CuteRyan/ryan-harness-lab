#!/bin/bash
# Claude Code PreToolUse hook: docs/ 파일 수정 시 체크리스트 존재 강제
# 체크리스트(.doc-checklist.md) 없이는 docs/ 하위 파일 Edit 불가
# 더블 체크 미완료 시 체크리스트 삭제 불가

# stdin에서 JSON 읽기 (Claude Code 훅은 stdin으로 전달)
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

# Windows 백슬래시 → 슬래시 정규화 (case 패턴 매칭용)
FILE_PATH=$(echo "$FILE_PATH" | tr '\\' '/')

# 프로젝트 루트 찾기 (git repo 또는 파일 경로에서 추론)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  # git이 아닌 경우: 파일 경로에서 docs/ 상위를 프로젝트 루트로 추론
  case "$FILE_PATH" in
    */docs/*) GIT_ROOT=$(echo "$FILE_PATH" | sed 's|/docs/.*||') ;;
    */.claude/rules/*) GIT_ROOT=$(echo "$FILE_PATH" | sed 's|/.claude/rules/.*||') ;;
    *) exit 0 ;;
  esac
fi

CHECKLIST="$GIT_ROOT/.doc-checklist.md"

# docs/ 하위 파일인지 확인 (docs/, .claude/rules/ 포함)
IS_DOC=false
case "$FILE_PATH" in
  */docs/*) IS_DOC=true ;;
  */.claude/rules/*) IS_DOC=true ;;
esac

if [ "$IS_DOC" = false ]; then
  exit 0
fi

# .doc-checklist.md 자체를 수정하는 건 허용 (체크리스트 작성/업데이트)
case "$FILE_PATH" in
  */.doc-checklist.md) exit 0 ;;
esac

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

exit 0
