---
title: "/feedback 인코딩 깨짐 — 근본 원인 3 레이어 분석"
owner: analyst
date: 2026-04-23
scope: /feedback 스킬 한글 mojibake 반복 발생 원인 진단
inputs:
  - C:/Users/rlgns/.claude/skills/feedback/SKILL.md
  - C:/Users/rlgns/.claude/skills/feedback/scripts/run-claude-sub.ps1
  - C:/Users/rlgns/.claude/skills/feedback/scripts/run-codex.ps1
  - C:/Users/rlgns/.claude/skills/feedback/scripts/run-gemini.ps1
  - C:/Users/rlgns/.claude/skills/feedback/scripts/orchestrate.ps1
  - docs/history/2026-04-22.md (H1 / 작업 A Claude Sub mojibake 실측)
---

# /feedback 인코딩 깨짐 — 근본 원인 3 레이어 분석

> 2026-04-22 `run-claude-sub.ps1`에 `[Console]::OutputEncoding = UTF8` 한 줄을 넣어 1차 대응했으나 여전히 재발. **단일 스크립트 단일 라인 패치로는 커버되지 않는 3개 레이어**가 동시에 관여하고 있음을 확인.

---

## 레이어 맵

| 레이어 | 방향 | 지배 변수 | 현재 스킬 상태 |
|---|---|---|---|
| **L1 — stdout 디코딩** | CLI stdout 바이트 → PS `string` | `[Console]::OutputEncoding` | 3개 CLI 중 1개만 설정 |
| **L2 — 인자 인코딩** | PS `string` → CLI argv/stdin 바이트 | `$OutputEncoding`, shell argv 코드페이지 | 전원 누락 + Gemini `-p` 인자는 별도 버그 |
| **L3 — Start-Job runspace** | 부모 PS 설정 → 자식 Job runspace 상속 | `Start-Job` ScriptBlock 내부 재설정 | 누락 (부모 설정이 자식에 전파 X) |

---

## L1. stdout 디코딩 (CLI → PS)

### 메커니즘
- PS 5.1은 외부 실행파일 stdout 바이트를 `[Console]::OutputEncoding`으로 디코딩해 `string`으로 변환.
- 한국어 Windows 기본값은 **CP949 (codepage 949)**.
- Claude/Codex/Gemini CLI는 **UTF-8 바이트**를 뿜음 → PS가 CP949로 해석 → mojibake.

### 현재 코드 실측

`run-claude-sub.ps1:36-37` — **유일하게 처리됨**:
```powershell
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$OutputEncoding = [System.Text.Encoding]::UTF8
```

`run-codex.ps1:33-35` — **누락**:
```powershell
$ErrorActionPreference = 'Stop'
$output = $null | codex.cmd exec --skip-git-repo-check -C $IsolatedDir $Prompt
```

`run-gemini.ps1:36-40` — **누락**:
```powershell
$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $IsolatedDir
try {
    $output = gemini.cmd -p $Prompt -o text --approval-mode plan
```

### 결과
Codex/Gemini stdout이 한글을 포함하면 PS 단계에서 이미 깨진 `string`이 됨. 이후 `Set-Content -Encoding UTF8`은 **이미 망가진 문자열을 UTF-8로 저장**하므로 파일에서 복구 불가.

---

## L2. 인자 인코딩 (PS → CLI)

### 메커니즘
- `$OutputEncoding`은 PS가 외부 프로세스로 쓰는 파이프/stdin의 인코딩을 지배.
- **argv(명령줄 인자)는 별개**: Windows는 argv를 UTF-16으로 커널에 전달하지만, 각 exe의 C runtime이 이를 어떤 코드페이지로 재해석하느냐가 관건. 많은 Node/Go CLI가 **시스템 ANSI 코드페이지(CP949)**로 해석 → 한글 손실.
- 파이프 stdin은 `$OutputEncoding` 설정 유효.

### 현재 코드 실측

`orchestrate.ps1:38-52` — 프롬프트는 한글 포함:
```powershell
$promptLines = @(
    "다음 파일을 리뷰해주세요: $isolatedFilePath",
    '요구 포맷 (엄격):',
    '- 각 지적의 첫 줄 맨 앞(줄 시작)에 대괄호 태그 [치명] [높음] [중간] [낮음] 중 하나를 반드시 부착.',
    ...
)
```

