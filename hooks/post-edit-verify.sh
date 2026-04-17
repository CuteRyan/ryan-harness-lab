#!/bin/bash
# Claude Code PostToolUse hook: Edit/Write 후 최소 검증
# - Python 파일은 py_compile로 문법 오류를 즉시 검출
# - Markdown 파일은 상대 로컬 링크 대상 존재 여부를 확인
# - 체크리스트 파일은 완료 처리한 파일 경로가 실제 존재하는지 확인
# - frontmatter가 있으면 필수 필드를 확인하고, doc_templates 신규 문서는 frontmatter를 요구
# - 병합 충돌 마커가 남아 있으면 차단

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
source "$SCRIPT_DIR/_harness_common.sh" 2>/dev/null || source ~/.claude/hooks/_harness_common.sh 2>/dev/null || true
if command -v harness_timer_start >/dev/null 2>&1; then
  harness_timer_start
  trap 'harness_timer_stop "post-edit-verify"' EXIT
fi

INPUT=$(cat)
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

FILE_PATH=$(echo "$FILE_PATH" | tr '\\' '/')
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_ROOT=$(harness_project_root_for_path "$FILE_PATH")
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd)
fi

if grep -qE '^(<<<<<<<|=======|>>>>>>>)' "$FILE_PATH" 2>/dev/null; then
  harness_log "post-edit-verify" "blocked" "$FILE_PATH conflict marker"
  echo "[harness/post] 병합 충돌 마커가 남아 있습니다: $FILE_PATH" >&2
  exit 1
fi

find_python() {
  local root="$1"
  for path in \
    "$root/venv/Scripts/python.exe" \
    "$root/.venv/Scripts/python.exe" \
    "$root/venv/bin/python" \
    "$root/.venv/bin/python"
  do
    if [ -f "$path" ]; then
      echo "$path"
      return 0
    fi
  done
  command -v python 2>/dev/null && return 0
  command -v python3 2>/dev/null && return 0
  return 1
}

