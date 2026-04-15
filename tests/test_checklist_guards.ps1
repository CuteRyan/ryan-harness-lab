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
    [Parameter(Mandatory = $true)][string]$HookName,
    [Parameter(Mandatory = $true)][string]$FilePath
  )

  $HookPath = Join-Path $RepoRoot "hooks\$HookName"
  $Payload = @{ tool_input = @{ file_path = $FilePath } } | ConvertTo-Json -Compress
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $Output = $Payload | & $Bash $HookPath 2>&1
    $ExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }

  [pscustomobject]@{
    ExitCode = $ExitCode
    Output = ($Output -join "`n")
  }
}

function Assert-ExitCode {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$HookName,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][int]$Expected
  )

  $Result = Invoke-Hook -HookName $HookName -FilePath $FilePath
  if ($Result.ExitCode -ne $Expected) {
    throw @"
[$Name] expected exit code $Expected, got $($Result.ExitCode)
Hook: $HookName
File: $FilePath
Output:
$($Result.Output)
"@
  }

  Write-Host "PASS $Name"
}

$TempRoot = Join-Path $env:TEMP ("harness-hook-test-" + [Guid]::NewGuid().ToString("N"))

try {
  New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot ".git") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot "src") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot "docs") -Force | Out-Null

  $CodeFile = Join-Path $TempRoot "src\app.py"
  $DocFile = Join-Path $TempRoot "docs\guide.md"

  Write-Utf8File $CodeFile 'print("hello")'
  Write-Utf8File $DocFile "# Guide`n"

  Assert-ExitCode "dev guard ignores docs" "dev-checklist-guard.sh" $DocFile 0
  Assert-ExitCode "dev guard blocks missing checklist" "dev-checklist-guard.sh" $CodeFile 2

  Write-Utf8File (Join-Path $TempRoot ".dev-checklist.md") @"
status: approved

## Tasks
- [ ] Fix
"@
  Assert-ExitCode "dev guard blocks shallow checklist" "dev-checklist-guard.sh" $CodeFile 2

  Write-Utf8File (Join-Path $TempRoot ".dev-checklist.md") @"
status: approved

## Tasks
- [ ] Update the parser boundary behavior

## Changed Files
- [ ] src/app.py is listed as the edited file

## Verification
- [ ] Run the focused hook smoke tests

## Double Check
- [x] approved
"@
  Assert-ExitCode "dev guard accepts valid checklist" "dev-checklist-guard.sh" $CodeFile 0

  Assert-ExitCode "doc guard blocks missing checklist" "doc-checklist-guard.sh" $DocFile 1

  Write-Utf8File (Join-Path $TempRoot ".doc-checklist.md") @"
status: approved

## Scope
- [ ] Check
"@
  Assert-ExitCode "doc guard blocks shallow checklist" "doc-checklist-guard.sh" $DocFile 1

  Write-Utf8File (Join-Path $TempRoot ".doc-checklist.md") @"
status: approved

## Scope
- [ ] Update the usage wording

## Related Docs
- [ ] docs/index.md cross-link reviewed

## Cross Check
- [ ] Related workflow wording checked

## Double Check
- [x] approved
"@
  Assert-ExitCode "doc guard accepts valid checklist" "doc-checklist-guard.sh" $DocFile 0
} finally {
  if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force
  }
}
