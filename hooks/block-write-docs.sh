#!/bin/bash
# Claude Code PreToolUse hook: 기존 문서 파일에 Write(전체 덮어쓰기) 차단
# 모든 문서/설정 파일은 Edit(부분 교체)만 허용
# 새 파일 생성은 허용 (파일이 아직 없으면 통과)

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

# 문서/설정 파일 확장자 체크
if echo "$FILE_PATH" | grep -qE '\.(md|html|htm|docx|doc|txt|rst|tex|csv|json|yaml|yml|xml|toml)$'; then
  # 파일이 이미 존재하면 차단 (새 파일 생성은 허용)
  if [ -f "$FILE_PATH" ]; then
    echo "[hook] 기존 문서 파일에 Write 사용 금지 — Edit 도구로 부분 교체만 허용됩니다: $(basename "$FILE_PATH")" >&2
    exit 1
  fi
fi

exit 0
