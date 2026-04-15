#!/bin/bash
# 하네스 훅 공통 함수
# opt-in 검사 + dry-run 로그 기록
# 다른 훅에서 source로 불러와 사용

# .harness.yml opt-in 검사
# 사용: find_harness_yml "$FILE_PATH"
# 성공 시 PROJECT_ROOT 변수 설정 + return 0
# 실패 시 return 1 (.harness.yml 없음 또는 git 프로젝트 아님)
find_harness_yml() {
  local file_path="$1"
  local dir

  # 파일 경로에서 디렉토리 추출 후 git root 찾기
  dir=$(cd "$(dirname "$file_path")" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$dir" ]; then
    return 1
  fi

  PROJECT_ROOT="$dir"

  if [ -f "$PROJECT_ROOT/.harness.yml" ]; then
    return 0
  fi
  return 1
}

# dry-run 로그 기록
# 사용: harness_log "hook-name" "action" "detail"
# action: triggered | warn | would-block
# PROJECT_ROOT가 설정되어 있어야 함 (find_harness_yml 호출 후)
harness_log() {
  local hook_name="$1"
  local action="$2"
  local detail="$3"
  local log_file="${PROJECT_ROOT:-.}/.claude/harness-audit.log"

  mkdir -p "$(dirname "$log_file")" 2>/dev/null
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] hook=$hook_name action=$action detail=$detail" >> "$log_file" 2>/dev/null
}
