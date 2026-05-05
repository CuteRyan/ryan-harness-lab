<#
.NAME
    shutdown-team.ps1 — 좀비 정리 + orphan team dir 청소 (Phase 8)

.WHY
    feedback 의 `.dev-checklist.md` 삭제 금지 원칙 차용 (R-5):
    기본 = `.archived_<timestamp>/` 로 이동 (보존), `-Force` 옵션 = 즉시 삭제 (사용자 명시 시만).

.INPUTS
    -Team <name>     : 팀 이름 (필수)
    -Force           : 즉시 삭제 (R-5 위반 경고 출력 + 사용자 컨펌 우회)
    -DryRun          : 실제 이동/삭제 없이 계획만 출력

.OUTPUTS
    JSON stdout: {
      "ok": true|false,
      "team": "...",
      "action": "archive" | "delete" | "dry-run",
      "archive_path": "...",
      "shutdown_signal": "...",
      "warnings": [...]
    }

.EXIT CODES
    0 = OK
    1 = 팀 디렉토리 부재
    2 = 이동/삭제 실패

.SOURCE
    - v2 spec `04_redesign-spec.md §3.1 Phase 8` (스펙 명세 차용)
    - feedback `.dev-checklist.md` 삭제 금지 원칙 (R-5 정합)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Team,

    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$tasksRoot = Join-Path $HOME '.claude\tasks'
$teamsRoot = Join-Path $HOME '.claude\teams'
$teamMetaDir = Join-Path $teamsRoot $Team
$teamTaskDir = Join-Path $tasksRoot $Team

$warnings = @()

if (-not (Test-Path $teamMetaDir) -and -not (Test-Path $teamTaskDir)) {
    @{
        ok       = $false
        team     = $Team
        error    = '팀 디렉토리 부재 (이미 정리됨 또는 잘못된 이름)'
        searched = @($teamMetaDir, $teamTaskDir)
    } | ConvertTo-Json -Depth 5
    exit 1
}

# Step 1: shutdown signal 생성 (각 teammate 가 SendMessage poll 시 감지)
$shutdownSignal = Join-Path $teamTaskDir '.shutdown_signal'
if ((Test-Path $teamTaskDir) -and -not $DryRun) {
    try {
        @{
            signal     = 'shutdown'
            requested_at = (Get-Date -Format 'o')
            requested_by = 'shutdown-team.ps1'
        } | ConvertTo-Json | Set-Content -LiteralPath $shutdownSignal -Encoding UTF8
    } catch {
        $warnings += "shutdown_signal write failed: $($_.Exception.Message)"
    }
}

# Step 2: archive 또는 delete
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archiveBase = Join-Path $teamsRoot ".archived"
$archivePath = Join-Path $archiveBase "$Team-$timestamp"

$action = 'archive'
if ($Force) {
    $action = 'delete'
    $warnings += 'R-5 위반 경고: -Force 옵션으로 즉시 삭제 (사용자 명시 컨펌 가정)'
}
if ($DryRun) {
    $action = 'dry-run'
}

$movedPaths = @()

if ($DryRun) {
    if (Test-Path $teamMetaDir) { $movedPaths += "[dry-run] $teamMetaDir → $archivePath\teams" }
    if (Test-Path $teamTaskDir) { $movedPaths += "[dry-run] $teamTaskDir → $archivePath\tasks" }
} elseif ($Force) {
    try {
        if (Test-Path $teamMetaDir) {
            Remove-Item -LiteralPath $teamMetaDir -Recurse -Force
            $movedPaths += "DELETED: $teamMetaDir"
        }
        if (Test-Path $teamTaskDir) {
            Remove-Item -LiteralPath $teamTaskDir -Recurse -Force
            $movedPaths += "DELETED: $teamTaskDir"
        }
    } catch {
        @{
            ok    = $false
            error = "delete failed: $($_.Exception.Message)"
            warnings = $warnings
        } | ConvertTo-Json -Depth 5
        exit 2
    }
} else {
    # archive (기본)
    try {
        if (-not (Test-Path $archiveBase)) {
            New-Item -ItemType Directory -Path $archiveBase -Force | Out-Null
        }
        if (-not (Test-Path $archivePath)) {
            New-Item -ItemType Directory -Path $archivePath -Force | Out-Null
        }
        if (Test-Path $teamMetaDir) {
            $dest = Join-Path $archivePath 'teams'
            Move-Item -LiteralPath $teamMetaDir -Destination $dest -Force
            $movedPaths += "ARCHIVED: $teamMetaDir → $dest"
        }
        if (Test-Path $teamTaskDir) {
            $dest = Join-Path $archivePath 'tasks'
            Move-Item -LiteralPath $teamTaskDir -Destination $dest -Force
            $movedPaths += "ARCHIVED: $teamTaskDir → $dest"
        }
    } catch {
        @{
            ok    = $false
            error = "archive failed: $($_.Exception.Message)"
            warnings = $warnings
        } | ConvertTo-Json -Depth 5
        exit 2
    }
}

@{
    ok              = $true
    team            = $Team
    action          = $action
    archive_path    = $(if ($action -eq 'archive') { $archivePath } else { $null })
    shutdown_signal = $(if ((Test-Path $shutdownSignal) -or $DryRun) { $shutdownSignal } else { $null })
    moved           = $movedPaths
    warnings        = $warnings
    timestamp       = (Get-Date -Format 'o')
} | ConvertTo-Json -Depth 5

exit 0
