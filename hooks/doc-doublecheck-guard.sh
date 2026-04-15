#!/bin/bash
# Claude Code PreToolUse hook: 체크리스트 삭제 시 더블 체크 완료 확인
# .dev-checklist.md 또는 .doc-checklist.md 삭제 시도 시,
# 파일 내에 더블 체크 완료 표시가 없으면 차단
#
# 수정이력:
# - 2026-04-11: .dev-checklist.md 추가, git 의존 제거 (non-git 프로젝트 지원)

# stdin에서 JSON 읽기
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

# .dev-checklist.md 또는 .doc-checklist.md 삭제 시도인지 확인
if ! echo "$COMMAND" | grep -qE '(rm|del|remove).*(\.dev-checklist\.md|\.doc-checklist\.md)'; then
  exit 0
fi

# 삭제 대상 파일 경로 추출 (rm 명령에서 마지막 인자)
CHECKLIST_PATH=""
for word in $COMMAND; do
  if echo "$word" | grep -qE '\.(dev|doc)-checklist\.md'; then
    CHECKLIST_PATH=$(echo "$word" | tr '\\' '/' | sed 's/"//g')
    break
  fi
done

# 경로를 못 찾으면 통과
if [ -z "$CHECKLIST_PATH" ]; then
  exit 0
fi

# 체크리스트 파일이 없으면 통과 (이미 삭제됨)
if [ ! -f "$CHECKLIST_PATH" ]; then
  exit 0
fi

# 더블 체크 완료 표시 확인
# 패턴: "## 더블 체크" 섹션 아래에 미완료 항목([ ])이 없어야 함
# 또는 "[x] 더블 체크 완료" / "[x] 빠진 항목 없" / "[x] 전부 반영" 패턴
DOUBLECHECK_SECTION=false
HAS_UNCHECKED=false

while IFS= read -r line; do
  # 더블 체크 섹션 시작 감지
  if echo "$line" | grep -qiE '^##\s*더블\s*체크'; then
    DOUBLECHECK_SECTION=true
    continue
  fi
  # 다른 ## 섹션이 시작되면 더블 체크 섹션 종료
  if $DOUBLECHECK_SECTION && echo "$line" | grep -qE '^##\s'; then
    DOUBLECHECK_SECTION=false
  fi
  # 더블 체크 섹션 내 미완료 항목 확인
  if $DOUBLECHECK_SECTION && echo "$line" | grep -qE '^\s*-\s*\[\s\]'; then
    HAS_UNCHECKED=true
    break
  fi
done < "$CHECKLIST_PATH"

# 더블 체크 섹션이 없거나 미완료 항목이 있으면 차단
if ! grep -qiE '^##\s*더블\s*체크' "$CHECKLIST_PATH"; then
  echo "BLOCKED: 체크리스트에 '## 더블 체크' 섹션이 없습니다."
  echo "더블 체크 섹션을 추가하고 모든 항목을 [x]로 체크한 후 삭제하세요."
  echo "대상 파일: $CHECKLIST_PATH"
  exit 2
fi

if $HAS_UNCHECKED; then
  echo "BLOCKED: 더블 체크가 완료되지 않았습니다."
  echo ""
  echo "더블 체크 항목을 모두 [x]로 체크한 후 삭제하세요:"
  echo "  1. 체크리스트 자체 검증 — 빠진 항목이 없는가?"
  echo "  2. 실행 검증 — 체크리스트대로 실제 반영했는가?"
  echo "  3. 일관성 검증 — 수정 내용이 다른 문서와 일치하는가?"
  echo ""
  echo "대상 파일: $CHECKLIST_PATH"
  exit 2
fi

# 더블 체크 섹션 존재 + 미완료 항목 없음 → 통과
exit 0
