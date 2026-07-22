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
    [Parameter(Mandatory = $true)][hashtable]$Payload,
    [string]$HookName = "doc-protection.sh"
  )

  $HookPath = Join-Path $RepoRoot "hooks\$HookName"
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
    [string]$ExpectedOutput,
    [string]$HookName = "doc-protection.sh"
  )

  $Result = Invoke-Hook -Payload $Payload -HookName $HookName
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
  $CombinedGuardSource = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot "hooks\pre-bash-guards.sh")
  if ($CombinedGuardSource -match 'run_guard\s+pre-commit-guard\.sh') {
    throw "combined hook still invokes the global pre-commit guard"
  }
  Write-Host "PASS combined hook does not invoke global pre-commit checks"

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

  if (Test-Path -LiteralPath (Join-Path $TempRoot "docs\.backups")) {
    throw "blocked Write created an unnecessary backup"
  }

  Assert-Hook "edit existing doc is allowed without backup" @{
    tool_name = "Edit"
    tool_input = @{ file_path = $ExistingDoc; old_string = "Guide"; new_string = "Updated" }
  } 0

  if (Test-Path -LiteralPath (Join-Path $TempRoot "docs\.backups")) {
    throw "Edit created an unnecessary backup"
  }

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
  } 1

  Assert-Hook "bash powershell set-content doc is blocked" @{
    tool_name = "Bash"
    tool_input = @{ command = "powershell -Command `"Set-Content -Path '$ExistingDoc' -Value x`"" }
  } 1 "PowerShell"

  Assert-Hook "bash git command is allowed" @{
    tool_name = "Bash"
    tool_input = @{ command = "git status --short" }
  } 0

  Assert-Hook "bash normal git push is allowed" @{
    tool_name = "Bash"
    tool_input = @{ command = "git push origin feature/light-hooks" }
  } 0

  Assert-Hook "bash hard reset is blocked" @{
    tool_name = "Bash"
    tool_input = @{ command = "git reset --hard HEAD~1" }
  } 1 "Git"

  Assert-Hook "bash backup command is allowed" @{
    tool_name = "Bash"
    tool_input = @{ command = ('cp "' + $ExistingDoc + '" "' + $BackupDoc + '"') }
  } 0

  Assert-Hook "bash backup source cannot overwrite doc with cp" @{
    tool_name = "Bash"
    tool_input = @{ command = ('cp "' + $BackupDoc + '" "' + $ExistingDoc + '"') }
  } 1 "mv/cp"

  Assert-Hook "bash backup source cannot overwrite doc with mv" @{
    tool_name = "Bash"
    tool_input = @{ command = ('mv "' + $BackupDoc + '" "' + $ExistingDoc + '"') }
  } 1 "mv/cp"

  Assert-Hook "combined hook allows normal push" @{
    tool_name = "Bash"
    tool_input = @{ command = "git push origin feature/light-hooks" }
  } 0 -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook allows git commit without global tests" @{
    tool_name = "Bash"
    tool_input = @{ command = "git commit -m 'local checkpoint'" }
  } 0 -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks short force push" @{
    tool_name = "Bash"
    tool_input = @{ command = "git push -f origin main" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks force-with-lease" @{
    tool_name = "Bash"
    tool_input = @{ command = "git push --force-with-lease origin main" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks chained short force push" @{
    tool_name = "Bash"
    tool_input = @{ command = "echo ready && git push -f origin main" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks attached separator after short force" @{
    tool_name = "Bash"
    tool_input = @{ command = "git push -f;echo ready" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks uppercase force push" @{
    tool_name = "Bash"
    tool_input = @{ command = "GIT PUSH -f origin main" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks force push with git C option" @{
    tool_name = "Bash"
    tool_input = @{ command = "git -C . push -f origin main" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks forced refspec" @{
    tool_name = "Bash"
    tool_input = @{ command = "git push origin +main" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks bundled short force option" @{
    tool_name = "Bash"
    tool_input = @{ command = "git push -vf origin main" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks hard reset" @{
    tool_name = "Bash"
    tool_input = @{ command = "git reset --hard HEAD~1" }
  } 1 "Git" -HookName "pre-bash-guards.sh"

  Assert-Hook "combined hook blocks document redirect" @{
    tool_name = "Bash"
    tool_input = @{ command = "echo replaced > docs/guide.md" }
  } 1 "redirect" -HookName "pre-bash-guards.sh"
} finally {
  if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force
  }
}
