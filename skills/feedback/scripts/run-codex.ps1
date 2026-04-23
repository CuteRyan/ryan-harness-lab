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

$output = $null | codex.cmd exec --skip-git-repo-check -C $IsolatedDir $Prompt

if ($LASTEXITCODE -ne 0) {
    throw "codex CLI exited with code $LASTEXITCODE"
}

if ([string]::IsNullOrWhiteSpace($output)) {
    throw "codex returned empty output"
}

Set-Content -LiteralPath $OutputFile -Value $output -Encoding UTF8
