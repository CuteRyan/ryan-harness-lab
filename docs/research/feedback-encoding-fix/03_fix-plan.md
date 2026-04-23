---
title: "/feedback 인코딩 깨짐 — 수정안 및 검증 절차"
owner: analyst
date: 2026-04-23
scope: L1/L2/L3 레이어별 구체 수정안 + 단계별 롤아웃 + 검증
depends_on:
  - 01_root-cause.md
  - 02_web-evidence.md
---

# /feedback 인코딩 깨짐 — 수정안 및 검증 절차

> [01_root-cause.md](01_root-cause.md)의 3 레이어 진단과 [02_web-evidence.md](02_web-evidence.md)의 외부 근거를 바탕으로, **MVP 범위 내 단기 패치**와 **장기 개선**을 분리 기술.

---

## 수정안 개요

| 단계 | 범위 | 레이어 | 리스크 | 예상 시간 |
|---|---|---|---|---|
| **A (최소)** | `_encoding.ps1` 헬퍼 + 3개 `run-*.ps1` + Start-Job | L1, L3 | 낮음 | 30분 |
| **B (중간)** | `$PSDefaultParameterValues`, BOM 처리, 로그 | L1 보강 | 낮음 | 30분 |
| **C (Gemini argv 우회)** | 프롬프트를 tempfile로 전달 | L2 | 중간 (Gemini CLI 호환성 실측 필요) | 1시간 |
| **D (장기)** | PS 7 이주, 배포 파이프라인 점검 | 전면 | 높음 | 별도 계획 |

**MVP 목표**: A + B 적용 후 스모크 통과 → C는 재발 시 착수. D는 Phase 2 후보.

---

## Step A — 최소 패치 (L1 + L3)

### A-1. 공통 헬퍼 분리

**신규 파일**: `skills/feedback/scripts/_encoding.ps1`

```powershell
# Dot-source 전용. UTF-8 I/O 인코딩 고정 (PS 5.1 ANSI 기본값 우회).
# 근거: docs/research/feedback-encoding-fix/02_web-evidence.md L1/L3
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-File:Encoding']    = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
```

**이유**:
- 3개 `run-*.ps1` + Start-Job ScriptBlock 내부에서 동일 설정 필요 → 중복 제거
- dot-source(`. <path>`)로 호출 스크립트의 스코프에 직접 적용
- `$PSDefaultParameterValues`는 근거 8 (codegenes.net)의 권장 패턴

### A-2. 3개 `run-*.ps1` 상단 공통 dot-source

**`run-codex.ps1` 수정**:
```powershell
# 현재 (33행)
$ErrorActionPreference = 'Stop'
$output = $null | codex.cmd exec ...
```
→
```powershell
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_encoding.ps1')
$output = $null | codex.cmd exec ...
```

**`run-gemini.ps1` 수정** (동일 패턴):
```powershell
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_encoding.ps1')
Push-Location -LiteralPath $IsolatedDir
```

**`run-claude-sub.ps1` 수정**:
- 기존 L33-37의 인라인 설정을 헬퍼 호출로 치환 → 중복 제거
```powershell
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_encoding.ps1')
```

### A-3. Start-Job ScriptBlock에도 삽입

**`orchestrate.ps1:72-77` 수정**:
```powershell
foreach ($cli in $cliNames) {
    $scriptDirForJob = $scriptDir  # 클로저 캡처 대비
    $jobs[$cli] = Start-Job -Name $cli -ScriptBlock {
        param($ScriptPath, $Isolated, $P, $Out, $ScriptsDir)
        . (Join-Path $ScriptsDir '_encoding.ps1')
        & $ScriptPath -IsolatedDir $Isolated -Prompt $P -OutputFile $Out
    } -ArgumentList $cliScripts[$cli], $isolated, $prompt, $outputs[$cli], $scriptDirForJob
}
```

**이유**:
- Start-Job은 별도 runspace → 자식 `run-*.ps1`의 헬퍼 호출보다 **먼저** 자식 PS 프로세스 자체를 UTF-8로 세팅해야 안전 (근거 6, 7).
- 자식 스크립트도 헬퍼를 다시 호출하지만 멱등(idempotent) → 문제없음.

---

## Step B — 중간 보강 (파일 저장 + 근거 기록)

### B-1. 출력 md 저장부 일관화

현재 `Set-Content -LiteralPath $out -Value ... -Encoding UTF8` 4곳:
- `orchestrate.ps1:134`, `run-claude-sub.ps1:62`, `run-codex.ps1:45`, `run-gemini.ps1:50`

PS 5.1의 `-Encoding UTF8`은 **BOM 포함 UTF-8**. 대부분 무해하지만 일부 툴(Go, 일부 마크다운 파서)에서 첫 줄에 BOM 문자가 보일 수 있음.

**선택 1 (현상 유지, 권장)**: 현재 코드 유지. `$PSDefaultParameterValues`가 자동 적용되면 중복이므로 명시 `-Encoding UTF8`은 제거해도 되지만 안전 마진으로 유지.

**선택 2 (BOM 제거 필요 시)**:
```powershell
# Set-Content 대신
[System.IO.File]::WriteAllText($OutputFile, $output, [System.Text.UTF8Encoding]::new($false))
```

**결정 기준**: 실제 소비처(Claude 메인 합성 + 주인님 육안 검토)가 BOM을 문제 삼지 않으면 선택 1. MVP는 선택 1.

### B-2. 진단 로그 (경량)

`orchestrate.ps1` Step 1 이후 1회:
```powershell
Write-Verbose "Parent encoding: Console=$([Console]::OutputEncoding.WebName), Output=$($OutputEncoding.WebName)"
```

**이유**: 재발 시 어느 레이어가 깨졌는지 빠른 진단. `-Verbose` 없으면 출력 없음 → 프로덕션 영향 0.

