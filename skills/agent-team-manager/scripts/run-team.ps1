<#
.NAME
    run-team.ps1 — sentinel 등록 (Phase 5)

.WHY
    teammate spawn 후 deadline + members 기록. 좀비/고아 감지 기반 데이터.
    스크립트는 tool 호출 안 함 (v2 spec §2 경계선 원칙). LLM 이 TeamCreate/spawn 후
    본 스크립트로 sentinel.json 만 기록.

.INPUTS
    -Team <name>           : 팀 이름 (필수)
    -SentinelInit          : sentinel.json 신설 (기본 모드)
    -TimeoutMinutes <int>  : deadline 분 (기본 30)
    -Preset <name>         : 사용한 preset (메타 추적)
    -Members <string[]>    : 멤버 이름 배열 (resolve-preset 출력에서 가져옴)

.OUTPUTS
    JSON stdout: {"ok": true, "sentinel_path": "...", "deadline": "ISO8601", "members": [...]}

.EXIT CODES
    0 = OK
    1 = sentinel 파일 신설 실패 또는 인자 invalid

.SOURCE
    - v2 spec `04_redesign-spec.md §3.1 Phase 5` (단독 구현 금지된 spec 의 sentinel 명세 차용)
    - feedback `.dev-checklist.md` 삭제 금지 원칙 (R-5 정합)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Team,

    [switch]$SentinelInit,

    [int]$TimeoutMinutes = 30,

    [string]$Preset,

    [string[]]$Members = @()
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$tasksRoot = Join-Path $HOME '.claude\tasks'
$teamDir = Join-Path $tasksRoot $Team
$sentinelPath = Join-Path $teamDir '.sentinel.json'

# Default mode = SentinelInit (편의)
if (-not $PSBoundParameters.ContainsKey('SentinelInit')) { $SentinelInit = $true }

if ($SentinelInit) {
    if (-not (Test-Path $teamDir)) {
        New-Item -ItemType Directory -Path $teamDir -Force | Out-Null
    }

    $now = Get-Date
    $deadline = $now.AddMinutes($TimeoutMinutes)

    $sentinel = [pscustomobject]@{
        team               = $Team
        preset             = $Preset
        start_time         = $now.ToString('o')
        deadline           = $deadline.ToString('o')
        timeout_minutes    = $TimeoutMinutes
        members            = $Members
        review_cycle_count = 0
        review_cycle_cap   = 3
        created_by         = 'run-team.ps1'
    }

    try {
        $sentinel | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $sentinelPath -Encoding UTF8
    } catch {
        @{ ok = $false; error = "sentinel write failed: $($_.Exception.Message)" } | ConvertTo-Json
        exit 1
    }

    @{
        ok            = $true
        sentinel_path = $sentinelPath
        deadline      = $deadline.ToString('o')
        members       = $Members
        team          = $Team
        preset        = $Preset
    } | ConvertTo-Json -Depth 5
    exit 0
}

# 다른 모드 (향후 확장: -Tick, -IncrementCycle)
@{ ok = $false; error = 'unknown mode (use -SentinelInit)' } | ConvertTo-Json
exit 1
