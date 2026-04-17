#!/bin/bash
# Claude Code PreToolUse hook: 문서/설정 파일 보호 + 자동 백업
# - Write로 기존 문서/설정 파일을 전체 덮어쓰는 작업 차단
# - Bash로 문서/설정 파일을 직접 수정하는 우회 경로 차단
# - Edit 시 기존 문서를 .backups/에 자동 백업
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

backup_doc() {
  local filepath="$1"
  if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
    return 0
  fi
  local dir=$(dirname "$filepath")
  local name=$(basename "$filepath")
  local backup_dir="$dir/.backups"
  local timestamp=$(date '+%Y%m%d_%H%M%S')
  mkdir -p "$backup_dir" 2>/dev/null
  cp "$filepath" "$backup_dir/${name}.${timestamp}.bak" 2>/dev/null
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
  Edit|MultiEdit)
    # Edit/MultiEdit은 허용하되, 기존 문서 파일이면 자동 백업
    if [ -n "$FILE_PATH" ] && is_doc_path "$FILE_PATH" && [ -f "$FILE_PATH" ]; then
      backup_doc "$FILE_PATH"
    fi
    exit 0
    ;;
  Write)
    if [ -n "$FILE_PATH" ] && is_doc_path "$FILE_PATH" && [ -f "$FILE_PATH" ]; then
      backup_doc "$FILE_PATH"
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

# 백업 디렉토리 자체 조작(ls, cat 등)만 허용 — 대상 경로가 .backups/ 아래인 경우만
# 주의: 명령 문자열에 .backups가 포함되었다고 전체 면제하면 우회됨
# .backups 디렉토리 관련 명령 허용:
#   - 조회(ls, cat 등): .backups 경로 포함이면 허용
#   - cp/mv → .backups: 목적지가 .backups 아래이면 허용 (백업 목적)
if echo "$COMMAND" | grep -qE '\.backups[/\\]'; then
  # cp/mv 명령이면 마지막 인자(목적지)가 .backups 아래인지 확인
  if echo "$COMMAND" | grep -qiE '(^|[[:space:];|&])(cp|copy|mv|move)[[:space:]]'; then
    # 목적지(.backups)가 포함되어 있으므로 백업 목적 허용
    exit 0
  fi
  # 그 외 조회 명령(.backups 경로 포함, 문서 확장자 없음)
  if ! echo "$COMMAND" | grep -qiE "$DOC_EXT_IN_COMMAND" || echo "$COMMAND" | grep -qE '\.backups[/\\][^[:space:]]*'"$DOC_EXT_IN_COMMAND"; then
    exit 0
  fi
fi

# --- git 명령 처리 ---
# 파괴적 git 명령은 즉시 차단 (확장자/경로 무관)
if echo "$COMMAND" | grep -qE '(^|[[:space:];|&])git[[:space:]]+(checkout|restore|rm|reset|clean|push)'; then
  block "git 파괴적 명령 차단 (checkout/restore/rm/reset/clean/push)" ""
fi

# git 읽기 전용 명령 허용 조건:
#   1. redirect(>), 체인(;&&||), 파이프(|), newline, command substitution($( `) 없음
#   2. 위험 옵션(--output, --ext-diff) 없음
#   3. 서브커맨드까지 읽기 전용
if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]' && \
   ! echo "$COMMAND" | grep -qE '[;|&>]' && \
   ! echo "$COMMAND" | grep -qF $'\n' && \
   ! echo "$COMMAND" | grep -qE '(\$\(|`)' && \
   ! echo "$COMMAND" | grep -qE '\-\-output' && \
   ! echo "$COMMAND" | grep -qE '\-\-ext-diff'; then
  # 단순 조회 명령 (인자 자유)
  if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]+(status|diff|log|show|blame)([[:space:]]|$)'; then
    exit 0
  fi
  # branch: 읽기만 (뒤에 -D/-d/-m 등 파괴 옵션 없어야 함)
  if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]+branch([[:space:]]|$)' && \
     ! echo "$COMMAND" | grep -qE '\-[DdmM]'; then
    exit 0
  fi
  # tag: 읽기만
  if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]+tag([[:space:]]|$)' && \
     ! echo "$COMMAND" | grep -qE '\-[dfs]'; then
    exit 0
  fi
  # remote: 읽기만
  if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]+remote([[:space:]]|$)' && \
     ! echo "$COMMAND" | grep -qiE '(add|remove|rename|set-url|set-head|prune)'; then
    exit 0
  fi
  # stash list
  if echo "$COMMAND" | grep -qE '^[[:space:]]*git[[:space:]]+stash[[:space:]]+list'; then
    exit 0
  fi
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

if echo "$COMMAND" | grep -qiE "(^|[[:space:];|&])(rm|del|erase|truncate)[[:space:]].*${DOC_EXT_IN_COMMAND}"; then
  BLOCKED=true
  REASON="rm/truncate로 문서/설정 파일 삭제/절삭"
fi

if echo "$COMMAND" | grep -qiE "(^|[[:space:];|&])(python|python3|node|ruby)[[:space:]].*${DOC_EXT_IN_COMMAND}" && echo "$COMMAND" | grep -qiE "(write_text|write_bytes|writeFile|open\(|WriteAllText)"; then
  BLOCKED=true
  REASON="스크립트 언어로 문서/설정 파일 직접 쓰기"
fi

if [ "$BLOCKED" = true ]; then
  block "$REASON" ""
fi

exit 0
