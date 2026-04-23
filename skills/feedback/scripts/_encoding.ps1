#Requires -Version 5.1
<#
.SYNOPSIS
    /feedback 스킬용 PowerShell UTF-8 I/O 인코딩 고정 헬퍼.

.DESCRIPTION
    Dot-source 전용 (`. (Join-Path $PSScriptRoot '_encoding.ps1')`).
    호출 스크립트의 스코프에 UTF-8 설정을 직접 적용.

    3 레이어 방어:
      L1. [Console]::OutputEncoding — CLI stdout 바이트 → PS string 디코딩
      L2. $OutputEncoding           — PS string → CLI 파이프 바이트
      +   $PSDefaultParameterValues — Set-Content/Out-File/Add-Content 기본 인코딩

    PS 5.1은 한국어 Windows에서 기본 CP949로 해석 → UTF-8 CLI 출력이 mojibake.
    Start-Job 자식 runspace는 부모 설정을 상속하지 않으므로 각 진입점에서 호출 필수.

    근거: docs/research/feedback-encoding-fix/02_web-evidence.md
          (hy2k.dev 2025-11, MS Learn CJK troubleshooting, PowerShell #4681/#14945)
#>

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$OutputEncoding = [System.Text.Encoding]::UTF8

$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-File:Encoding']    = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
