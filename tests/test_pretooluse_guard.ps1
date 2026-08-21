Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$HookPath = Join-Path $RepoRoot "hooks\pretooluse-guard.ps1"
. $HookPath

function Assert-Decision {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][ValidateSet("allow", "warn", "block")][string]$Expected
  )

  $Decision = Get-HarnessGitDecision $Command
  if ($Decision.Action -ne $Expected) {
    throw "[$Name] expected $Expected, got $($Decision.Action): $Command"
  }
  Write-Host "PASS $Name"
}

$Cases = @(
  @{ Name = "normal status"; Command = "git status --short"; Expected = "allow" },
  @{ Name = "normal commit"; Command = "git commit -m 'checkpoint'"; Expected = "allow" },
  @{ Name = "normal push"; Command = "git push origin feature/light-hooks"; Expected = "allow" },
  @{ Name = "git text in argument"; Command = "echo git reset --hard"; Expected = "allow" },
  @{ Name = "quoted shell separator"; Command = "echo 'git reset --hard; still text'"; Expected = "allow" },
  @{ Name = "hard reset"; Command = "git reset --hard HEAD~1"; Expected = "block" },
  @{ Name = "uppercase hard reset"; Command = "GIT RESET --HARD HEAD~1"; Expected = "block" },
  @{ Name = "hard reset after chain"; Command = "echo ready && git reset --hard HEAD~1"; Expected = "block" },
  @{ Name = "hard reset with C option"; Command = "git -C . reset --hard HEAD~1"; Expected = "block" },
  @{ Name = "hard reset with config option"; Command = "git -c core.autocrlf=false reset --hard HEAD~1"; Expected = "block" },
  @{ Name = "quoted git executable"; Command = '"C:\Program Files\Git\bin\git.exe" reset --hard HEAD~1'; Expected = "block" },
  @{ Name = "clean with git-dir option"; Command = "git --git-dir=.git clean -fd"; Expected = "block" },
  @{ Name = "clean dry run"; Command = "git clean -nd"; Expected = "allow" },
  @{ Name = "restore worktree"; Command = "git restore app.py"; Expected = "block" },
  @{ Name = "restore staged only"; Command = "git restore --staged app.py"; Expected = "allow" },
  @{ Name = "checkout file"; Command = "git checkout -- app.py"; Expected = "block" },
  @{ Name = "normal checkout branch"; Command = "git checkout feature"; Expected = "allow" },
  @{ Name = "short force push"; Command = "git push -f origin main"; Expected = "block" },
  @{ Name = "bundled short force push"; Command = "git push -vf origin main"; Expected = "block" },
  @{ Name = "long force push"; Command = "git push --force origin main"; Expected = "block" },
  @{ Name = "force push with C option"; Command = "git -C . push -f origin main"; Expected = "block" },
  @{ Name = "attached separator after force"; Command = "git push -f; echo ready"; Expected = "block" },
  @{ Name = "forced refspec"; Command = "git push origin +main"; Expected = "block" },
  @{ Name = "force with lease warning"; Command = "git push --force-with-lease origin main"; Expected = "warn" },
  @{ Name = "document redirect outside policy"; Command = "echo replaced > docs/guide.md"; Expected = "allow" },
  @{ Name = "document copy outside policy"; Command = "cp docs/guide.md docs/guide-copy.md"; Expected = "allow" },
  @{ Name = "PowerShell file command outside policy"; Command = "Remove-Item -LiteralPath docs/guide.md"; Expected = "allow" },
  @{ Name = "deploy text outside policy"; Command = "echo scp 187.127.123.81"; Expected = "allow" }
)

foreach ($Case in $Cases) {
  Assert-Decision -Name $Case.Name -Command $Case.Command -Expected $Case.Expected
}

$Payload = @{
  tool_name = "Bash"
  tool_input = @{ command = "git -C . reset --hard HEAD~1" }
} | ConvertTo-Json -Compress -Depth 4

$PowerShell = (Get-Process -Id $PID).Path
$PreviousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $Output = $Payload | & $PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '$HookPath'" 2>&1
  $ExitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $PreviousErrorActionPreference
}

if ($ExitCode -ne 1) {
  throw "[stdin integration] expected exit code 1, got $ExitCode`n$($Output -join "`n")"
}
if (($Output -join "`n") -notlike "*Blocked destructive Git command*") {
  throw "[stdin integration] block message was not emitted"
}
Write-Host "PASS stdin integration"

foreach ($WhitespaceCommand in @(
  "echo one`n   `necho two",
  "echo one;   ;echo two"
)) {
  $WhitespacePayload = @{
    tool_name = "Bash"
    tool_input = @{ command = $WhitespaceCommand }
  } | ConvertTo-Json -Compress -Depth 4

  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $WhitespaceOutput = $WhitespacePayload | & $PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '$HookPath'" 2>&1
    $WhitespaceExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
  }

  if ($WhitespaceExitCode -ne 0) {
    throw "[whitespace integration] expected exit code 0, got $WhitespaceExitCode`n$($WhitespaceOutput -join "`n")"
  }
}
Write-Host "PASS whitespace-only shell segments"

foreach ($SettingsName in @("settings.json", "settings.template.json")) {
  $SettingsPath = Join-Path $RepoRoot "settings\$SettingsName"
  $Settings = Get-Content -Raw -Encoding UTF8 $SettingsPath | ConvertFrom-Json
  $PreToolUse = @($Settings.hooks.PreToolUse)
  if ($PreToolUse.Count -ne 1 -or $PreToolUse[0].matcher -ne "Bash") {
    throw "[$SettingsName] expected one Bash-only PreToolUse registration"
  }
  $Command = [string]$PreToolUse[0].hooks[0].command
  if ($Command -notlike "*pretooluse-guard.ps1*" -or
      $Command -match "run-hook|pre-bash-guards|doc-protection|deploy-version-guard") {
    throw "[$SettingsName] hook command is not lightweight: $Command"
  }
  Write-Host "PASS $SettingsName registration"
}
