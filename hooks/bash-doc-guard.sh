#!/bin/bash
# Claude Code PreToolUse hook: Bash로 문서 파일 직접 수정 차단
# Edit 도구를 사용해야 auto-backup.sh가 백업을 만들어줌
# Bash로 우회하면 백업 없이 수정되므로 차단

# stdin에서 JSON 읽기 (Claude Code 훅은 stdin으로 전달)
INPUT=$(cat)
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

# 명령어가 없으면 통과
if [ -z "$COMMAND" ]; then
  exit 0
fi

# 문서 확장자 패턴
DOC_EXT='\.(md|html|htm|docx|doc|txt|rst|tex|csv|json|yaml|yml|xml|toml)'

# 위험한 패턴 감지: 문서 파일을 직접 수정/덮어쓰는 Bash 명령
# 1) sed -i (in-place 수정)
# 2) awk ... > 파일 (리다이렉션 덮어쓰기)
# 3) echo/cat/printf + > 또는 >> (리다이렉션)
# 4) tee (파이프로 파일 쓰기)
# 5) mv (파일 이동/덮어쓰기)
# 6) cp (복사로 덮어쓰기 — 백업 목적 cp는 허용)

BLOCKED=false
REASON=""

# sed -i 로 문서 파일 수정
if echo "$COMMAND" | grep -qE "sed\s+(-[a-zA-Z]*i|--in-place)" && echo "$COMMAND" | grep -qE "$DOC_EXT"; then
  BLOCKED=true
  REASON="sed -i로 문서 파일 직접 수정"
fi

# 리다이렉션(> 또는 >>)으로 문서 파일에 쓰기
if echo "$COMMAND" | grep -qE ">\s*['\"]?[^|]*${DOC_EXT}"; then
  BLOCKED=true
  REASON="리다이렉션(>)으로 문서 파일 덮어쓰기"
fi

# tee로 문서 파일에 쓰기
if echo "$COMMAND" | grep -qE "tee\s+.*${DOC_EXT}"; then
  BLOCKED=true
  REASON="tee로 문서 파일 쓰기"
fi

# .backups/ 관련 명령은 허용 (백업 작업 자체는 통과)
if echo "$COMMAND" | grep -q '\.backups'; then
  exit 0
fi

# git 명령은 허용 (checkout, restore 등)
if echo "$COMMAND" | grep -qE '^git\s'; then
  exit 0
fi

if [ "$BLOCKED" = true ]; then
  echo "[hook] Bash로 문서 파일 직접 수정 차단: $REASON" >&2
  echo "[hook] 문서 수정은 Edit 도구를 사용하세요 (자동 백업됨)" >&2
  exit 1
fi

exit 0
