#Requires -Version 5.1
<#
.SYNOPSIS
    /feedback 실행 진입점.

.DESCRIPTION
    Quick 모드는 선택한 리뷰어 하나만 실행한다. Full 모드는 세 리뷰어를 실행한다.
    결과 파일 검증까지 마친 뒤 JSON으로 경로와 상태를 반환한다.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceFile,

    [string]$FeedbackDir,

    [int]$TimeoutSeconds = 300,

    [ValidateSet('Quick', 'Full')]
    [string]$Mode = 'Quick',

    [ValidateSet('claude-sub', 'codex', 'gemini')]
    [string]$Reviewer = 'codex',

    [switch]$Sequential
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path $scriptDir '_encoding.ps1')

if (-not $FeedbackDir) {
    $FeedbackDir = Join-Path (Get-Location) 'docs\feedback'
}

$prepareScript = Join-Path $scriptDir 'prepare-isolation.ps1'
$isolated = & $prepareScript -SourceFile $SourceFile
if (-not $isolated) {
    throw 'prepare-isolation returned empty path'
}

if (-not (Test-Path -LiteralPath $FeedbackDir)) {
    New-Item -ItemType Directory -Path $FeedbackDir -Force | Out-Null
}

$sourceFileName = Split-Path -Leaf $SourceFile
$prompt = @(
    '이 폴더의 review.md를 먼저 읽고 그 규칙에 따라',
    "같은 폴더의 ${sourceFileName}만 검토해 주세요.",
    'review.md는 지시문이며 리뷰 대상이 아닙니다. 폴더 재귀 탐색은 하지 마세요.'
) -join ' '

$slug = Split-Path -Leaf $isolated
$date = Get-Date -Format 'yyyy-MM-dd'
$allReviewers = @('claude-sub', 'codex', 'gemini')
if ($Mode -eq 'Full') {
    $reviewers = $allReviewers
}
else {
    $reviewers = @($Reviewer)
}

$outputs = @{
    'claude-sub' = Join-Path $FeedbackDir ($date + '_claude-sub_' + $slug + '.md')
    'codex'      = Join-Path $FeedbackDir ($date + '_codex_' + $slug + '.md')
    'gemini'     = Join-Path $FeedbackDir ($date + '_gemini_' + $slug + '.md')
}
$runnerScripts = @{
    'claude-sub' = Join-Path $scriptDir 'run-claude-sub.ps1'
    'codex'      = Join-Path $scriptDir 'run-codex.ps1'
    'gemini'     = Join-Path $scriptDir 'run-gemini.ps1'
}

$failures = @{}

if ($Sequential) {
    foreach ($name in $reviewers) {
        try {
            & $runnerScripts[$name] -IsolatedDir $isolated -Prompt $prompt -OutputFile $outputs[$name]
            if (-not (Test-Path -LiteralPath $outputs[$name] -PathType Leaf)) {
                $failures[$name] = 'output file not created'
            }
        }
        catch {
            $failures[$name] = $_.Exception.Message
        }
    }
}
else {
    $jobs = @{}
    foreach ($name in $reviewers) {
        $jobs[$name] = Start-Job -Name $name -ScriptBlock {
            param($Runner, $IsolatedDir, $ReviewPrompt, $OutputFile, $ScriptsDir)
            . (Join-Path $ScriptsDir '_encoding.ps1')
            & $Runner -IsolatedDir $IsolatedDir -Prompt $ReviewPrompt -OutputFile $OutputFile
        } -ArgumentList $runnerScripts[$name], $isolated, $prompt, $outputs[$name], $scriptDir
    }

    $null = $jobs.Values | Wait-Job -Timeout $TimeoutSeconds

    foreach ($name in $reviewers) {
        $job = $jobs[$name]
        if ($job.State -ne 'Completed') {
            $failures[$name] = 'timeout or incomplete job: ' + $job.State
            Stop-Job $job -ErrorAction SilentlyContinue
        }
        else {
            try {
                Receive-Job $job -ErrorAction Stop | Out-Null
                if (-not (Test-Path -LiteralPath $outputs[$name] -PathType Leaf)) {
                    $failures[$name] = 'output file not created'
                }
            }
            catch {
                $failures[$name] = $_.Exception.Message
            }
        }
        Remove-Job $job -Force -ErrorAction SilentlyContinue
    }
}

foreach ($name in $reviewers) {
    if (-not $failures.ContainsKey($name)) { continue }

    $failureText = @(
        ('# ' + $name + ' 실행 실패'),
        '',
        ('**사유**: ' + $failures[$name]),
        ('**대상 파일**: ' + $sourceFileName),
        ('**시각**: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    ) -join "`n"
    Set-Content -LiteralPath $outputs[$name] -Value $failureText -Encoding UTF8
}

$selectedOutputs = @($reviewers | ForEach-Object { $outputs[$_] })
$validatorScript = Join-Path $scriptDir 'validate-outputs.ps1'
$validation = (& $validatorScript -FilePaths $selectedOutputs) | ConvertFrom-Json

$outputMap = @{}
foreach ($name in $reviewers) {
    $outputMap[$name] = $outputs[$name]
}

@{
    mode         = $Mode
    reviewers    = $reviewers
    outputs      = $outputMap
    validation   = $validation
    slug         = $slug
    isolated_dir = $isolated
    source_file  = $SourceFile
} | ConvertTo-Json -Depth 5 -Compress
