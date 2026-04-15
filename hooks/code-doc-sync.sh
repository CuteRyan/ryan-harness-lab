#!/bin/bash
# Claude Code PreToolUse hook: 코드↔문서 양방향 리마인더
# - 코드 파일 Edit → 관련 문서 리마인더
# - docs/ 문서 Edit → 관련 코드 리마인더
# - .harness.yml opt-in 필수
# - 역색인(docs/.harness-index.json) 기반. 없으면 사용자 출력 없이 통과.
# - 강도: 리마인더 (exit 0 — 차단 안함)

# 공통 함수 로드
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || exit 0
harness_timer_start
trap 'harness_timer_stop "code-doc-sync"' EXIT

INPUT=$(cat)

if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

# Edit만 대상
if [ "$TOOL_NAME" != "Edit" ]; then
  exit 0
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# opt-in 검사
if ! find_harness_yml "$FILE_PATH"; then
  exit 0
fi
if ! harness_feature_enabled "code_doc_sync" "false"; then
  exit 0
fi

# 역색인 경로
INDEX_JSON="$PROJECT_ROOT/docs/.harness-index.json"

# 파일이 코드인지 문서인지 판별
IS_CODE=false
IS_DOC=false

if echo "$FILE_PATH" | grep -qE '\.(py|js|ts|tsx|jsx|go|java|rs|rb|php|swift|kt|c|cpp|h|hpp|cs)$'; then
  IS_CODE=true
fi
if echo "$FILE_PATH" | grep -qiE '(/|\\)docs(/|\\).*\.md$'; then
  IS_DOC=true
fi

# 코드도 문서도 아니면 통과
if [ "$IS_CODE" = false ] && [ "$IS_DOC" = false ]; then
  exit 0
fi

# 역색인이 없으면 아직 준비되지 않은 프로젝트로 보고 완전 무음 처리
if [ ! -f "$INDEX_JSON" ]; then
  harness_log "code-doc-sync" "skip" "no index: $INDEX_JSON"
  exit 0
fi

# 경로를 repo-relative로 변환 (Windows \ → /, PROJECT_ROOT 제거)
normalize_path() {
  local p="$1"
  p=$(echo "$p" | tr '\\' '/')
  # PROJECT_ROOT 부분 제거 (대소문자 무시)
  local root
  root=$(echo "$PROJECT_ROOT" | tr '\\' '/')
  p="${p#$root/}"
  # /c/Users... → C:/Users... 형식 대응
  local root_alt
  root_alt=$(echo "$root" | sed 's|^/\([a-zA-Z]\)/|\1:/|')
  p="${p#$root_alt/}"
  echo "$p"
}

REL_PATH=$(normalize_path "$FILE_PATH")

# 코드 파일 수정 → 관련 문서 조회
if [ "$IS_CODE" = true ]; then
  if command -v jq &>/dev/null; then
    RELATED=$(jq -r --arg p "$REL_PATH" '.code_to_docs[$p][]? // empty' "$INDEX_JSON" 2>/dev/null)
  else
    RELATED=$(python -c "
import sys,json
with open('$INDEX_JSON') as f:
    idx = json.load(f)
for doc in idx.get('code_to_docs',{}).get('$REL_PATH',[]):
    print(doc)
" 2>/dev/null)
  fi
  if [ -n "$RELATED" ]; then
    harness_log "code-doc-sync" "remind-code" "$REL_PATH -> $RELATED"
    echo "[harness/sync] 이 코드와 관련된 문서가 있습니다:" >&2
    echo "$RELATED" | while read -r doc; do
      echo "  → $doc" >&2
    done
  fi
fi

# 문서 파일 수정 → 프론트매터에서 related_code 구조적 파싱
if [ "$IS_DOC" = true ]; then
  if [ -f "$FILE_PATH" ]; then
    # Python stdlib 기반 프론트매터 파싱 (sed|grep 방식의 오탐 방지)
    RELATED_CODE=$(python -c "
import sys
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        lines = f.readlines()
    if not lines or lines[0].strip() != '---':
        sys.exit(0)
    in_fm, in_rc = False, False
    fm_end = -1
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == '---':
            fm_end = i
            break
    if fm_end < 0:
        sys.exit(0)
    for line in lines[1:fm_end]:
        stripped = line.rstrip()
        if stripped.startswith('related_code:'):
            in_rc = True
            continue
        if in_rc:
            if stripped.startswith('  -'):
                val = stripped.lstrip().lstrip('-').strip()
                if val:
                    print(val)
            else:
                in_rc = False
except Exception:
    pass
" "$FILE_PATH" 2>/dev/null)
    if [ -n "$RELATED_CODE" ]; then
      harness_log "code-doc-sync" "remind-doc" "$REL_PATH -> code files"
      echo "[harness/sync] 이 문서와 관련된 코드가 있습니다:" >&2
      echo "$RELATED_CODE" | while read -r code; do
        echo "  → $code" >&2
      done
    fi
  fi
fi

exit 0
