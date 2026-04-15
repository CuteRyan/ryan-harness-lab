Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoRoot = Split-Path -Parent $PSScriptRoot
$BashCandidates = @(
  "C:\Program Files\Git\bin\bash.exe",
  "bash"
)

$Bash = $null
foreach ($Candidate in $BashCandidates) {
  if ($Candidate -eq "bash") {
    $Command = Get-Command bash -ErrorAction SilentlyContinue
    if ($Command) {
      $Bash = $Command.Source
      break
    }
  } elseif (Test-Path -LiteralPath $Candidate) {
    $Bash = $Candidate
    break
  }
}

if (-not $Bash) {
  throw "Git Bash was not found. Install Git for Windows or add bash to PATH."
}

function Write-Utf8File {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )

  $Directory = Split-Path -Parent $Path
  if ($Directory -and -not (Test-Path -LiteralPath $Directory)) {
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
  }

  $Encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function Invoke-Hook {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Payload
  )

  $HookPath = Join-Path $RepoRoot "hooks\doc-protection.sh"
  $Json = $Payload | ConvertTo-Json -Compress -Depth 5
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $Output = $Json | & $Bash $HookPath 2>&1
    $ExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }

  [pscustomobject]@{
    ExitCode = $ExitCode
    Output = ($Output -join "`n")
  }
}

function Assert-Hook {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][hashtable]$Payload,
    [Parameter(Mandatory = $true)][int]$ExpectedExitCode,
    [string]$ExpectedOutput
  )

  $Result = Invoke-Hook -Payload $Payload
  if ($Result.ExitCode -ne $ExpectedExitCode) {
    throw @"
[$Name] expected exit code $ExpectedExitCode, got $($Result.ExitCode)
Output:
$($Result.Output)
"@
  }
  if ($ExpectedOutput -and $Result.Output -notlike "*$ExpectedOutput*") {
    throw @"
[$Name] expected output containing: $ExpectedOutput
Actual output:
$($Result.Output)
"@
  }

  Write-Host "PASS $Name"
}

$TempRoot = Join-Path $env:TEMP ("harness-doc-protection-test-" + [Guid]::NewGuid().ToString("N"))

try {
  New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot "docs") -Force | Out-Null

  $ExistingDoc = Join-Path $TempRoot "docs\guide.md"
  $NewDoc = Join-Path $TempRoot "docs\new.md"
  $CodeFile = Join-Path $TempRoot "app.py"
  $BackupDoc = Join-Path $TempRoot ".backups\guide.md"
  Write-Utf8File $ExistingDoc "# Guide`n"
  Write-Utf8File $CodeFile "print('ok')`n"

  Assert-Hook "write existing doc is blocked" @{
    tool_name = "Write"
    tool_input = @{ file_path = $ExistingDoc; content = "# Replaced`n" }
  } 1 "Write"

  Assert-Hook "write new doc is allowed" @{
    tool_name = "Write"
    tool_input = @{ file_path = $NewDoc; content = "# New`n" }
  } 0

  Assert-Hook "write existing code is allowed" @{
    tool_name = "Write"
    tool_input = @{ file_path = $CodeFile; content = "print('changed')`n" }
  } 0

  Assert-Hook "bash sed in-place doc is blocked" @{
    tool_name = "Bash"
    tool_input = @{ command = "sed -i 's/a/b/' `"$ExistingDoc`"" }
  } 1 "sed"

  Assert-Hook "bash redirect doc is blocked" @{
    tool_name = "Bash"
    tool_input = @{ command = "echo hello > `"$ExistingDoc`"" }
  } 1 "redirect"

  Assert-Hook "bash tee doc is blocked" @{
    tool_name = "Bash"
    tool_input = @{ command = "printf hello | tee `"$ExistingDoc`"" }
  } 1 "tee"

  Assert-Hook "bash python open doc is blocked" @{
    tool_name = "Bash"
    tool_input = @{ command = "python -c `"open('$ExistingDoc','w').write('x')`"" }
  } 1 "script"

  Assert-Hook "bash powershell set-content doc is blocked" @{
    tool_name = "Bash"
    tool_input = @{ command = "powershell -Command `"Set-Content -Path '$ExistingDoc' -Value x`"" }
  } 1 "PowerShell"

  Assert-Hook "bash git command is allowed" @{
    tool_name = "Bash"
    tool_input = @{ command = "git status --short" }
  } 0

  Assert-Hook "bash backup command is allowed" @{
    tool_name = "Bash"
    tool_input = @{ command = ('cp "' + $ExistingDoc + '" "' + $BackupDoc + '"') }
  } 0
} finally {
  if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force
  }
}
