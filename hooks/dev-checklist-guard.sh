#!/bin/bash
# dev-checklist-guard.sh
# 개발 체크리스트 강제 — 모든 파일 Edit/Write 시 .dev-checklist.md 없으면 차단
#
# 목적: 하네스 엔지니어링 원칙 — 작업 전 체크리스트 필수
# 예외: 체크리스트 자체, .backups/, CLAUDE.md, MEMORY.md, .gitignore,
#       __init__.py, conftest.py, setup.py, settings.json(훅 설정)

# stdin에서 tool_input JSON 읽기 (Claude Code 훅은 stdin으로 전달)
INPUT=$(cat)
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
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

# memory/ 디렉토리 파일은 통과 (메모리 관리)
if [[ "$FILE_PATH" == */memory/* || "$FILE_PATH" == */.claude/* ]]; then
  exit 0
fi

# 프로젝트 루트 찾기 — 2단계 탐색
# 1단계: 체크리스트를 파일 위치부터 상위로 탐색 (어디에서든 찾으면 통과)
# 2단계: 체크리스트 못 찾으면, 가장 가까운 프로젝트 루트를 기준으로 차단
PROJECT_ROOT=""
CHECK_DIR=$(dirname "$FILE_PATH")

# Windows 경로를 Unix로 변환
CHECK_DIR=$(echo "$CHECK_DIR" | tr '\\' '/')

# 1단계: 체크리스트 탐색 (루트까지 올라감)
SEARCH_DIR="$CHECK_DIR"
while [ "$SEARCH_DIR" != "/" ] && [ "$SEARCH_DIR" != "." ]; do
  if [ -f "$SEARCH_DIR/.dev-checklist.md" ]; then
    exit 0
  fi
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

# 2단계: 체크리스트 없음 → 가장 가까운 프로젝트 루트 찾기 (차단 메시지용)
while [ "$CHECK_DIR" != "/" ] && [ "$CHECK_DIR" != "." ]; do
  if [ -d "$CHECK_DIR/.git" ] || [ -f "$CHECK_DIR/pyproject.toml" ] || \
     [ -f "$CHECK_DIR/CLAUDE.md" ] || [ -d "$CHECK_DIR/docs" ]; then
    PROJECT_ROOT="$CHECK_DIR"
    break
  fi
  CHECK_DIR=$(dirname "$CHECK_DIR")
done

# 프로젝트 루트를 못 찾으면 — CWD를 루트로 사용
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$PWD"
  if [ -f "$PROJECT_ROOT/.dev-checklist.md" ]; then
    exit 0
  fi
fi

# 프로젝트 루트에 .dev-checklist.md 있는지 최종 확인
if [ -f "$PROJECT_ROOT/.dev-checklist.md" ]; then
  exit 0
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
