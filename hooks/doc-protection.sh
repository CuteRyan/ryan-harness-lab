#!/bin/bash
# Claude Code PreToolUse hook: 문서/설정 파일 직접 덮어쓰기 보호
# - Write로 기존 문서/설정 파일을 전체 덮어쓰는 작업 차단
# - Bash로 문서/설정 파일을 직접 수정하는 우회 경로 차단
# - 신규 파일 Write는 허용하고, 내용 변경은 Edit 도구 사용을 유도

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || true
if command -v harness_timer_start >/dev/null 2>&1; then
  harness_timer_start
  trap 'harness_timer_stop "doc-protection"' EXIT
fi

INPUT=$(cat)
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | python -c "import sys,json; data=json.load(sys.stdin); print(data.get('tool_name',''))" 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; data=json.load(sys.stdin); print(data.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
  COMMAND=$(echo "$INPUT" | python -c "import sys,json; data=json.load(sys.stdin); print(data.get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

DOC_EXT='\.(md|markdown|html|htm|docx|doc|txt|rst|tex|csv|json|yaml|yml|xml|toml)$'
DOC_EXT_IN_COMMAND='\.(md|markdown|html|htm|docx|doc|txt|rst|tex|csv|json|yaml|yml|xml|toml)'

normalize_path() {
  echo "$1" | tr '\\' '/'
}

is_doc_path() {
  local path="$1"
  echo "$path" | grep -qiE "$DOC_EXT"
}

block() {
  local reason="$1"
  local target="$2"
  if [ -n "$target" ]; then
    target=$(basename "$target")
  fi
  echo "[hook] 문서 보호 정책 위반: $reason" >&2
  if [ -n "$target" ]; then
    echo "[hook] 대상: $target" >&2
  fi
  echo "[hook] 기존 문서/설정 파일 수정은 Edit 도구를 사용하세요. 신규 파일 생성은 Write가 허용됩니다." >&2
  exit 1
}

if [ -n "$FILE_PATH" ]; then
  FILE_PATH=$(normalize_path "$FILE_PATH")
fi

case "$TOOL_NAME" in
  Write)
    if [ -n "$FILE_PATH" ] && is_doc_path "$FILE_PATH" && [ -f "$FILE_PATH" ]; then
      block "기존 문서/설정 파일에 Write 사용" "$FILE_PATH"
    fi
    exit 0
    ;;
  Bash|"")
    ;;
  *)
    exit 0
    ;;
esac

if [ -z "$COMMAND" ]; then
  exit 0
fi

# 백업/버전관리/조회성 명령은 보호 훅 대상에서 제외
if echo "$COMMAND" | grep -q '\.backups'; then
  exit 0
fi
if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]'; then
  exit 0
fi

BLOCKED=false
REASON=""

if echo "$COMMAND" | grep -qE "sed[[:space:]]+(-[a-zA-Z]*i|--in-place)" && echo "$COMMAND" | grep -qiE "$DOC_EXT_IN_COMMAND"; then
  BLOCKED=true
  REASON="sed -i로 문서/설정 파일 직접 수정"
fi

if echo "$COMMAND" | grep -qiE "(^|[[:space:];|&])perl[[:space:]].*(-[a-zA-Z]*i|--in-place)" && echo "$COMMAND" | grep -qiE "$DOC_EXT_IN_COMMAND"; then
  BLOCKED=true
  REASON="perl -i로 문서/설정 파일 직접 수정"
fi

if echo "$COMMAND" | grep -qE ">{1,2}[[:space:]]*['\"]?[^|;&]*${DOC_EXT_IN_COMMAND}"; then
  BLOCKED=true
  REASON="redirect: 문서/설정 파일 쓰기"
fi

if echo "$COMMAND" | grep -qiE "(^|[[:space:];|&])tee[[:space:]].*${DOC_EXT_IN_COMMAND}"; then
  BLOCKED=true
  REASON="tee로 문서/설정 파일 쓰기"
fi

if echo "$COMMAND" | grep -qiE "(Set-Content|Add-Content|Out-File)[[:space:]].*${DOC_EXT_IN_COMMAND}"; then
  BLOCKED=true
  REASON="PowerShell 파일 쓰기 명령으로 문서/설정 파일 수정"
fi

if echo "$COMMAND" | grep -qiE "(open|write_text|writeFileSync|createWriteStream)[^;&|]*${DOC_EXT_IN_COMMAND}"; then
  BLOCKED=true
  REASON="script: 파일 쓰기 API로 문서/설정 파일 수정"
fi

if echo "$COMMAND" | grep -qiE "(^|[[:space:];|&])(mv|move|cp|copy)[[:space:]].*${DOC_EXT_IN_COMMAND}"; then
  BLOCKED=true
  REASON="mv/cp로 문서/설정 파일 덮어쓰기 가능성"
fi

if [ "$BLOCKED" = true ]; then
  block "$REASON" ""
fi

exit 0
