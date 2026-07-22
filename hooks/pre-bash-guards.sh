#!/bin/bash
# PreToolUse(Bash): 평소에는 명령을 한 번만 읽고, 필요한 검사만 실행합니다.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT=$(cat)

if [ -n "${HARNESS_COMMAND+x}" ]; then
  COMMAND="$HARNESS_COMMAND"
elif command -v jq &>/dev/null; then
  COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(printf '%s' "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

[ -n "$COMMAND" ] || exit 0
LOWER_COMMAND=${COMMAND,,}

run_guard() {
  local guard="$1"
  [ -f "$DIR/$guard" ] || return 0
  HARNESS_COMMAND="$COMMAND" bash "$DIR/$guard" <<< "$INPUT"
}

# 배포 검사는 실제 배포 명령에서만 실행합니다.
if [[ "$LOWER_COMMAND" =~ (scp|rsync) ]] && [[ "$COMMAND" == *"187.127.123.81"* ]]; then
  run_guard deploy-version-guard.sh || exit $?
fi

# 문서 쓰기 가능성이 있거나 복구하기 어려운 Git 명령만 상세 검사합니다.
NEEDS_DOC_GUARD=false
if [[ "$LOWER_COMMAND" =~ (^|[[:space:];|\&])git[[:space:]]+(rm|restore|clean)([[:space:]]|$) ]] || \
   [[ "$LOWER_COMMAND" =~ (^|[[:space:];|\&])git[[:space:]]+reset[[:space:]]+.*--hard ]] || \
   [[ "$LOWER_COMMAND" =~ (^|[[:space:];|\&])git[[:space:]]+checkout[[:space:]]+.*-- ]] || \
   [[ "$LOWER_COMMAND" =~ (^|[[:space:];|\&])git([^;|\&])*[[:space:]]push([[:space:];|\&]|$) ]]; then
  NEEDS_DOC_GUARD=true
elif [[ "$LOWER_COMMAND" =~ \.(md|markdown|html|htm|docx|doc|txt|rst|tex|csv|json|yaml|yml|xml|toml) ]] && \
     [[ "$LOWER_COMMAND" =~ (sed|perl|tee|set-content|add-content|out-file|write_text|writefile|createwritestream|writealltext|truncate|(^|[[:space:];|\&])(rm|del|erase|mv|move|cp|copy)[[:space:]]|\>) ]]; then
  NEEDS_DOC_GUARD=true
fi

if [ "$NEEDS_DOC_GUARD" = true ]; then
  run_guard doc-protection.sh || exit $?
fi

exit 0
