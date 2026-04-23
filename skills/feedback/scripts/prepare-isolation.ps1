#Requires -Version 5.1
<#
.SYNOPSIS
    /feedback 스킬용 격리 디렉토리 준비.

.DESCRIPTION
    대상 파일을 $HOME\codex-cwd\<slug> 에 복사하고 격리 디렉토리 경로를 반환.
    Codex CLI의 한글 경로 CP949 문제 + 재귀 스캔 폭주를 차단하는 표준 패턴.

.PARAMETER SourceFile
    리뷰 대상 파일의 절대경로.

.OUTPUTS
    격리 디렉토리 절대경로 (stdout 1줄).

.EXAMPLE
    .\prepare-isolation.ps1 -SourceFile "C:\project\docs\sample.md"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceFile
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {
    throw "Source file not found: $SourceFile"
}

$sourceItem = Get-Item -LiteralPath $SourceFile
$slug = "$($sourceItem.BaseName)_$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$isolated = Join-Path -Path (Join-Path $HOME 'codex-cwd') -ChildPath $slug

if (Test-Path -LiteralPath $isolated) {
    throw "Isolated directory already exists (slug collision): $isolated"
}

New-Item -ItemType Directory -Path $isolated | Out-Null
Copy-Item -LiteralPath $SourceFile -Destination $isolated

Write-Output $isolated
