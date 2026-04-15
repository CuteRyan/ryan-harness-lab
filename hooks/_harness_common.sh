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
  local hook_name="$1"
  local action="$2"
  local detail="$3"
  local log_file="${PROJECT_ROOT:-.}/.claude/harness-audit.log"

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

# 파일 위치에서 상위로 올라가며 특정 파일 탐색
# 사용: harness_find_upward "$START_DIR" ".dev-checklist.md"
harness_find_upward() {
  local dir="$1"
  local name="$2"
  local parent

  dir=$(echo "$dir" | tr '\\' '/')

  while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
    if [ -f "$dir/$name" ]; then
      echo "$dir/$name"
      return 0
    fi
    parent=$(harness_parent_dir "$dir") || break
    dir="$parent"
  done

  return 1
}

harness_has_heading() {
  local file="$1"
  local pattern_list="$2"
  local pattern
  local IFS='|'

  for pattern in $pattern_list; do
    grep -qiF "## $pattern" "$file" 2>/dev/null && return 0
    grep -qiF "##$pattern" "$file" 2>/dev/null && return 0
  done

  return 1
}

harness_checklist_has_approval() {
  local file="$1"

  grep -qiE '^[[:space:]-]*approved:[[:space:]]*(true|yes|approved)[[:space:]]*$' "$file" 2>/dev/null && return 0
  grep -qiE '^status:[[:space:]]*approved[[:space:]]*$' "$file" 2>/dev/null && return 0
  grep -qiE '^[[:space:]]*[-*][[:space:]]*\[[xX]\][[:space:]]*(주인님[[:space:]]*)?승인([[:space:]]|$)' "$file" 2>/dev/null && return 0
  grep -qiE '^[[:space:]]*[-*][[:space:]]*\[[xX]\][[:space:]]*approved([[:space:]]|$)' "$file" 2>/dev/null && return 0

  return 1
}

harness_checklist_item_count() {
  local file="$1"
  grep -Ec '^[[:space:]]*[-*][[:space:]]*\[[ xX]\][[:space:]]+[^[:space:]]' "$file" 2>/dev/null
}

harness_checklist_has_trivial_item() {
  local file="$1"
  grep -qiE '^[[:space:]]*[-*][[:space:]]*\[[ xX]\][[:space:]]*(구현|확인|수정|테스트|검증|작업|완료|implement|check|fix|test|verify|work|done)[[:space:]]*$' "$file" 2>/dev/null
}

harness_value_line_count() {
  local value="$1"
  if [ -z "$value" ]; then
    echo 0
    return 0
  fi
  printf '%s' "$value" | awk 'END { print NR }'
}

harness_tiny_edit_allowed() {
  local tool_name="$1"
  local old_string="$2"
  local new_string="$3"
  local max_lines="${HARNESS_TINY_EDIT_LINES:-3}"
  local max_chars="${HARNESS_TINY_EDIT_CHARS:-240}"
  local old_lines
  local new_lines
  local old_chars
  local new_chars

  if [ "$tool_name" != "Edit" ]; then
    return 1
  fi

  if [ -z "$old_string" ] || [ -z "$new_string" ]; then
    return 1
  fi

  old_lines=$(harness_value_line_count "$old_string")
  new_lines=$(harness_value_line_count "$new_string")
  old_chars=${#old_string}
  new_chars=${#new_string}

  if [ "$old_lines" -le "$max_lines" ] && [ "$new_lines" -le "$max_lines" ] && \
     [ "$old_chars" -le "$max_chars" ] && [ "$new_chars" -le "$max_chars" ]; then
    return 0
  fi

  return 1
}

# 체크리스트 품질 검증
# 사용: harness_validate_checklist "$CHECKLIST" "dev|doc"
# 실패 시 CHECKLIST_ERROR에 이유 저장
harness_validate_checklist() {
  local checklist="$1"
  local kind="$2"
  local item_count

  CHECKLIST_ERROR=""

  if [ ! -f "$checklist" ]; then
    CHECKLIST_ERROR="체크리스트 파일이 없습니다."
    return 1
  fi

  if ! harness_checklist_has_approval "$checklist"; then
    CHECKLIST_ERROR="승인 마커가 없습니다. 'status: approved', 'approved: true', 또는 '- [x] 승인'을 추가하세요."
    return 1
  fi

  if [ "$kind" = "dev" ]; then
    harness_has_heading "$checklist" "구현 항목|작업 항목|Implementation|Tasks" || {
      CHECKLIST_ERROR="'## 구현 항목' 또는 '## Tasks' 섹션이 없습니다."
      return 1
    }
    harness_has_heading "$checklist" "수정 대상 파일|Changed Files|Target Files|Files" || {
      CHECKLIST_ERROR="'## 수정 대상 파일' 또는 '## Changed Files' 섹션이 없습니다."
      return 1
    }
    harness_has_heading "$checklist" "검증 항목|Verification" || {
      CHECKLIST_ERROR="'## 검증 항목' 또는 '## Verification' 섹션이 없습니다."
      return 1
    }
    harness_has_heading "$checklist" "더블 체크|Double Check" || {
      CHECKLIST_ERROR="'## 더블 체크' 또는 '## Double Check' 섹션이 없습니다."
      return 1
    }
  else
    harness_has_heading "$checklist" "작업 범위|작업 내용|Scope|Work Scope|Content" || {
      CHECKLIST_ERROR="'## 작업 범위' 또는 '## Scope' 섹션이 없습니다."
      return 1
    }
    harness_has_heading "$checklist" "연관 문서|Related Docs|Related Documents" || {
      CHECKLIST_ERROR="'## 연관 문서' 또는 '## Related Docs' 섹션이 없습니다."
      return 1
    }
    harness_has_heading "$checklist" "교차 검증|Cross Check|Cross Verification" || {
      CHECKLIST_ERROR="'## 교차 검증' 또는 '## Cross Check' 섹션이 없습니다."
      return 1
    }
    harness_has_heading "$checklist" "더블 체크|Double Check" || {
      CHECKLIST_ERROR="'## 더블 체크' 또는 '## Double Check' 섹션이 없습니다."
      return 1
    }
  fi

  item_count=$(harness_checklist_item_count "$checklist")
  if [ "$item_count" -lt 3 ]; then
    CHECKLIST_ERROR="체크박스 항목이 3개 미만입니다."
    return 1
  fi

  if harness_checklist_has_trivial_item "$checklist"; then
    CHECKLIST_ERROR="'구현', '확인', '수정' 같은 한 단어 체크 항목은 사용할 수 없습니다."
    return 1
  fi

  return 0
}
