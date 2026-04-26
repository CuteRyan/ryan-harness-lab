#Requires -Version 5.1
# /feedback orchestration entry point.
# 3 CLI (Claude Sub / Codex / Gemini) parallel invocation with timeout and retry.
# See SKILL.md for full documentation.

param(
    [Parameter(Mandatory = $true)]
    [string]$SourceFile,

    [string]$FeedbackDir,

    [int]$TimeoutSeconds = 300,

    # Step 7 retry 직전 cleanup 대기 (sec). Codex stdin 점유 / Gemini IDE client 리크 해소 목적.
    # V-3 (3회 연속) 실패 추적 결과 — Start-Job 종료 후 자식 CLI 핸들 정리에 시간이 필요.
    [int]$WaitSec = 10,

    # Start-Job 병렬 대신 순차 실행. stateful 누적 회피용 안전 모드.
    [switch]$Sequential
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# UTF-8 I/O 고정 — 부모 세션에도 적용 (Set-Content fallback 경로 + Step 7 retry 직접 호출 커버).
# 근거: docs/research/feedback-encoding-fix/02_web-evidence.md.
. (Join-Path $scriptDir '_encoding.ps1')
Write-Verbose ("Parent encoding: Console={0} Output={1}" -f [Console]::OutputEncoding.WebName, $OutputEncoding.WebName)

if (-not $FeedbackDir) {
    $FeedbackDir = Join-Path (Get-Location) 'docs\feedback'
}

# Step 1: prepare isolation directory
$prepareScript = Join-Path $scriptDir 'prepare-isolation.ps1'
$isolated = & $prepareScript -SourceFile $SourceFile
if (-not $isolated) {
    throw "prepare-isolation returned empty path"
}

# Step 2: ensure feedback output directory
if (-not (Test-Path -LiteralPath $FeedbackDir)) {
    New-Item -ItemType Directory -Path $FeedbackDir -Force | Out-Null
}

# Step 3: build fixed review prompt (keep in sync with SKILL.md)
$sourceFileName = Split-Path -Leaf $SourceFile
$isolatedFilePath = Join-Path $isolated $sourceFileName
$promptLines = @(
    "다음 파일을 리뷰해주세요: $isolatedFilePath",
    '',
    '요구 포맷 (엄격):',
    '- 각 지적의 첫 줄 맨 앞(줄 시작)에 대괄호 태그 [치명] [높음] [중간] [낮음] 중 하나를 반드시 부착.',
    '  (중요도별 섹션으로 묶어도 무방하나 섹션 제목이 아니라 각 지적 줄마다 태그 필수.',
    '   본문 설명·예시·코드블록 안에 [태그] 문자열을 인용 형태로 쓰지 말 것 — Validation Gate가 우회로 판정.)',
    '- 각 지적에 파일:줄 + 근거 1개 (실측 출력 / 공식 문서 URL / 파일 내용 인용 중 하나).',
    '- 장점 나열·rubber-stamp 금지. 문제 없는 항목은 "[낮음] 없음 - 근거: X" 한 줄로만.',
    '- 접근 실패/맥락 부족은 추측 말고 "[확인 불가] 사유: X" 로 명시.',
    '- 마지막에 Top 3 반영 우선순위 (각 항목도 [태그] 접두사 필수).',
    '',
    '대상 파일만 읽고 폴더 재귀 탐색 금지.'
)
$prompt = $promptLines -join "`n"

# Step 4: output file paths
$slug = Split-Path -Leaf $isolated
$date = Get-Date -Format 'yyyy-MM-dd'

$cliNames = @('claude-sub', 'codex', 'gemini')

$outputs = @{}
$outputs['claude-sub'] = Join-Path $FeedbackDir ($date + '_claude-sub_' + $slug + '.md')
$outputs['codex']      = Join-Path $FeedbackDir ($date + '_codex_' + $slug + '.md')
$outputs['gemini']     = Join-Path $FeedbackDir ($date + '_gemini_' + $slug + '.md')

$cliScripts = @{}
$cliScripts['claude-sub'] = Join-Path $scriptDir 'run-claude-sub.ps1'
$cliScripts['codex']      = Join-Path $scriptDir 'run-codex.ps1'
$cliScripts['gemini']     = Join-Path $scriptDir 'run-gemini.ps1'

# Step 5/6/7: 병렬(Start-Job) 또는 순차(-Sequential) 실행 + retry
# Start-Job ScriptBlock은 별도 runspace — 부모 인코딩 설정 상속 X (PS #4681, #14945).
# 자식 진입 즉시 _encoding.ps1을 dot-source해야 CLI stdout 디코딩이 UTF-8로 고정됨.

# 병렬 결과를 (needRetry, failReason) 형태로 모아둘 해시. 순차 모드에서는 그대로 비워둠.
$jobResults = @{}

if (-not $Sequential) {
    # Step 5 (병렬): Start-Job 으로 3개 동시 spawn.
    $jobs = @{}
    foreach ($cli in $cliNames) {
        $jobs[$cli] = Start-Job -Name $cli -ScriptBlock {
            param($ScriptPath, $Isolated, $P, $Out, $ScriptsDir)
            . (Join-Path $ScriptsDir '_encoding.ps1')
            & $ScriptPath -IsolatedDir $Isolated -Prompt $P -OutputFile $Out
        } -ArgumentList $cliScripts[$cli], $isolated, $prompt, $outputs[$cli], $scriptDir
    }

    # Step 6: wait with configurable timeout (default 300s)
    $null = $jobs.Values | Wait-Job -Timeout $TimeoutSeconds

    # 1차 수집: 각 job 의 성공/실패만 판정하고 정리. retry 는 cleanup 대기 후 일괄.
    foreach ($cli in $cliNames) {
        $job = $jobs[$cli]
        $out = $outputs[$cli]

        $needRetry = $false
        $failReason = ""

        if ($job.State -ne 'Completed') {
            $needRetry = $true
            $failReason = "async job state: " + $job.State + " (likely timeout)"
            Stop-Job $job -ErrorAction SilentlyContinue
        }
        else {
            try {
                Receive-Job $job -ErrorAction Stop | Out-Null
                if (-not (Test-Path -LiteralPath $out -PathType Leaf)) {
                    $needRetry = $true
                    $failReason = "output file not created"
                }
            }
            catch {
                $needRetry = $true
                $failReason = "async error: " + $_.Exception.Message
            }
        }
        Remove-Job $job -Force -ErrorAction SilentlyContinue

        $jobResults[$cli] = @{ needRetry = $needRetry; failReason = $failReason }
    }
}
else {
    # 순차 모드: Start-Job 우회. 각 CLI 를 직렬로 호출하고 실패 시 retry 표시.
    foreach ($cli in $cliNames) {
        $cliScript = $cliScripts[$cli]
        $out = $outputs[$cli]

        $needRetry = $false
        $failReason = ""
        try {
            & $cliScript -IsolatedDir $isolated -Prompt $prompt -OutputFile $out
            if (-not (Test-Path -LiteralPath $out -PathType Leaf)) {
                $needRetry = $true
                $failReason = "output file not created"
            }
        }
        catch {
            $needRetry = $true
            $failReason = "sequential error: " + $_.Exception.Message
        }

        $jobResults[$cli] = @{ needRetry = $needRetry; failReason = $failReason }
    }
}

# Step 7: retry — 실패한 CLI 가 있을 때만 cleanup 대기 후 동기 재호출.
$anyRetry = $false
foreach ($cli in $cliNames) {
    if ($jobResults[$cli].needRetry) { $anyRetry = $true; break }
}

if ($anyRetry -and $WaitSec -gt 0) {
    # Codex stdin 점유 / Gemini IDE client 핸들 정리 시간 부여.
    # 근거: V-3 (3회 연속) 실패 추적 — Start-Job 종료 직후 즉시 동기 호출하면
    # 이전 자식 CLI 의 파이프 핸들이 살아있어 "Reading additional input from stdin..." /
    # "[ERROR] [IDEClient] Failed to connect to IDE companion extension" 발생.
    Write-Verbose ("Retry cleanup wait: {0}s" -f $WaitSec)
    Start-Sleep -Seconds $WaitSec
}

foreach ($cli in $cliNames) {
    if (-not $jobResults[$cli].needRetry) { continue }

    $cliScript = $cliScripts[$cli]
    $out = $outputs[$cli]
    $failReason = $jobResults[$cli].failReason

    $retrySuccess = $false
    try {
        & $cliScript -IsolatedDir $isolated -Prompt $prompt -OutputFile $out
        if (Test-Path -LiteralPath $out -PathType Leaf) {
            $retrySuccess = $true
        }
    }
    catch {
        $failReason += " | retry also failed: " + $_.Exception.Message
    }

    if (-not $retrySuccess) {
        $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $msgLines = @(
            ('# ' + $cli + ' 실행 실패'),
            '',
            ('**사유**: ' + $failReason),
            '',
            ('**격리 디렉토리**: ' + $isolated),
            ('**대상 파일**: ' + $sourceFileName),
            ('**시각**: ' + $now)
        )
        Set-Content -LiteralPath $out -Value ($msgLines -join "`n") -Encoding UTF8
    }
}

# Step 8: return JSON with paths
$result = @{}
$result['claude_sub']   = $outputs['claude-sub']
$result['codex']        = $outputs['codex']
$result['gemini']       = $outputs['gemini']
$result['slug']         = $slug
$result['isolated_dir'] = $isolated
$result['source_file']  = $SourceFile
$result | ConvertTo-Json -Compress
