#!/bin/bash
# PreToolUse(Bash) 글로벌 훅: 배포 명령 감지 시 버전업 + CI 상태 확인
# 조건: scp 명령에 EC2 서버(3.36.211.91) 포함 시 동작
# 체크 항목:
#   1. pyproject.toml 버전업 여부
#   2. HISTORY.md 업데이트 여부
#   3. GitHub CI 최신 커밋 통과 여부

INPUT=$(cat)
if command -v jq &>/dev/null; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  CMD=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
fi

# SCP 배포 명령인지 확인
if ! echo "$CMD" | grep -q "scp" || ! echo "$CMD" | grep -q "3.36.211.91"; then
  exit 0
fi

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  exit 0
fi

cd "$GIT_ROOT" || exit 0

# --- 체크 1, 2: 버전업 + HISTORY ---
TOML_CHANGED=$(git diff HEAD~1 --name-only 2>/dev/null | grep "pyproject.toml")
HISTORY_CHANGED=$(git diff HEAD~1 --name-only 2>/dev/null | grep "HISTORY.md")

# --- 체크 3: GitHub CI 상태 ---
CI_STATUS="unknown"
CI_DETAIL=""
if command -v gh &>/dev/null; then
  CURRENT_SHA=$(git rev-parse HEAD 2>/dev/null)
  if [ -n "$CURRENT_SHA" ]; then
    CI_JSON=$(gh run list --commit "$CURRENT_SHA" --json conclusion,status,name --limit 5 2>/dev/null)
    if [ -n "$CI_JSON" ] && [ "$CI_JSON" != "[]" ]; then
      RUNNING=$(echo "$CI_JSON" | jq -r '[.[] | select(.status != "completed")] | length' 2>/dev/null)
      FAILED=$(echo "$CI_JSON" | jq -r '[.[] | select(.conclusion == "failure")] | length' 2>/dev/null)
      FAILED_NAMES=$(echo "$CI_JSON" | jq -r '[.[] | select(.conclusion == "failure") | .name] | join(", ")' 2>/dev/null)

      if [ "${RUNNING:-0}" -gt 0 ]; then
        CI_STATUS="running"
        CI_DETAIL="CI가 아직 실행 중입니다"
      elif [ "${FAILED:-0}" -gt 0 ]; then
        CI_STATUS="failed"
        CI_DETAIL="실패한 워크플로: $FAILED_NAMES"
      else
        CI_STATUS="passed"
      fi
    else
      CI_STATUS="none"
      CI_DETAIL="이 커밋에 CI 실행 기록이 없습니다"
    fi
  fi
fi

# --- 결과 판단 ---
BLOCKED=false

HAS_TOML=false
if [ -f "$GIT_ROOT/pyproject.toml" ]; then
  HAS_TOML=true
fi

if [ "$HAS_TOML" = true ] && { [ -z "$TOML_CHANGED" ] || [ -z "$HISTORY_CHANGED" ]; }; then
  BLOCKED=true
fi

if [ "$CI_STATUS" = "failed" ] || [ "$CI_STATUS" = "running" ]; then
  BLOCKED=true
fi

if [ "$BLOCKED" = true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "BLOCKED: 배포 전 체크리스트 미완료"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ "$HAS_TOML" = true ]; then
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
  fi

  case "$CI_STATUS" in
    passed)
      echo "  [x] GitHub CI — 통과"
      ;;
    failed)
      echo "  [ ] GitHub CI — 실패 ($CI_DETAIL)"
      ;;
    running)
      echo "  [ ] GitHub CI — 실행 중 (완료 후 재시도)"
      ;;
    none)
      echo "  [-] GitHub CI — $CI_DETAIL"
      ;;
    unknown)
      echo "  [-] GitHub CI — gh CLI 없음 (수동 확인 필요)"
      ;;
  esac

  echo ""
  echo "다음 단계: 미완료 항목 처리 후 재시도"
  exit 2
fi

exit 0
