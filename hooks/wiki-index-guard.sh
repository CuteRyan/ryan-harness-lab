#!/bin/bash
# Claude Code PreToolUse hook: docs/ 파일 생성/수정 시 index.md 등록 여부 확인
# - docs/ 내 .md 파일을 Write/Edit할 때 index.md에 해당 파일이 등록되어 있는지 확인
# - .harness.yml opt-in 필수: 없으면 no-op
# - Phase 0: 미등록이면 경고만 (차단 안함)
# - 예외: index.md, log.md, HISTORY.md, TEMPLATE.md 자체 수정은 통과

# 공통 함수 로드 (opt-in 검사 + 로그)
source ~/.claude/hooks/_harness_common.sh 2>/dev/null || exit 0

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

# .harness.yml opt-in 검사 — 없으면 no-op
if ! find_harness_yml "$FILE_PATH"; then
  exit 0
fi

# docs/ 폴더 내 .md 파일인지 확인 (경로에 /docs/ 또는 \docs\ 포함)
if ! echo "$FILE_PATH" | grep -qiE '(/|\\)docs(/|\\)'; then
  exit 0
fi

# .md 파일이 아니면 통과
if ! echo "$FILE_PATH" | grep -qiE '\.md$'; then
  exit 0
fi

# templates/ 하위 파일은 예외 (양식 파일)
if echo "$FILE_PATH" | grep -qiE '(/|\\)templates(/|\\)'; then
  exit 0
fi

# 파일명 추출
BASENAME=$(basename "$FILE_PATH")

# 관리 파일은 예외 (이것들 자체를 수정하는 건 허용)
case "$BASENAME" in
  index.md|log.md|HISTORY.md|TEMPLATE.md)
    exit 0
    ;;
esac

# docs/ 디렉토리 찾기 (FILE_PATH에서 docs/ 부분까지 추출)
# 하위 폴더(docs/design/xxx.md)도 대응
DOCS_DIR=$(echo "$FILE_PATH" | sed -E 's|(.*[/\\]docs)[/\\].*|\1|')

# index.md 경로
INDEX_FILE="$DOCS_DIR/index.md"

# index.md가 없으면 통과 (위키 체계 미도입 프로젝트)
if [ ! -f "$INDEX_FILE" ]; then
  exit 0
fi

# index.md에서 해당 파일명이 등록되어 있는지 확인
if grep -q "$BASENAME" "$INDEX_FILE" 2>/dev/null; then
  exit 0
fi

# 미등록 → 경고만 (Phase 0: 차단 안함)
harness_log "wiki-index-guard" "would-block" "$BASENAME not in index.md"
echo "[harness/wiki] docs/ 문서가 index.md에 미등록: $BASENAME (Phase 0: 경고만)" >&2
exit 0
