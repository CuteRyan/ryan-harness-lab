#!/bin/bash
# PreToolUse(Bash) 글로벌 훅: SCP 배포 명령 감지 시 버전업 확인
# 조건: scp 명령에 EC2 서버(3.36.211.91) 포함 시 동작
INPUT=$(cat)
if command -v jq &>/dev/null; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  CMD=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

# SCP 배포 명령인지 확인
if echo "$CMD" | grep -q "scp" && echo "$CMD" | grep -q "3.36.211.91"; then
  # git diff --cached 또는 최근 커밋에서 버전 파일 변경 여부 확인
  TOML_EXISTS=$(ls pyproject.toml 2>/dev/null)
  if [ -n "$TOML_EXISTS" ]; then
    # 최근 커밋에 pyproject.toml이 포함됐는지 확인
    TOML_CHANGED=$(git diff HEAD~1 --name-only 2>/dev/null | grep "pyproject.toml")
    HISTORY_CHANGED=$(git diff HEAD~1 --name-only 2>/dev/null | grep "HISTORY.md")

    if [ -z "$TOML_CHANGED" ] || [ -z "$HISTORY_CHANGED" ]; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "BLOCKED: 배포 전 체크리스트 미완료"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "규칙: ~/.claude/rules/deployment.md"
      echo ""
      if [ -z "$TOML_CHANGED" ]; then
        echo "  [ ] pyproject.toml — 버전업 필요"
      else
        echo "  [x] pyproject.toml — 버전 변경됨"
      fi
      if [ -z "$HISTORY_CHANGED" ]; then
        echo "  [ ] HISTORY.md — 변경사항 기록 필요"
      else
        echo "  [x] HISTORY.md — 업데이트됨"
      fi
      echo ""
      echo "다음 단계: 미완료 항목 처리 후 git commit → 재시도"
      exit 2
    fi
  fi
fi

exit 0
