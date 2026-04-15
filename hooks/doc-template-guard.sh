#!/bin/bash
# Claude Code PreToolUse hook: 문서 양식(YAML 프론트매터) 검증
# - docs/ 내 .md 파일 Write(신규): 프론트매터 없으면 차단
# - docs/ 내 .md 파일 Edit(기존): Stage별 차등 (Stage1=통과, Stage2=경고, Stage3=차단)
# - .harness.yml opt-in 필수: 없으면 no-op
# - 확인 필드: title, type, status, created
# - 예외: index.md, log.md, HISTORY.md, templates/ 하위 파일

# 공통 함수 로드
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || exit 0
harness_timer_start
trap 'harness_timer_stop "doc-template-guard"' EXIT

INPUT=$(cat)

# 도구명 추출 (Write vs Edit 구분)
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
  CONTENT=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('content',''))" 2>/dev/null)
fi

# 파일 경로가 없으면 통과
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# .harness.yml opt-in 검사
if ! find_harness_yml "$FILE_PATH"; then
  exit 0
fi
if ! harness_feature_enabled "doc_templates" "false"; then
  exit 0
fi

# docs/ 하위 .md 파일인지 확인
if ! echo "$FILE_PATH" | grep -qiE '(/|\\)docs(/|\\)'; then
  exit 0
fi
if ! echo "$FILE_PATH" | grep -qiE '\.md$'; then
  exit 0
fi

# 예외 파일
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  index.md|log.md|HISTORY.md|TEMPLATE.md)
    exit 0
    ;;
esac

# templates/ 하위 파일은 예외
if echo "$FILE_PATH" | grep -qiE '(/|\\)templates(/|\\)'; then
  exit 0
fi

# Stage 결정 (.harness.yml에서 읽기 — 없으면 기본 Stage 1)
STAGE=1
if [ -n "$PROJECT_ROOT" ] && [ -f "$PROJECT_ROOT/.harness.yml" ]; then
  # strict_metadata: true → Stage 3
  if grep -q 'strict_metadata: *true' "$PROJECT_ROOT/.harness.yml" 2>/dev/null; then
    STAGE=3
  # warn_metadata: true → Stage 2
  elif grep -q 'warn_metadata: *true' "$PROJECT_ROOT/.harness.yml" 2>/dev/null; then
    STAGE=2
  fi
fi

# 프론트매터 존재 확인 함수
check_frontmatter() {
  local content="$1"
  # --- 로 시작하는 YAML 프론트매터가 있는지 확인
  if ! echo "$content" | head -1 | grep -q '^---'; then
    return 1
  fi
  # 필수 필드 확인: title, type, status, created
  local missing=""
  echo "$content" | grep -q '^title:' || missing="$missing title"
  echo "$content" | grep -q '^type:' || missing="$missing type"
  echo "$content" | grep -q '^status:' || missing="$missing status"
  echo "$content" | grep -q '^created:' || missing="$missing created"
  if [ -n "$missing" ]; then
    echo "$missing"
    return 1
  fi
  return 0
}

# Write (신규 생성) — 프론트매터 없으면 차단 (Stage 1부터)
if [ "$TOOL_NAME" = "Write" ]; then
  if [ -z "$CONTENT" ]; then
    exit 0
  fi
  MISSING=$(check_frontmatter "$CONTENT")
  if [ $? -ne 0 ]; then
    harness_log "doc-template-guard" "blocked" "Write $BASENAME missing:$MISSING"
    echo "[harness/template] 신규 문서에 YAML 프론트매터가 필요합니다: $BASENAME" >&2
    echo "[harness/template] 필수 필드: title, type, status, created" >&2
    echo "[harness/template] docs/templates/ 에서 양식을 참고하세요." >&2
    exit 1
  fi
  exit 0
fi

# Edit (기존 수정) — Stage별 차등
if [ "$TOOL_NAME" = "Edit" ]; then
  # 파일이 존재하고 프론트매터가 없는 경우만 검사
  if [ -f "$FILE_PATH" ]; then
    FILE_CONTENT=$(head -20 "$FILE_PATH" 2>/dev/null)
    MISSING=$(check_frontmatter "$FILE_CONTENT")
    if [ $? -ne 0 ]; then
      case $STAGE in
        1)
          # Stage 1: 통과 (로그만)
          harness_log "doc-template-guard" "pass-stage1" "Edit $BASENAME no frontmatter"
          exit 0
          ;;
        2)
          # Stage 2: 경고
          harness_log "doc-template-guard" "warn-stage2" "Edit $BASENAME missing:$MISSING"
          echo "[harness/template] 이 문서에 프론트매터가 없습니다: $BASENAME (Stage 2: 경고)" >&2
          echo "[harness/template] 프론트매터 추가를 권장합니다. 필수 필드: title, type, status, created" >&2
          exit 0
          ;;
        3)
          # Stage 3: 차단
          harness_log "doc-template-guard" "blocked-stage3" "Edit $BASENAME missing:$MISSING"
          echo "[harness/template] 프론트매터 없는 문서 수정 차단: $BASENAME (Stage 3)" >&2
          echo "[harness/template] 먼저 프론트매터를 추가하세요. 필수 필드: title, type, status, created" >&2
          exit 1
          ;;
      esac
    fi
  fi
  exit 0
fi

exit 0
