<#
.NAME
    preflight.ps1 — agent-team-manager 환경 검증 (Phase 0)

.WHY
    Phase 1 진입 전 4 전제조건 결정론적 검증 (LLM 해석 변동 차단).
    실패 시 메인 Claude (사장) 가 abort + reference/errors.md 의 reason 안내.

.INPUTS
    -Strict   : 부드러운 warn 도 fail 처리 (CI 모드)
    -SkipTmux : tmux 검사 생략 (Windows 환경 한정, 기본 = 활성)

.OUTPUTS
    JSON stdout: {"ok": true|false, "checks": [...], "abort_reason": null|"...", "warnings": [...]}

.EXIT CODES
    0 = OK (모든 critical 검사 PASS)
    1 = 실패 (critical 검사 1건 이상 fail)

.SOURCE
    - v2 spec `04_redesign-spec.md §1·§3.1 Phase 0` (단독 구현 금지된 spec 의 검증 항목 부분만 차용)
    - turn 8 #019 fallback C+ 영구 적용 → SUBAGENT_MODEL env 부재 검증 추가
    - turn 7 #018 강제 훅 활성 → claude-code 버전 ≥ 2.1.126 검증 추가
    - 본 비전 preset YAML 양식 (Day 20 turn 1) 정합 — pyyaml 모듈 검증
#>

[CmdletBinding()]
param(
    [switch]$Strict,
    [switch]$SkipTmux
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$checks = @()
$warnings = @()
$abortReason = $null

function Add-Check {
    param([string]$Name, [string]$Status, [string]$Detail, [bool]$Critical = $true)
    $script:checks += [pscustomobject]@{
        name     = $Name
        status   = $Status   # ok | warn | fail
        detail   = $Detail
        critical = $Critical
    }
    if ($Status -eq 'fail' -and $Critical) {
        if (-not $script:abortReason) { $script:abortReason = "$Name fail: $Detail" }
    } elseif ($Status -eq 'warn') {
        $script:warnings += "$Name : $Detail"
    }
}

# Check 1: env CLAUDE_CODE_SUBAGENT_MODEL 부재 (fallback C+ 정합, turn 8 #019)
$envModel = [Environment]::GetEnvironmentVariable('CLAUDE_CODE_SUBAGENT_MODEL', 'Process')
if ([string]::IsNullOrEmpty($envModel)) {
    Add-Check -Name 'env_subagent_model_absent' -Status 'ok' `
              -Detail 'CLAUDE_CODE_SUBAGENT_MODEL 부재 (fallback C+ 효과 유지)'
} else {
    Add-Check -Name 'env_subagent_model_absent' -Status 'fail' `
              -Detail "CLAUDE_CODE_SUBAGENT_MODEL=$envModel 잔존 (fallback C+ 위반, turn 8 #019 정합 깨짐)"
}

# Check 2: claude-code CLI 버전 (≥ 2.1.126, turn 7 #018 강제 훅 정합)
try {
    $cliVersion = & claude --version 2>$null
    if ($cliVersion -match '(\d+\.\d+\.\d+)') {
        $ver = [Version]$Matches[1]
        $minVer = [Version]'2.1.126'
        if ($ver -ge $minVer) {
            Add-Check -Name 'claude_code_version' -Status 'ok' `
                      -Detail "claude-code $ver (≥ $minVer, 강제 훅 Task|Agent matcher 활성)"
        } else {
            Add-Check -Name 'claude_code_version' -Status 'warn' `
                      -Detail "claude-code $ver < $minVer (강제 훅 작동 보장 안 됨, turn 7 #018 정합)" -Critical $false
        }
    } else {
        Add-Check -Name 'claude_code_version' -Status 'warn' `
                  -Detail "claude --version 출력 파싱 실패: $cliVersion" -Critical $false
    }
} catch {
    Add-Check -Name 'claude_code_version' -Status 'warn' `
              -Detail "claude CLI 호출 실패 (PATH 누락 또는 미설치): $($_.Exception.Message)" -Critical $false
}

# Check 3: subagent 컨텍스트 (메인 Claude = 사장 인지 확인)
$inSubagent = -not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('CLAUDE_CODE_SUBAGENT', 'Process'))
if ($inSubagent) {
    Add-Check -Name 'main_claude_context' -Status 'fail' `
              -Detail '본 스크립트는 메인 Claude (사장) 에서 호출되어야 함. 워커 컨텍스트에서 호출 불가 (R-2/issue#32731 nested team 불가)'
} else {
    Add-Check -Name 'main_claude_context' -Status 'ok' `
              -Detail '메인 Claude 컨텍스트 (사장) 확인'
}

# Check 4: PowerShell 버전 (5.1 또는 7+)
$psVer = $PSVersionTable.PSVersion
if ($psVer.Major -ge 5) {
    Add-Check -Name 'powershell_version' -Status 'ok' `
              -Detail "PowerShell $psVer (5.1+ 호환)"
} else {
    Add-Check -Name 'powershell_version' -Status 'fail' `
              -Detail "PowerShell $psVer < 5.0 (비호환)"
}

# Check 5: pyyaml 모듈 (resolve-preset.ps1 의존성)
try {
    $pyCheck = & python -c "import yaml; print(yaml.__version__)" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Add-Check -Name 'pyyaml_module' -Status 'ok' `
                  -Detail "pyyaml $pyCheck (preset YAML 파싱 가능)"
    } else {
        Add-Check -Name 'pyyaml_module' -Status 'fail' `
                  -Detail 'pyyaml 모듈 부재 — `pip install pyyaml` 필요 (resolve-preset.ps1 차단)'
    }
} catch {
    Add-Check -Name 'pyyaml_module' -Status 'fail' `
              -Detail "python 호출 실패: $($_.Exception.Message)"
}

# Check 6 (선택): tmux (Windows 환경 = SkipTmux 기본 권장)
if (-not $SkipTmux) {
    try {
        $tmuxVer = & tmux -V 2>$null
        if ($LASTEXITCODE -eq 0) {
            Add-Check -Name 'tmux_available' -Status 'ok' -Detail $tmuxVer -Critical $false
        } else {
            Add-Check -Name 'tmux_available' -Status 'warn' `
                      -Detail 'tmux 미설치 (display_mode: tmux 사용 시 inline 으로 fallback)' -Critical $false
        }
    } catch {
        Add-Check -Name 'tmux_available' -Status 'warn' `
                  -Detail 'tmux 미설치 (Windows 정상)' -Critical $false
    }
}

# Strict 모드: warn 도 abort
if ($Strict -and $warnings.Count -gt 0 -and -not $abortReason) {
    $abortReason = "Strict mode: $($warnings.Count) warnings = abort"
}

$ok = $null -eq $abortReason
$result = [pscustomobject]@{
    ok           = $ok
    checks       = $checks
    abort_reason = $abortReason
    warnings     = $warnings
    timestamp    = (Get-Date -Format 'o')
}

$result | ConvertTo-Json -Depth 10 -Compress:$false
exit ($(if ($ok) { 0 } else { 1 }))
