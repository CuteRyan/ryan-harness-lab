#Requires -Version 5.1
<#
.SYNOPSIS
    /feedback 스킬용 Claude Sub CLI 호출.

.DESCRIPTION
    Claude Code CLI를 읽기 전용 모드로 호출해 대상 파일을 리뷰.
    --allowed-tools "Read" 로 Grep/Glob 제거 (단일 파일 리뷰엔 불필요 + 탐색 경계 강화).
    --permission-mode plan 로 쓰기 차단.
    결과 JSON의 result 필드를 OutputFile에 Markdown으로 저장.

.PARAMETER IsolatedDir
    prepare-isolation.ps1 이 만든 격리 디렉토리 경로.

.PARAMETER Prompt
    Claude에 전달할 리뷰 프롬프트 (SKILL.md의 고정 템플릿).

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

$jsonOut = claude -p $Prompt `
    --permission-mode plan `
    --allowed-tools "Read" `
    --output-format json `
    --model sonnet `
    --no-session-persistence `
    --add-dir $IsolatedDir

if ($LASTEXITCODE -ne 0) {
    throw "claude CLI exited with code $LASTEXITCODE"
}

try {
    $parsed = $jsonOut | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Failed to parse claude JSON output: $($_.Exception.Message)"
}

if (-not $parsed.result) {
    throw "No 'result' field in claude JSON output"
}

Set-Content -LiteralPath $OutputFile -Value $parsed.result -Encoding UTF8
