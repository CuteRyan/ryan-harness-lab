#!/bin/bash
# Claude Code PreToolUse hook: 문서/설정 파일 보호
# - Write로 기존 문서/설정 파일을 전체 덮어쓰는 작업 차단
# - Bash로 문서/설정 파일을 직접 수정하는 우회 경로 차단
# - Edit/MultiEdit은 그대로 허용
# - 신규 파일 Write는 허용하고, 기존 파일 전체 덮어쓰기만 차단

if [ -n "${HARNESS_TOOL_NAME+x}" ]; then
  TOOL_NAME="$HARNESS_TOOL_NAME"
  FILE_PATH="${HARNESS_FILE_PATH:-}"
  COMMAND="${HARNESS_COMMAND:-}"
elif [ -n "${HARNESS_COMMAND+x}" ]; then
  TOOL_NAME="Bash"
  FILE_PATH=""
  COMMAND="$HARNESS_COMMAND"
else
  INPUT=$(cat)
  if command -v jq &>/dev/null; then
    PARSED=$(printf '%s' "$INPUT" | jq -r '[.tool_name // "", .tool_input.file_path // "", (.tool_input.command // "" | gsub("[\\r\\n]"; " "))] | join("\u001f")' 2>/dev/null)
  else
    PARSED=$(printf '%s' "$INPUT" | python -c "import sys,json; d=json.load(sys.stdin); v=[d.get('tool_name',''),d.get('tool_input',{}).get('file_path',''),d.get('tool_input',{}).get('command','')]; print(chr(31).join(str(x).replace(chr(10),' ').replace(chr(13),' ') for x in v))" 2>/dev/null)
  fi
  IFS=$'\x1f' read -r TOOL_NAME FILE_PATH COMMAND <<< "$PARSED"
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
  Edit|MultiEdit)
    exit 0
    ;;
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

# cp/mv의 마지막 인자가 .backups 아래 문서일 때만 백업 작업으로 허용합니다.
# .backups가 원본에만 등장하면 아래 일반 덮어쓰기 검사로 보냅니다.
if echo "$COMMAND" | grep -qiE '(^|[[:space:];|&])(cp|copy|mv|move)[[:space:]]' && \
   echo "$COMMAND" | grep -qiE "[[:space:]]+([\"'][^\"']*\.backups[/\\\\][^\"']*${DOC_EXT_IN_COMMAND}[\"']|[^[:space:]]*\.backups[/\\\\][^[:space:]]*${DOC_EXT_IN_COMMAND})[[:space:]]*$"; then
  exit 0
fi

# --- git 명령 처리 ---
# 복구하기 어려운 Git 명령만 차단합니다. 일반 push와 브랜치 전환은 허용합니다.
if echo "$COMMAND" | grep -qE '(^|[[:space:];|&])git[[:space:]]+(rm|restore|clean)([[:space:]]|$)' || \
   echo "$COMMAND" | grep -qE '(^|[[:space:];|&])git[[:space:]]+reset[[:space:]].*--hard' || \
   echo "$COMMAND" | grep -qE '(^|[[:space:];|&])git[[:space:]]+checkout[[:space:]].*--' || \
   echo "$COMMAND" | grep -qiE '(^|[[:space:];|&])git([^;|&])*[[:space:]]push([^;|&])*([[:space:]]-[[:alnum:]]*f[[:alnum:]]*([=[:space:];|&]|$)|[[:space:]]--force[^[:space:];|&]*([=[:space:];|&]|$)|[[:space:]]\+[^[:space:];|&]+)'; then
  block "복구하기 어려운 Git 명령" ""
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
