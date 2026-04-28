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

# BOM 삽입 복사 (Day 10 Part 3 V-1 내부 관찰 → L4 회복 단계 skip)
# Codex 내부 spawn PowerShell 이 격리본을 Get-Content 기본 CP949 로 읽어도
# BOM 이 있으면 UTF-8 로 즉시 인식 → mojibake → 재시도 1단계 절약 + stdout 진단성 향상.
# 근거: docs/research/feedback-encoding-fix/03_fix-plan.md L4
$dst = Join-Path $isolated $sourceItem.Name
$content = Get-Content -LiteralPath $SourceFile -Raw -Encoding UTF8
[System.IO.File]::WriteAllText($dst, $content, [System.Text.UTF8Encoding]::new($true))

# B 방식 (2026-04-28~): prompts/review.md 를 격리 디렉토리에 같이 복사.
# CLI 가 자기 read 도구로 review.md 를 직접 읽어 그 안의 형식·규칙을 따름.
# orchestrate.ps1 은 "이 폴더의 review.md 읽고 따라줘" 라는 짧은 메타 prompt 만 전달.
# Why: PowerShell argv 로 긴 한글 prompt 전달 시 인코딩 위험 + 코드/프롬프트 분리.
$promptSrc = Join-Path (Split-Path -Parent $PSScriptRoot) 'prompts\review.md'
if (-not (Test-Path -LiteralPath $promptSrc -PathType Leaf)) {
    throw "Prompt SSOT file not found: $promptSrc"
}
$promptDst = Join-Path $isolated 'review.md'
$promptContent = Get-Content -LiteralPath $promptSrc -Raw -Encoding UTF8
[System.IO.File]::WriteAllText($promptDst, $promptContent, [System.Text.UTF8Encoding]::new($true))

Write-Output $isolated
