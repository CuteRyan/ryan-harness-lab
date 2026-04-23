---
name: feedback
description: 대상 파일을 Claude Sub / Codex / Gemini 3개 CLI에 병렬로 리뷰받아 `docs/feedback/`에 저장 + Claude 메인이 종합.
---

# /feedback 스킬

**용도**: 지정한 파일(들)에 대해 3개 계열 LLM의 병렬 비판 리뷰 + Claude 메인 합성.

**설계 원칙**: 실행 로직은 PowerShell 스크립트(`scripts/`)가 담당하고, 이 md는 **LLM이 합성 단계에서 참조할 규칙**만 기술. PowerShell 코드블록을 md에서 해석해 실행하던 과거 방식(31회 백업의 원인)을 제거하고, `orchestrate.ps1` 1회 호출로 통합.

**3개 모두 병렬 시도는 필수**, 성공은 부분 허용 (≥1 성공이면 종합 작성). 다른 계열 교차검증이 /feedback의 핵심 목적.

---

## 실행 절차 (LLM이 수행)

### Step 1. 오케스트레이션 스크립트 호출

파일 1개당 1회 호출. 스크립트가 격리 디렉토리 준비·3 CLI 병렬 실행·타임아웃(5분)·재시도(1회)·실패 마커 기록까지 모두 수행.

```powershell
& "$HOME\.claude\skills\feedback\scripts\orchestrate.ps1" -SourceFile "<대상 파일 절대경로>"
```

- stdout으로 JSON 반환: `{claude_sub, codex, gemini, slug, isolated_dir, source_file}`
- N파일 처리는 파일당 1회 호출 (병렬로 여러 호출 가능)
- `-FeedbackDir` 인자로 저장 디렉토리 재정의 가능 (기본: 현재 경로의 `docs/feedback`)
- `-TimeoutSeconds` 인자로 병렬 대기 타임아웃 재정의 가능 (기본 300초 = 5분). hang 방지용 안전장치이므로 제거는 비추 — 큰 파일은 `-TimeoutSeconds 900` 등으로 늘려서 사용

### Step 2. Validation Gate

3개 결과 파일을 디스크 기반으로 검증. LLM 해석이 아닌 스크립트 판정.

```powershell
& "$HOME\.claude\skills\feedback\scripts\validate-outputs.ps1" -FilePaths @("<claude_sub 경로>", "<codex 경로>", "<gemini 경로>")
```

- JSON 반환: `{summary, valid_count, total, results: [{file, path, status, reason}]}`
- `status = VALID` 조건 (모두 만족): 파일 존재 + 크기 > 0 + 실패 마커 없음 + 중요도 태깅 접두사 `[치명]`·`[높음]`·`[중간]`·`[낮음]` 중 1개 이상이 **줄 시작 위치**(선택적 불릿 `-`/`*`, 번호 `1.`, ATX 헤더 `#`~`######` 허용)에 존재. 본문 인용 형태는 우회로 판정.

### Step 3. 종합 작성 (LLM 본 작업)

`valid_count ≥ 1` 이면 종합 작성. `valid_count = 0` 이면 "리뷰 불가, 수동 리뷰 필요"로 보고.

종합 파일: `docs/feedback/{YYYY-MM-DD}_claude_{슬러그}-종합.md`

종합 구조:
- 3개 원문 비교 요약
- 각 지적에 대한 [반영] / [유보] / [반박] 판정 + 사유
- Top 3 반영 우선순위
- 실패한 CLI는 "실패 — 사유: X"로 명시 (Validation Gate의 reason 활용)

### Step 4. 인덱스 갱신

`docs/feedback/index.md`에 1줄 추가 (날짜·대상 파일·슬러그·validation 요약).

---

## 프롬프트 템플릿

**SSOT**: `scripts/orchestrate.ps1` Step 3 의 `$promptLines` 배열이 유일한 원본. 수정 시 그 파일만 편집.

여기에 템플릿 전문 복사 금지 — 두 곳 관리 시 필연적으로 어긋남 (2026-04-22 메타 리뷰 공통 지적).

---

## 저장 규칙

