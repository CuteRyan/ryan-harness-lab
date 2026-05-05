<#
.NAME
    monitor-team.ps1 — 팀 상태 주기 덤프 (Phase 6)

.WHY
    파일시스템 주기 읽기는 스크립트가 안정적, LLM 은 출력만 해석 (v2 spec §2).
    좀비 / deadline 초과 / 진행 정체 감지 기반 데이터.

.INPUTS
    -Team <name>     : 팀 이름 (필수)
    -Format <type>   : json (기본) | table (사람 읽기)

.OUTPUTS
    JSON stdout: {
      "team": "...",
      "sentinel": {...},
      "now": "ISO8601",
      "deadline_remaining_min": <int>,
      "tasks": [...],
      "members": [{name, inbox_count, outbox_count, last_active}],
      "warnings": [...],
      "status": "active" | "stale" | "zombie" | "orphan"
    }

.EXIT CODES
    0 = active (정상)
    1 = zombie (deadline 초과)
    2 = orphan (sentinel.json 부재)

.SOURCE
    - v2 spec `04_redesign-spec.md §3.1 Phase 6` (스펙 명세 차용)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Team,

    [ValidateSet('json', 'table')]
    [string]$Format = 'json'
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$tasksRoot = Join-Path $HOME '.claude\tasks'
$teamsRoot = Join-Path $HOME '.claude\teams'
$teamTaskDir = Join-Path $tasksRoot $Team
$teamMetaDir = Join-Path $teamsRoot $Team
$sentinelPath = Join-Path $teamTaskDir '.sentinel.json'

$warnings = @()
$status = 'active'

# orphan 검사
if (-not (Test-Path $sentinelPath)) {
    $result = @{
        team     = $Team
        status   = 'orphan'
        warnings = @("sentinel.json not found at: $sentinelPath")
        now      = (Get-Date -Format 'o')
    }
    if ($Format -eq 'table') {
        Write-Host "[$Team] ORPHAN — sentinel.json 부재"
    } else {
        $result | ConvertTo-Json -Depth 5
    }
    exit 2
}

$sentinel = Get-Content -LiteralPath $sentinelPath -Raw | ConvertFrom-Json
$now = Get-Date
$deadline = [DateTime]::Parse($sentinel.deadline)
$remainingMin = [int]($deadline - $now).TotalMinutes

if ($remainingMin -lt 0) {
    $status = 'zombie'
    $warnings += "deadline 초과 ($([Math]::Abs($remainingMin)) 분)"
}

# task 상태 스캔 (~/.claude/tasks/<team>/ 의 task json 또는 디렉토리)
$tasks = @()
$taskFiles = @()
if (Test-Path $teamTaskDir) {
    $taskFiles = Get-ChildItem -Path $teamTaskDir -Filter '*.json' -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -ne '.sentinel.json' }
    foreach ($tf in $taskFiles) {
        try {
            $td = Get-Content -LiteralPath $tf.FullName -Raw | ConvertFrom-Json
            $tasks += [pscustomobject]@{
                id        = $td.id
                subject   = $td.subject
                owner     = $td.owner
                status    = $td.status
                blocked_by = $td.blocked_by
            }
        } catch {
            $warnings += "task file parse failed: $($tf.Name)"
        }
    }
}

# 멤버 inbox/outbox 카운트
$memberStats = @()
foreach ($mn in $sentinel.members) {
    $inbox = Join-Path $teamMetaDir "inboxes\$mn"
    $outbox = Join-Path $teamMetaDir "outboxes\$mn"
    $inCount = if (Test-Path $inbox) {
        @(Get-ChildItem -Path $inbox -File -ErrorAction SilentlyContinue).Count
    } else { 0 }
    $outCount = if (Test-Path $outbox) {
        @(Get-ChildItem -Path $outbox -File -ErrorAction SilentlyContinue).Count
    } else { 0 }
    $memberStats += [pscustomobject]@{
        name         = $mn
        inbox_count  = $inCount
        outbox_count = $outCount
    }
}

# review_cycle_cap 초과 검사
if ($sentinel.review_cycle_count -gt $sentinel.review_cycle_cap) {
    $warnings += "review_cycle_count=$($sentinel.review_cycle_count) > cap=$($sentinel.review_cycle_cap) (PM 에스컬레이션 권장)"
    if ($status -eq 'active') { $status = 'stale' }
}

$result = [pscustomobject]@{
    team                   = $Team
    sentinel               = $sentinel
    now                    = $now.ToString('o')
    deadline_remaining_min = $remainingMin
    tasks                  = $tasks
    members                = $memberStats
    warnings               = $warnings
    status                 = $status
}

if ($Format -eq 'table') {
    Write-Host "=== $Team ($status) ==="
    Write-Host "  deadline: $($sentinel.deadline)  (remaining: ${remainingMin}m)"
    Write-Host "  preset: $($sentinel.preset)  members: $($sentinel.members -join ', ')"
    Write-Host "  review_cycle: $($sentinel.review_cycle_count)/$($sentinel.review_cycle_cap)"
    Write-Host "  tasks: $($tasks.Count)"
    if ($warnings.Count -gt 0) {
        Write-Host "  WARNINGS:"
        $warnings | ForEach-Object { Write-Host "    - $_" }
    }
} else {
    $result | ConvertTo-Json -Depth 10
}

$exitCode = switch ($status) {
    'active' { 0 }
    'stale'  { 0 }   # 진행 가능 (단 warn)
    'zombie' { 1 }
    'orphan' { 2 }
    default  { 0 }
}
exit $exitCode
