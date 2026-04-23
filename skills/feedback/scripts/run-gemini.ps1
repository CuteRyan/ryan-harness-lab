#Requires -Version 5.1
<#
.SYNOPSIS
    /feedback 스킬용 Gemini CLI 호출.

.DESCRIPTION
    Gemini CLI는 --include-directories로 workspace 확장이 불안정 (2026-04-21 실측:
    격리 경로 거부 후 프로젝트 구버전으로 폴백). CWD 전환이 유일한 안정 격리 방법.

    Push-Location/Pop-Location 필수 — 단순 cd 사용 시 세션 CWD가 격리 디렉토리로
    고정되어 이후 저장 경로 오염 (2026-04-21 3차 dogfood 공통 지적).

    --approval-mode plan: 쓰기 차단.
    -o text: plain text 출력.

.PARAMETER IsolatedDir
    prepare-isolation.ps1 이 만든 격리 디렉토리 경로.

.PARAMETER Prompt
    Gemini에 전달할 리뷰 프롬프트.

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

Push-Location -LiteralPath $IsolatedDir
try {
    $output = gemini.cmd -p $Prompt -o text --approval-mode plan

    if ($LASTEXITCODE -ne 0) {
        throw "gemini CLI exited with code $LASTEXITCODE"
    }

    if ([string]::IsNullOrWhiteSpace($output)) {
        throw "gemini returned empty output"
    }

    Set-Content -LiteralPath $OutputFile -Value $output -Encoding UTF8
}
finally {
    Pop-Location
}
