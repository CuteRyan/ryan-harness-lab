---
name: feedback
description: 대상 파일을 Claude Sub / Codex / Gemini 3개 CLI에 병렬로 리뷰받아 `docs/feedback/`에 저장 + Claude 메인이 종합.
---

# /feedback

**용도**: 지정한 파일(들)에 대해 3개 계열 LLM의 병렬 비판 리뷰 + Claude 메인 합성.

**3개 모두 병렬 시도는 필수**, 성공은 부분 허용 (≥1 성공이면 종합 작성). 다른 계열 교차검증이 /feedback의 핵심 목적.

## 0. 격리 준비 (호출 전 필수)

**왜**: 프롬프트로 "탐색 금지" 지침만으로는 권한 경계가 약함 (2026-04-21 Codex H2). 대상 파일을 임시 격리 디렉토리에 복사해 각 CLI에 그 디렉토리만 권한으로 전달.

**원칙**: **파일당 3 CLI 병렬 호출**. N파일이면 **N개 격리 디렉토리 × 3 CLI = N×3 호출**. 격리 디렉토리끼리 병렬, 각 디렉토리 내 3 CLI도 병렬.

```powershell
# 슬러그: 파일명 + 타임스탬프 (재사용 방지 — 이전 실행 잔존물 차단)
$slug = "$((Get-Item -LiteralPath <대상파일>).BaseName)_$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$isolated = "$HOME\codex-cwd\$slug"
New-Item -ItemType Directory -Path $isolated -ErrorAction Stop  # 존재 시 실패 → 새 slug 강제
Copy-Item -LiteralPath <대상파일> -Destination $isolated        # -LiteralPath: 특수문자/와일드카드 안전
```

