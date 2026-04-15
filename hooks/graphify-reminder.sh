#!/bin/bash
# Claude Code PreToolUse hook: 코드 프로젝트에서 GRAPH_REPORT.md 부재 시 리마인더
# - 코드 파일(.py, .js, .ts 등) Edit 시 graphify-out/GRAPH_REPORT.md 존재 확인
# - .harness.yml opt-in 필수: 없으면 no-op (경고도 안함)
# - 없으면 경고 메시지 출력 (차단하지 않음 — exit 0 유지)
# - 코드 파일 10개 미만 프로젝트는 무시

# 공통 함수 로드 (opt-in 검사 + 로그)
source ~/.claude/hooks/_harness_common.sh 2>/dev/null || exit 0

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

# .harness.yml opt-in 검사 — 없으면 no-op
if ! find_harness_yml "$FILE_PATH"; then
  exit 0
fi

# 코드 파일 확장자인지 확인
if ! echo "$FILE_PATH" | grep -qE '\.(py|js|ts|tsx|jsx|go|java|rs|rb|php|swift|kt|c|cpp|h|hpp|cs)$'; then
  exit 0
fi

# 프로젝트 루트 찾기 (git root 또는 파일의 디렉토리)
PROJECT_DIR=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_DIR" ]; then
  # git 프로젝트가 아니면 통과
  exit 0
fi

# 이미 GRAPH_REPORT.md가 있으면 통과
if [ -f "$PROJECT_DIR/graphify-out/GRAPH_REPORT.md" ]; then
  exit 0
fi

# 코드 파일 10개 이상인지 확인 (빠르게 카운트)
CODE_COUNT=$(find "$PROJECT_DIR" -maxdepth 3 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o -name "*.go" -o -name "*.java" -o -name "*.rs" \) 2>/dev/null | head -11 | wc -l)

if [ "$CODE_COUNT" -lt 10 ]; then
  exit 0
fi

# 리마인더 출력 (차단하지 않음)
harness_log "graphify-reminder" "warn" "GRAPH_REPORT.md missing"
echo "[reminder] 이 프로젝트에 Graphify 그래프가 없습니다. \`/graphify .\`로 생성하면 코드 구조 파악에 도움됩니다." >&2
exit 0
