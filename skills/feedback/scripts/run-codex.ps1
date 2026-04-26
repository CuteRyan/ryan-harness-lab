#Requires -Version 5.1
<#
.SYNOPSIS
    /feedback 스킬용 Codex CLI 호출.

.DESCRIPTION
    Codex CLI를 격리 디렉토리를 CWD로 잡고 호출.
    $null | 패턴은 stdin 제공 (bash/PowerShell 호환).
    --skip-git-repo-check: git 초기화 없는 격리 디렉토리에서도 실행 허용.
    --output-schema 사용 금지 (early return 방지 — 2026-04-21 실측).
    stdout 원문 Markdown을 OutputFile에 저장.

.PARAMETER IsolatedDir
    prepare-isolation.ps1 이 만든 격리 디렉토리 경로.

.PARAMETER Prompt
    Codex에 전달할 리뷰 프롬프트.

.PARAMETER OutputFile
    결과 md 파일 저장 경로 (절대경로).
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$IsolatedDir,

    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$ErrorActionPreference = 'Stop'

# UTF-8 I/O 고정 — PS 5.1 CP949 기본값 우회 (L1 stdout + L2 argv/pipe + 파일 저장).
# 근거: docs/research/feedback-encoding-fix/02_web-evidence.md (hy2k.dev, MS Learn).
. (Join-Path $PSScriptRoot '_encoding.ps1')

# 지수 백오프 retry (1→2→4s, 최대 3회) — Codex stdin 점유로 인한 일시적 실패 회복용.
# 영구 실패(인증 등)는 3회 모두 같은 에러로 끝나므로 추가 비용은 최대 7s.
$maxAttempts = 3
$delays = @(1, 2, 4)
$lastError = $null
$output = $null

for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    try {
        $output = $null | codex.cmd exec --skip-git-repo-check -C $IsolatedDir $Prompt

        if ($LASTEXITCODE -ne 0) {
            throw "codex CLI exited with code $LASTEXITCODE"
        }
        if ([string]::IsNullOrWhiteSpace($output)) {
            throw "codex returned empty output"
        }

        $lastError = $null
        break
    }
    catch {
        $lastError = $_
        if ($attempt -lt $maxAttempts) {
            $sleep = $delays[$attempt - 1]
            Write-Verbose ("codex attempt {0}/{1} failed: {2} — retry in {3}s" -f $attempt, $maxAttempts, $_.Exception.Message, $sleep)
            Start-Sleep -Seconds $sleep
        }
    }
}

if ($lastError) {
    throw $lastError
}

Set-Content -LiteralPath $OutputFile -Value $output -Encoding UTF8