- **프롬프트에 넣는 절대경로는 원본 아니라 격리 디렉토리의 복사본 경로** (2026-04-21 2차 dogfood Codex 중간 #4)
- 각 CLI는 이 디렉토리만 권한으로 받음 (호출 방식은 CLI별 Section 1 참조)

## 1. 호출 (3개 병렬)

**병렬 실행 + 타임아웃 (PowerShell `Start-Job` 권장)**:
```powershell
$jobs = @(
  Start-Job -ScriptBlock { <Claude Sub 호출> },
  Start-Job -ScriptBlock { <Codex 호출> },
  Start-Job -ScriptBlock { <Gemini 호출 — Push-Location/Pop-Location 포함> }
)
$jobs | Wait-Job -Timeout 300   # 5분 타임아웃 (hang 방지)
$jobs | ForEach-Object { Receive-Job $_; Remove-Job $_ }
```
- 타임아웃 초과 CLI는 실패로 기록, 나머지 결과로 진행
- bash 환경에서는 `&` + `wait` + `timeout 300 <cmd>` 패턴


### Claude Sub
```powershell
claude -p "<프롬프트>" --permission-mode plan --allowed-tools "Read" --output-format json --model sonnet --no-session-persistence --add-dir "$isolated"
```
- `--allowed-tools "Read"`: Grep/Glob 제거 (단일 파일 리뷰에 불필요 + 탐색 경계 강화)
- `--add-dir "$isolated"`: 격리 디렉토리만
- 결과: stdout JSON의 `result` 필드 = Markdown 본문

### Codex
```powershell
$null | codex.cmd exec --skip-git-repo-check -C "$isolated" "<프롬프트>"
```
- `$null |` 패턴: PowerShell/bash 양쪽 호환 (bash `</dev/null` 불가)
- `-C "$isolated"`: 격리 디렉토리 사용 (Section 0에서 준비)
- `--output-schema` 강제 금지 (early return) — stdout 원문 Markdown
- PowerShell Constrained Language 환경에서 stdout mojibake 발생 가능하나 **파일 본문은 무관** (2026-04-21 dogfood 실측)

### Gemini
```powershell
Push-Location "$isolated"
try {
  gemini.cmd -p "<프롬프트>" -o text --approval-mode plan
} finally {
  Pop-Location   # 세션 CWD 복구 필수 (이후 저장/index 갱신 경로 오염 방지)
}
```
- **CWD = 격리 디렉토리** — Gemini는 `--include-directories` 플래그로 workspace 확장이 안 됨 (2026-04-21 2차 dogfood 실측: 격리 경로 거부 후 프로젝트 구버전으로 폴백). CWD 전환이 유일한 안정 격리 방법
- **`Push-Location`/`Pop-Location` 필수** — `cd` 단순 사용 시 세션 CWD가 격리 디렉토리로 고정되어 이후 저장 경로 오염 (2026-04-21 3차 dogfood 공통 지적)
- **프리앰블 규칙** = Section 2 프롬프트 템플릿 전체. 생략 시 rubber-stamp (Day 7 실측)

## 2. 프롬프트 (고정 템플릿)

```
다음 파일을 리뷰해주세요: <절대경로>

요구 포맷:
- 중요도(치명/높음/중간/낮음)별 섹션
- 각 지적마다 파일:줄 + 근거 1개 (실측 출력 / 공식 문서 URL / 파일 내용 인용 중 하나)
- 근거 없는 찬성(✅) 금지 — 문제 없으면 "없음 — 근거: X"
- 접근 실패·맥락 부족은 추측 말고 명시 ("확인 불가" 태그)
- 마지막에 Top 3 반영 우선순위

대상 파일만 읽고 폴더 재귀 탐색 금지.
```

## 3. 저장 (항상 4개 파일)

| 파일 | 내용 |
|------|------|
| `docs/feedback/{YYYY-MM-DD}_claude-sub_{슬러그}.md` | Claude Sub 원문 |
| `docs/feedback/{YYYY-MM-DD}_codex_{슬러그}.md` | Codex 원문 (실패 시 실패 사유 기록) |
| `docs/feedback/{YYYY-MM-DD}_gemini_{슬러그}.md` | Gemini 원문 (실패 시 실패 사유 기록) |
| `docs/feedback/{YYYY-MM-DD}_claude_{슬러그}-종합.md` | Claude 메인 합성: 3개 비교 + [반영]/[유보]/[반박] 판정 + 반영 우선순위 |

`docs/feedback/index.md`에 1줄 추가.

## 4. 실패 처리

- **각 CLI 실패** → 재시도 1회 후 실패 사유를 해당 CLI 파일에 기록하고 넘어감
- **≥ 1개 성공** → 종합 작성 (실패한 것은 "실패 — 사유: X"로 명시)
- **3개 모두 실패** → 종합에 "리뷰 불가, 수동 리뷰 필요" 보고

**리뷰 유효성 판정**:
- **필수 조건 (둘 다 만족해야 유효)**:
  1. 중요도 태깅(치명/높음/중간/낮음) 존재
  2. 최소 1개 지적에 **근거 있음** — 파일:줄 / 공식 문서 URL / 명령 출력 인용 / "근거 있는 없음"(문제 없으면 "없음 — 근거: X") 중 하나
- CLI exit code 0은 별도 실행 성공 게이트일 뿐 품질 판정 아님 (rubber-stamp도 exit 0 — 2026-04-21 Claude Sub H2)
- 미만 시 재호출 1회, 여전히 미달이면 [유보]

**Gemini rubber-stamp 감지**: 중요도 태깅 없음 + 파일:줄 없음 → 프리앰블 누락 가능. 재호출 1회 후 [반박].

**환경 환각 감지** (메인 Claude 합성 시):
- CLI가 "파일 mojibake/깨짐" 류 지적 시 → 원본 파일 UTF-8 검증 → 정상이면 [반박] (CLI 자기 stdout 환경 문제)
- 2026-04-21 Codex dogfood에서 H1/M5 연쇄 환각 실측

## 5. 제약

**권한 분리** (서브 CLI vs 메인 실행자):
- **서브 리뷰 CLI (Claude Sub / Codex / Gemini)**: 읽기 전용
  - Claude Sub: `--permission-mode plan` (쓰기 차단)
  - Codex: `-C "$isolated"`로 격리 디렉토리에 고정. **CLI 자체 read-only 강제 옵션 없음** — 격리로 완화
  - Gemini: `--approval-mode plan`
- **메인 /feedback 실행자 (Claude Code 본 세션)**: `docs/feedback/`에 4개 파일 저장 및 `index.md` 갱신 가능. "리뷰 도구는 읽기만"은 서브 CLI 한정

**기타**:
- `claude /status` 등 슬래시 커맨드 호출 금지 (서브-서브 프로세스 발생)
- N파일 처리는 Section 0 원칙(파일당 격리 디렉토리 1개, 총 N×3 호출) 참조

## 6. 이전 피드백 참조

같은 대상을 재리뷰할 때만 `docs/feedback/index.md`에서 과거 지적 1개를 프롬프트에 첨부 (맥락 제공용, 1회 한정).