case "$FILE_PATH" in
  *.py)
    PYTHON=$(find_python "$PROJECT_ROOT")
    if [ -z "$PYTHON" ]; then
      harness_log "post-edit-verify" "skip" "$FILE_PATH no python"
      exit 0
    fi
    OUTPUT=$("$PYTHON" -m py_compile "$FILE_PATH" 2>&1)
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
      harness_log "post-edit-verify" "blocked" "$FILE_PATH python syntax"
      echo "[harness/post] Python 문법 검증 실패: $FILE_PATH" >&2
      echo "$OUTPUT" | head -20 >&2
      exit 1
    fi
    harness_log "post-edit-verify" "pass" "$FILE_PATH python syntax"
    ;;
  *.md|*.markdown)
    PYTHON=$(find_python "$PROJECT_ROOT")
    if [ -z "$PYTHON" ]; then
      harness_log "post-edit-verify" "skip" "$FILE_PATH no python"
      exit 0
    fi
    REQUIRE_FRONTMATTER=false
    BASENAME=$(basename "$FILE_PATH")
    case "$FILE_PATH" in
      */docs/*|*/rules/*.md|*/.claude/rules/*)
        if [ "$TOOL_NAME" = "Write" ] && command -v harness_feature_enabled >/dev/null 2>&1 && harness_feature_enabled "doc_templates" "false"; then
          case "$BASENAME" in
            index.md|log.md|HISTORY.md|TEMPLATE.md|.dev-checklist.md|.doc-checklist.md|.checklist.md)
              REQUIRE_FRONTMATTER=false
              ;;
            *)
              case "$FILE_PATH" in
                */templates/*) REQUIRE_FRONTMATTER=false ;;
                *) REQUIRE_FRONTMATTER=true ;;
              esac
              ;;
          esac
        fi
        ;;
    esac

    OUTPUT=$("$PYTHON" - "$FILE_PATH" "$PROJECT_ROOT" "$TOOL_NAME" "$REQUIRE_FRONTMATTER" <<'PY' 2>&1
from pathlib import Path
import re
import sys
from urllib.parse import unquote

path = Path(sys.argv[1])
project_root = Path(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else path.parent
tool_name = sys.argv[3] if len(sys.argv) > 3 else ""
require_frontmatter = len(sys.argv) > 4 and sys.argv[4].lower() == "true"

try:
    text = path.read_text(encoding="utf-8")
except UnicodeDecodeError:
    text = path.read_text(encoding="utf-8-sig")

problems = []

required_frontmatter = {"title", "type", "status", "created"}
frontmatter = {}
has_frontmatter = text.startswith("---\n") or text.startswith("---\r\n")
if has_frontmatter:
    lines = text.splitlines()
    end = None
    for idx, line in enumerate(lines[1:], 1):
        if line.strip() == "---":
            end = idx
            break
    if end is None:
        problems.append("frontmatter: closing --- is missing")
    else:
        for line in lines[1:end]:
            if ":" not in line or line.startswith((" ", "\t", "-")):
                continue
            key, value = line.split(":", 1)
            frontmatter[key.strip()] = value.strip()
        missing = sorted(required_frontmatter - set(frontmatter))
        if missing:
            problems.append("frontmatter: missing required fields: " + ", ".join(missing))
elif require_frontmatter:
    problems.append("frontmatter: required for new docs when features.doc_templates=true")

pattern = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
for match in pattern.finditer(text):
    target = match.group(1).strip()
    if not target or target.startswith(("#", "http://", "https://", "mailto:", "tel:")):
        continue
    if "://" in target:
        continue
    target = target.split("#", 1)[0].strip()
    if not target:
        continue
    target = unquote(target)
    linked = (path.parent / target).resolve()
    if not linked.exists():
        problems.append(f"markdown link: missing target {target}")

def heading_name(line):
    if not line.startswith("##"):
        return None
    return line.lstrip("#").strip().lower()

def normalize_token(token):
    token = token.strip().strip("`'\".,;:)")
    return token.replace("\\", "/")

def is_external_or_anchor(token):
    return (
        not token
        or token.startswith("#")
        or token.startswith(("http://", "https://", "mailto:", "tel:"))
        or "://" in token
    )

def token_candidates(item):
    candidates = []
    for match in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", item):
        target = normalize_token(unquote(match.group(1).split("#", 1)[0]))
        if not is_external_or_anchor(target):
            candidates.append(target)
    for token in re.findall(r"`([^`]+)`", item):
        token = normalize_token(token)
        if not is_external_or_anchor(token):
            candidates.append(token)
    for token in re.findall(r"[\w./\\:-]+\.(?:py|md|markdown|json|ya?ml|toml|txt|rst|tsx?|jsx?|go|rs|java|cs|cpp|c|h|hpp|html|css)", item, flags=re.I):
        token = normalize_token(token)
        if not is_external_or_anchor(token):
            candidates.append(token)
    deduped = []
    for item in candidates:
        if item not in deduped:
            deduped.append(item)
    return deduped

def resolves_existing(token):
    candidate = Path(token)
    roots = []
    if candidate.is_absolute():
        roots.append(candidate)
    else:
        roots.append(project_root / token)
        roots.append(path.parent / token)
    return any(root.exists() for root in roots)

def validate_checked_file_items(kind):
    if kind == "dev":
        target_sections = {
            "수정 대상 파일", "changed files", "target files", "files",
        }
    else:
        target_sections = {
            "연관 문서", "related docs", "related documents",
        }
    current = None
    skip_words = {"none", "n/a", "na", "없음", "해당 없음", "not applicable"}
    for raw in text.splitlines():
        heading = heading_name(raw)
        if heading is not None:
            current = heading
            continue
        if current not in target_sections:
            continue
        match = re.match(r"^\s*[-*]\s*\[[xX]\]\s*(.+?)\s*$", raw)
        if not match:
            continue
        item = match.group(1).strip()
        if item.lower() in skip_words:
            continue
        candidates = token_candidates(item)
        if not candidates:
            problems.append(f"checklist: checked item has no file path: {item}")
            continue
        missing = [candidate for candidate in candidates if not resolves_existing(candidate)]
        if missing:
            problems.append("checklist: checked file path does not exist: " + ", ".join(missing))

if path.name == ".dev-checklist.md":
    validate_checked_file_items("dev")
elif path.name == ".doc-checklist.md":
    validate_checked_file_items("doc")
elif path.name == ".checklist.md":
    validate_checked_file_items("dev")

if problems:
    print("Post edit markdown verification failed:")
    for item in problems[:20]:
        print(f"- {item}")
    sys.exit(1)
PY
)
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
      harness_log "post-edit-verify" "blocked" "$FILE_PATH markdown"
      echo "[harness/post] Markdown 사후 검증 실패: $FILE_PATH" >&2
      echo "$OUTPUT" >&2
      exit 1
    fi
    harness_log "post-edit-verify" "pass" "$FILE_PATH markdown"
    ;;
esac

exit 0