| 파일 | 내용 |
|------|------|
| `docs/feedback/{YYYY-MM-DD}_claude-sub_{슬러그}.md` | Claude Sub 원문 (또는 실패 마커) |
| `docs/feedback/{YYYY-MM-DD}_codex_{슬러그}.md` | Codex 원문 (또는 실패 마커) |
| `docs/feedback/{YYYY-MM-DD}_gemini_{슬러그}.md` | Gemini 원문 (또는 실패 마커) |
| `docs/feedback/{YYYY-MM-DD}_claude_{슬러그}-종합.md` | Claude 메인 합성 (LLM 작성) |
| `docs/feedback/index.md` | 전체 리뷰 인덱스 (1줄 추가) |

슬러그 = `<대상파일basename>_<yyyyMMdd-HHmmss>` (격리 디렉토리명과 동일).

---

## 유효성 판정

**SSOT**: `scripts/validate-outputs.ps1` 의 판정이 **최종**. LLM은 이 판정을 그대로 수용.

판정 규칙 (스크립트 내부 구현):
1. 파일 존재 + 크기 > 0
2. `orchestrate` 실패 마커(`# <cli> 실행 실패`) 없음
3. 중요도 태깅 접두사 `[치명]`·`[높음]`·`[중간]`·`[낮음]` 중 1개 이상이 **줄 시작 위치**(불릿 `-`/`*`, 번호 `1.`, ATX 헤더 `#`~`######` 허용)에 존재. 본문 인용 불가.
4. 근거 1개 이상 — `근거` 키워드 / URL / `파일.확장자:줄번호` 중 하나

**환경 환각 감지** (LLM이 종합 시 체크): CLI가 "파일 mojibake/깨짐" 류 지적 → 원본 파일 UTF-8 정상이면 [반박] (CLI 자기 stdout 환경 문제, 2026-04-21 Codex dogfood 실측).

---

## 실패 처리

- **각 CLI 실패**: `orchestrate.ps1`이 async → sync 재시도 1회 후 실패 마커 파일 기록. LLM은 해당 CLI를 "실패" 처리.
- **≥ 1개 VALID**: 종합 작성 (실패한 것은 "실패 — 사유: X"로 명시).
- **3개 모두 INVALID**: 종합에 "리뷰 불가, 수동 리뷰 필요" 보고.

---

## 권한 분리

- **서브 리뷰 CLI (Claude Sub / Codex / Gemini)**: 읽기 전용
  - Claude Sub: `--permission-mode plan` (쓰기 차단) — `run-claude-sub.ps1`에 고정
  - Codex: `-C "$isolated"` 격리 디렉토리 고정 — CLI 자체 read-only 옵션 없어 격리로 완화
  - Gemini: `--approval-mode plan` — `run-gemini.ps1`에 고정
- **메인 /feedback 실행자 (Claude Code 본 세션)**: `docs/feedback/`에 파일 저장·인덱스 갱신 가능. "리뷰 도구는 읽기만"은 서브 CLI 한정.

---

## 기타 제약

- `claude /status` 등 슬래시 커맨드 호출 금지 (서브-서브 프로세스 발생).
- 프롬프트의 절대경로는 **원본 아니라 격리 디렉토리 복사본 경로** (`orchestrate.ps1`이 자동 조립).
- 세션 CWD 오염 방지는 `run-gemini.ps1`의 Push-Location/Pop-Location 로 처리됨.

---

## 이전 피드백 참조

같은 대상을 재리뷰할 때만 `docs/feedback/index.md`에서 과거 지적 1개를 프롬프트에 첨부 (맥락 제공용, 1회 한정). 프롬프트 수정이 필요하므로 `orchestrate.ps1`의 `$prompt`에 조건부 분기를 추가하거나 인자로 전달받아야 함 (MVP에서는 미구현 — Phase 2).

---

## 스크립트 파일 목록

- `scripts/prepare-isolation.ps1` — 격리 디렉토리 생성
- `scripts/run-claude-sub.ps1` — Claude Sub 호출
- `scripts/run-codex.ps1` — Codex 호출
- `scripts/run-gemini.ps1` — Gemini 호출 (Push/Pop-Location 내장)
- `scripts/orchestrate.ps1` — 위 스크립트들 병렬 실행 + 타임아웃 + 재시도 (LLM이 Step 1에서 호출)
- `scripts/validate-outputs.ps1` — Validation Gate (LLM이 Step 2에서 호출)

---

## Phase 2 후보 (MVP 제외)

- bash 버전 병행 (리눅스 서버 배포용)
- Pester 유닛 테스트
- 재리뷰 시 이전 피드백 자동 첨부
- 로깅 (실행 시간·재시도 이력)