`run-gemini.ps1:40` — 이 한글 프롬프트를 `-p` **argv 인자**로 직접 전달:
```powershell
$output = gemini.cmd -p $Prompt -o text --approval-mode plan
```

### 별도 실증 버그
gemini-cli 이슈 #20186 (2026-02 보고, 미해결) — Windows PS에서 `-p "<한글>"` 전달 시 한글이 손상된 바이트로 CLI에 도착. 보고자가 확인한 유일한 우회책은 **파일 기반 전달**(`--file`, stdin 파이프 등).

Codex도 비슷한 동력(`openai/codex` #4498) — `-NoProfile`로 UTF-8 프로필이 로드되지 않아 argv 경로에서 CP949 해석 발생.

### 결과
프롬프트 자체가 CLI에 도달하기 전에 깨짐 → CLI는 깨진 프롬프트를 읽고 응답 생성 → 응답 품질 저하 + 응답 내 한글 재인용 시 이중 mojibake.

---

## L3. Start-Job runspace 격리

### 메커니즘
- `Start-Job`은 **별도 PowerShell 프로세스**(또는 별도 runspace)에서 ScriptBlock 실행.
- 부모 세션의 `[Console]::OutputEncoding` / `$OutputEncoding` / `$PROFILE` 로드 결과는 **자식에 상속되지 않음**.
- 자식 잡 내부에서 **다시** 설정해야 유효.

### 현재 코드 실측

`orchestrate.ps1:72-77`:
```powershell
foreach ($cli in $cliNames) {
    $jobs[$cli] = Start-Job -Name $cli -ScriptBlock {
        param($ScriptPath, $Isolated, $P, $Out)
        & $ScriptPath -IsolatedDir $Isolated -Prompt $P -OutputFile $Out
    } -ArgumentList $cliScripts[$cli], $isolated, $prompt, $outputs[$cli]
}
```

- Start-Job ScriptBlock 내부에서 `[Console]::OutputEncoding` 설정 없음.
- 자식 스크립트(`run-*.ps1`) 내부에 설정이 있어야 커버됨 → `run-claude-sub.ps1`만 있고 나머지 누락(L1과 맞물림).
- 더 문제: `Start-Job` 자체가 한글 argv(`$P = $prompt`)를 자식으로 전달하는 과정에서도 인코딩 변환이 있음. PS 5.1은 여기를 UTF-16으로 넘기므로 자식 PS 내부까지는 무손실. **자식 PS → CLI argv 단계에서만 유실** (L2와 동일 문제).

---

## 2026-04-22 1차 대응이 실패한 이유

`run-claude-sub.ps1`에만 L1 두 줄 추가:
- Claude Sub는 이후 안정. **L1은 맞게 짚었음**.
- 그러나 Codex/Gemini 같은 구멍 방치 → 재발 시 어느 CLI가 깨졌는지만 바뀜.
- L2(Gemini argv) / L3(Job runspace) 는 아예 미인지 상태.

핵심 원인: **단일 CLI 단일 레이어 패치**. 3 레이어 × 3 CLI = 9개 교차점 중 1개만 막음.

---

## 검증 가설 (03_fix-plan.md로 연결)

| 가설 | 검증 방법 |
|---|---|
| L1 수정만으로 Codex/Gemini 깨짐 해소 | 3 CLI 모두 L1 2줄 + `$PSDefaultParameterValues` 추가 → 한글 포함 md 대상 스모크 |
| L2가 Gemini 단독 이슈 | 한글 프롬프트로 Gemini만 재현, Codex·Claude Sub는 정상 확인 |
| L3이 병렬 실행 시에만 재현 | `orchestrate.ps1` 병렬 vs 순차 직접 호출 비교 |

---

## 연관 문서
- [02_web-evidence.md](02_web-evidence.md) — 각 레이어의 외부 근거 URL 정리
- [03_fix-plan.md](03_fix-plan.md) — 레이어별 수정안 + 검증 절차
- `docs/history/2026-04-22.md` — 1차 대응 기록(H1 / 작업 A)
