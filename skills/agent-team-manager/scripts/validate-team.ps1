<#
.NAME
    validate-team.ps1 — 고아·좀비·데드라인·중복 owner 검증 (Phase 7)

.WHY
    feedback/validate-outputs.ps1 대응. 룰 기반 판정 = 결정론.
    LLM 은 본 스크립트 JSON 판정을 수용 (이의 제기 금지, v2 spec §2 경계선).

.INPUTS
    -Team <name>      : 단일 팀 검증
    -AllTeams         : ~/.claude/teams/ 全 팀 일괄 검증
    -Format <type>    : json (기본) | table

.OUTPUTS
    JSON stdout: {
      "valid": true|false,
      "team_count": <int>,
      "results": [{team, status, issues, recommendations}]
    }

.EXIT CODES
    0 = 全 valid
    1 = 1건 이상 invalid

.SOURCE
    - v2 spec `04_redesign-spec.md §3.1 Phase 7` (스펙 명세 차용)
    - feedback/validate-outputs.ps1 동일 철학 (LLM 이의 제기 금지)
#>

[CmdletBinding(DefaultParameterSetName = 'Single')]
param(
    [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
    [string]$Team,

    [Parameter(ParameterSetName = 'All', Mandatory = $true)]
    [switch]$AllTeams,

    [ValidateSet('json', 'table')]
    [string]$Format = 'json'
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$tasksRoot = Join-Path $HOME '.claude\tasks'
$teamsRoot = Join-Path $HOME '.claude\teams'

function Test-Team {
    param([string]$TeamName)

    $issues = @()
    $recommendations = @()
    $teamMetaDir = Join-Path $teamsRoot $TeamName
    $teamTaskDir = Join-Path $tasksRoot $TeamName
    $sentinelPath = Join-Path $teamTaskDir '.sentinel.json'

    # Issue 1: 고아 디렉토리 (teams/ 만 있고 tasks/ 또는 sentinel.json 없음)
    if (Test-Path $teamMetaDir) {
        if (-not (Test-Path $sentinelPath)) {
            $issues += @{ type = 'orphan_no_sentinel'; detail = "teams/$TeamName 존재하나 sentinel.json 부재" }
            $recommendations += "shutdown-team.ps1 -Team $TeamName 으로 archive 권장"
        }
    } else {
        $issues += @{ type = 'team_meta_missing'; detail = "teams/$TeamName 디렉토리 부재" }
    }

    if (-not (Test-Path $sentinelPath)) {
        return @{ team = $TeamName; status = 'invalid'; issues = $issues; recommendations = $recommendations }
    }

    # sentinel 파싱
    try {
        $sentinel = Get-Content -LiteralPath $sentinelPath -Raw | ConvertFrom-Json
    } catch {
        $issues += @{ type = 'sentinel_parse_fail'; detail = $_.Exception.Message }
        return @{ team = $TeamName; status = 'invalid'; issues = $issues; recommendations = $recommendations }
    }

    # Issue 2: 데드라인 초과
    $now = Get-Date
    $deadline = [DateTime]::Parse($sentinel.deadline)
    if ($deadline -lt $now) {
        $minOver = [int]($now - $deadline).TotalMinutes
        $issues += @{ type = 'deadline_exceeded'; detail = "${minOver}분 초과 (deadline: $($sentinel.deadline))" }
        $recommendations += "monitor-team.ps1 -Team $TeamName 으로 진행 상태 확인 후 shutdown 또는 deadline 연장"
    }

    # Issue 3: review_cycle_cap 초과
    if ($sentinel.review_cycle_count -gt $sentinel.review_cycle_cap) {
        $issues += @{ type = 'cycle_cap_exceeded'; detail = "$($sentinel.review_cycle_count) > $($sentinel.review_cycle_cap)" }
        $recommendations += "PM 에스컬레이션 또는 사장 직접 결정 (마스터플랜 §4.3 escalation)"
    }

    # Issue 4: 중복 owner (동일 task_id 의 owner 가 다중)
    $taskFiles = @()
    if (Test-Path $teamTaskDir) {
        $taskFiles = Get-ChildItem -Path $teamTaskDir -Filter '*.json' -File -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -ne '.sentinel.json' }
    }
    $taskMap = @{}
    foreach ($tf in $taskFiles) {
        try {
            $td = Get-Content -LiteralPath $tf.FullName -Raw | ConvertFrom-Json
            if ($td.id) {
                if ($taskMap.ContainsKey($td.id)) {
                    $issues += @{ type = 'duplicate_task_id'; detail = "task id=$($td.id) 중복 (owners: $($taskMap[$td.id]), $($td.owner))" }
                } else {
                    $taskMap[$td.id] = $td.owner
                }
            }
        } catch {
            $issues += @{ type = 'task_parse_fail'; detail = $tf.Name }
        }
    }

    # Issue 5: 미완료 task + deadline 초과 (zombie task)
    foreach ($tf in $taskFiles) {
        try {
            $td = Get-Content -LiteralPath $tf.FullName -Raw | ConvertFrom-Json
            if ($td.status -ne 'completed' -and $deadline -lt $now) {
                $issues += @{ type = 'zombie_task'; detail = "task '$($td.subject)' (id=$($td.id), owner=$($td.owner)) 미완료 + deadline 초과" }
            }
        } catch { }
    }

    $status = if ($issues.Count -eq 0) { 'valid' } else { 'invalid' }
    return @{
        team            = $TeamName
        status          = $status
        sentinel        = $sentinel
        issues          = $issues
        recommendations = $recommendations
    }
}

# 검증 대상 결정
$targets = @()
if ($PSCmdlet.ParameterSetName -eq 'All') {
    if (Test-Path $teamsRoot) {
        $targets = Get-ChildItem -Path $teamsRoot -Directory -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -notmatch '^\.' } |
                   ForEach-Object { $_.Name }
    }
} else {
    $targets = @($Team)
}

$results = @()
foreach ($t in $targets) {
    $results += Test-Team -TeamName $t
}

$invalidCount = @($results | Where-Object { $_.status -eq 'invalid' }).Count
$valid = ($invalidCount -eq 0 -and $results.Count -gt 0)

$summary = [pscustomobject]@{
    valid       = $valid
    team_count  = $results.Count
    invalid_count = $invalidCount
    results     = $results
    timestamp   = (Get-Date -Format 'o')
}

if ($Format -eq 'table') {
    Write-Host "=== validate-team summary ==="
    Write-Host "  total: $($results.Count) | invalid: $invalidCount | valid overall: $valid"
    foreach ($r in $results) {
        Write-Host "  [$($r.team)] $($r.status)  issues=$($r.issues.Count)"
        foreach ($i in $r.issues) {
            Write-Host "    - $($i.type): $($i.detail)"
        }
    }
} else {
    $summary | ConvertTo-Json -Depth 10
}

exit ($(if ($valid) { 0 } else { 1 }))
