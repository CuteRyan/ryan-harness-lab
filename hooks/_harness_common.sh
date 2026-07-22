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
    dir=$(harness_project_root_for_path "$file_path")
  fi
  if [ -z "$dir" ]; then
    return 1
  fi

  PROJECT_ROOT="$dir"
  HARNESS_YML="$PROJECT_ROOT/.harness.yml"

  if [ -f "$HARNESS_YML" ]; then
    return 0
  fi
  return 1
}

harness_feature_value() {
  local feature="$1"
  local file="${HARNESS_YML:-${PROJECT_ROOT:-}/.harness.yml}"

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    return 1
  fi

  awk -v feature="$feature" '
    function trim(s) {
      gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
      return s
    }
    function normalize(v) {
      v = trim(v)
      gsub(/["\r]/, "", v)
      return tolower(v)
    }
    {
      line = $0
      sub(/[ \t]*#.*/, "", line)
      if (line ~ /^[ \t]*$/) next

      raw = line
      indent = match(raw, /[^ ]/) - 1
      stripped = trim(raw)

      if (stripped ~ /^features:[ \t]*$/) {
        in_features = 1
        next
      }

      if (in_features && indent == 0 && stripped !~ /^-/) {
        in_features = 0
      }

      split(stripped, parts, ":")
      key = trim(parts[1])
      value = normalize(substr(stripped, index(stripped, ":") + 1))

      if (in_features && key == feature) {
        print value
        exit
      }

      if (key == "features." feature) {
        print value
        exit
      }
    }
  ' "$file" 2>/dev/null
}

# .harness.yml의 features.<name> 값 확인.
# 사용: harness_feature_enabled "wiki" "false"
harness_feature_enabled() {
  local feature="$1"
  local default_value="${2:-false}"
  local value

  value=$(harness_feature_value "$feature")
  if [ -z "$value" ]; then
    value="$default_value"
  fi

  case "$value" in
    true|yes|on|1|enabled)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# dry-run 로그 기록
# 사용: harness_log "hook-name" "action" "detail"
# action: triggered | warn | would-block
# PROJECT_ROOT가 설정되어 있어야 함 (find_harness_yml 호출 후)
harness_log() {
  [ -z "$PROJECT_ROOT" ] && return 0
  local hook_name="$1"
  local action="$2"
  local detail="$3"
  local log_file="$PROJECT_ROOT/.claude/harness-audit.log"

  mkdir -p "$(dirname "$log_file")" 2>/dev/null
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] hook=$hook_name action=$action detail=$detail" >> "$log_file" 2>/dev/null
}

harness_now_ms() {
  local raw
  raw=$(date +%s%3N 2>/dev/null)
  case "$raw" in
    *N*|"")
      echo "$(($(date +%s) * 1000))"
      ;;
    *)
      echo "$raw"
      ;;
  esac
}

harness_timer_start() {
  HARNESS_HOOK_START_MS=$(harness_now_ms)
}

harness_timer_stop() {
  local hook_name="$1"
  local threshold_ms="${2:-500}"
  local end_ms
  local elapsed_ms

  if [ -z "$HARNESS_HOOK_START_MS" ] || [ -z "$PROJECT_ROOT" ]; then
    return 0
  fi

  end_ms=$(harness_now_ms)
  elapsed_ms=$((end_ms - HARNESS_HOOK_START_MS))
  if [ "$elapsed_ms" -ge "$threshold_ms" ]; then
    harness_log "$hook_name" "slow" "${elapsed_ms}ms"
  fi
}

# dirname이 같은 값을 반환하는 Windows C: 루트 케이스를 안전하게 처리
harness_parent_dir() {
  local path="$1"
  local parent
  parent=$(dirname "$path")
  if [ "$parent" = "$path" ]; then
    return 1
  fi
  echo "$parent"
}

# 파일 경로 기준 프로젝트 루트 탐색
# 사용: harness_project_root_for_path "$FILE_PATH"
harness_project_root_for_path() {
  local file_path="$1"
  local dir
  local parent

  file_path=$(echo "$file_path" | tr '\\' '/')
  dir=$(dirname "$file_path")

  while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
    # 글로벌 ~/.claude는 프로젝트가 아니므로 탐색 대상에서 제외합니다.
    if [ "$(basename "$dir")" = ".claude" ] && [ -d "$dir/hooks" ]; then
      parent=$(harness_parent_dir "$dir") || break
      dir="$parent"
      continue
    fi
    if [ -d "$dir/.git" ] || [ -f "$dir/CLAUDE.md" ] || \
       [ -f "$dir/pyproject.toml" ] || [ -f "$dir/package.json" ] || \
       [ -d "$dir/docs" ]; then
      echo "$dir"
      return 0
    fi
    parent=$(harness_parent_dir "$dir") || break
    dir="$parent"
  done

  return 1
}