---

## Step C — Gemini argv 우회 (L2, 보류)

### 트리거
Step A+B 적용 후에도 Gemini 결과물에서 한글 깨짐 재현 시 착수.

### 방법
근거 4 (gemini-cli #20186)가 확인한 유일 우회책: 프롬프트를 tempfile에 쓰고 파일 경로만 인자로 전달.

**문제점**:
- gemini-cli가 `-f <file>` / `--prompt-file` 옵션을 지원하는지 **스킬 기획 시점에 미확인**.
- 대안: stdin 파이프 `Get-Content -Raw tmp.txt | gemini.cmd -o text --approval-mode plan`. 단 현재 `run-gemini.ps1`은 stdin 미사용이므로 호환 가능.

### 사전 실측 필요
```powershell
# 실측 1: gemini 도움말에 파일 입력 옵션 존재 확인
gemini.cmd --help | Select-String -Pattern 'file|prompt'

# 실측 2: stdin 파이프로 한글 프롬프트 전달 시 정상 응답 여부
"한국어 테스트: 이 문장을 그대로 반복하세요" | gemini.cmd -o text --approval-mode plan
```

### 구현 스케치
```powershell
# run-gemini.ps1
$promptFile = Join-Path $IsolatedDir '_prompt.txt'
[System.IO.File]::WriteAllText($promptFile, $Prompt, [System.Text.UTF8Encoding]::new($false))
$output = Get-Content -Raw -LiteralPath $promptFile | gemini.cmd -o text --approval-mode plan
Remove-Item -LiteralPath $promptFile -ErrorAction SilentlyContinue
```

**리스크**: Gemini CLI가 stdin을 안 읽으면 hang. 타임아웃은 `orchestrate.ps1`의 `Wait-Job -Timeout`이 잡아주지만 매번 full timeout 기다리는 사이드이펙트.

**결론**: MVP 제외. 재발 시 별도 체크리스트로 처리.

---

## Step D — 장기 (PS 7 이주, 보류)

- PS 7은 `$OutputEncoding` 기본값이 UTF-8 → L2 대부분 자연 해소.
- 단 하네스 프로젝트 배포 타깃(메모리 `project_deployment_target.md`: 최종 Linux 서버)과 현재 Windows 개발 환경 사이 PS 버전 관리 정책이 먼저 필요.
- Phase 2 후보. 별도 연구 문서로 분리.

---

## 검증 절차 (Step A+B 완료 후)

### V-1. 스모크 1 — 한글 대상 파일
대상: `docs/history/2026-04-22.md` (H1 섹션 한글 다수)

```powershell
& "$HOME\.claude\skills\feedback\scripts\orchestrate.ps1" `
    -SourceFile "C:\Users\rlgns\OneDrive\문서\Harness-engineering\docs\history\2026-04-22.md"
```

**판정**:
- [ ] 3개 결과 md 모두 `status=VALID` (validate-outputs.ps1 기준)
- [ ] 3개 결과 md 내 한글이 정상 렌더 (`한국어`, `인코딩`, `레이어` 등 검색)
- [ ] mojibake 패턴 부재 (`�`, `[\xC0-\xFB][\x80-\xBF]{2,}` 류 이상 바이트 시퀀스 grep 0건)

### V-2. 스모크 2 — 순수 영어 대상 (회귀 방지)
기존 정상 동작 케이스가 안 깨지는지 확인.

### V-3. 스모크 3 — 병렬 재현
Start-Job 경로만 테스트하기 위해 `-TimeoutSeconds 30` 짧게 잡고 3회 연속 실행 → 레이스/runspace 재현성 확인.

### V-4. 운영 동기화
스테이징(`skills/feedback/`) → 운영(`~/.claude/skills/feedback/`) 복사. 경로 기준: `C:\Users\rlgns\.claude\skills\feedback\scripts\*.ps1`.

---

## 체크리스트 항목 (후속 `/checklist` 스킬에서 그대로 채택)

1. [ ] `scripts/_encoding.ps1` 신규 작성 (A-1)
2. [ ] `run-claude-sub.ps1` 인라인 → dot-source 치환 (A-2)
3. [ ] `run-codex.ps1` dot-source 추가 (A-2)
4. [ ] `run-gemini.ps1` dot-source 추가 (A-2)
5. [ ] `orchestrate.ps1` Start-Job 블록에 dot-source 추가 (A-3)
6. [ ] Step B-1은 선택 1(현상 유지) 결정
7. [ ] Step B-2 진단 로그 1줄 추가 (선택)
8. [ ] 스테이징 → `~/.claude/skills/feedback/scripts/` 동기화
9. [ ] V-1 스모크 통과
10. [ ] V-3 병렬 스모크 3회 통과
11. [ ] 히스토리 `docs/history/2026-04-23.md` 보강

---

## 결정이 필요한 항목 (주인님 컨펌)

- **D1**. Step B-1에서 BOM 제거 필요 여부 — 기본 "유지"로 진행해도 되는지
- **D2**. Step C 사전 실측(gemini stdin 지원 여부)을 이번 세션에 포함할지 vs MVP 이후로 미룰지
- **D3**. `--add-dir`·`-C` 등 격리 옵션도 UTF-8 경로 전달 가능성 점검 필요할지 (OneDrive 한글 경로 배경)

**기본 진행 제안**: D1=유지, D2=미룸, D3=점검 — 주인님이 달리 원하시면 재조정.

---

## 연관 문서
- [01_root-cause.md](01_root-cause.md) — 3 레이어 원인 분석
- [02_web-evidence.md](02_web-evidence.md) — 웹 근거 수집
- `docs/history/2026-04-22.md` — 1차 대응(`run-claude-sub.ps1` L1 only) 기록
