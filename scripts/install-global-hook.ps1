param(
  [string]$ClaudeRoot = (Join-Path $env:USERPROFILE ".claude"),
  [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SourceHook = Join-Path $RepoRoot "hooks\pretooluse-guard.ps1"
$TemplatePath = Join-Path $RepoRoot "settings\settings.template.json"
$ClaudeRoot = [System.IO.Path]::GetFullPath($ClaudeRoot)
$HooksRoot = Join-Path $ClaudeRoot "hooks"
$RuntimeSettingsPath = Join-Path $ClaudeRoot "settings.json"
$LegacyHookNames = @(
  "_harness_common.sh",
  "deploy-version-guard.sh",
  "doc-protection.sh",
  "pre-bash-guards.sh",
  "run-hook.ps1"
)
$ManagedHookNames = @($LegacyHookNames) + @("pretooluse-guard.ps1")
$ManagedCommandPattern = "pretooluse-guard|run-hook|pre-bash-guards|doc-protection|deploy-version-guard"

if ((Split-Path -Leaf $ClaudeRoot) -ne ".claude") {
  throw "Refusing non-.claude target: $ClaudeRoot"
}
if (-not (Test-Path -LiteralPath $SourceHook -PathType Leaf)) {
  throw "Source hook not found: $SourceHook"
}
if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) {
  throw "Settings template not found: $TemplatePath"
}
if (-not (Test-Path -LiteralPath $RuntimeSettingsPath -PathType Leaf)) {
  throw "Runtime settings not found: $RuntimeSettingsPath"
}
if (-not (Test-Path -LiteralPath $HooksRoot -PathType Container)) {
  throw "Runtime hooks directory not found: $HooksRoot"
}

$RuntimeSettings = Get-Content -Raw -Encoding UTF8 $RuntimeSettingsPath | ConvertFrom-Json
$TemplateSettings = Get-Content -Raw -Encoding UTF8 $TemplatePath | ConvertFrom-Json
$TemplateEntry = $TemplateSettings.hooks.PreToolUse |
  Where-Object { $_.matcher -eq "Bash" } |
  Select-Object -First 1
if ($null -eq $TemplateEntry) {
  throw "Bash PreToolUse entry not found in settings template"
}

$NewEntry = $TemplateEntry | ConvertTo-Json -Depth 20 | ConvertFrom-Json
$RuntimeHookPath = Join-Path $HooksRoot "pretooluse-guard.ps1"
$EscapedRuntimeHookPath = $RuntimeHookPath.Replace("'", "''")
$NewEntry.hooks[0].command = "powershell -NoProfile -ExecutionPolicy Bypass -Command `"& '$EscapedRuntimeHookPath'`""

if ($null -eq $RuntimeSettings.hooks) {
  $RuntimeSettings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{})
}

$ExistingPreToolUse = @()
if ($null -ne $RuntimeSettings.hooks.PSObject.Properties["PreToolUse"]) {
  $ExistingPreToolUse = @($RuntimeSettings.hooks.PreToolUse)
}
$PreservedPreToolUse = @(
  $ExistingPreToolUse | Where-Object {
    $Commands = @($_.hooks | ForEach-Object { [string]$_.command }) -join " "
    $Commands -notmatch $ManagedCommandPattern
  }
)
$MergedPreToolUse = @($PreservedPreToolUse) + @($NewEntry)

if ($null -eq $RuntimeSettings.hooks.PSObject.Properties["PreToolUse"]) {
  $RuntimeSettings.hooks | Add-Member -NotePropertyName PreToolUse -NotePropertyValue $MergedPreToolUse
} else {
  $RuntimeSettings.hooks.PreToolUse = $MergedPreToolUse
}

Write-Host "Target: $ClaudeRoot"
Write-Host "Preserved PreToolUse entries: $($PreservedPreToolUse.Count)"
Write-Host "Install hook: $RuntimeHookPath"
foreach ($HookName in $LegacyHookNames) {
  $LegacyPath = Join-Path $HooksRoot $HookName
  if (Test-Path -LiteralPath $LegacyPath -PathType Leaf) {
    Write-Host "Archive legacy hook: $LegacyPath"
  }
}

if (-not $Apply) {
  Write-Host "DRY RUN: no files changed. Re-run with -Apply to install."
  exit 0
}

$ArchiveRoot = Join-Path $ClaudeRoot ".archive"
$ArchivePath = Join-Path $ArchiveRoot ((Get-Date -Format "yyyyMMdd-HHmmss") + "-hook-lightweight")
if (Test-Path -LiteralPath $ArchivePath) {
  throw "Archive path already exists: $ArchivePath"
}

$MovedHookNames = [System.Collections.Generic.List[string]]::new()
$Encoding = [System.Text.UTF8Encoding]::new($false)

try {
  New-Item -ItemType Directory -Path $ArchivePath | Out-Null
  Copy-Item -LiteralPath $RuntimeSettingsPath -Destination (Join-Path $ArchivePath "settings.json")

  foreach ($HookName in $ManagedHookNames) {
    $RuntimeHook = Join-Path $HooksRoot $HookName
    if (Test-Path -LiteralPath $RuntimeHook -PathType Leaf) {
      Move-Item -LiteralPath $RuntimeHook -Destination (Join-Path $ArchivePath $HookName)
      $MovedHookNames.Add($HookName)
    }
  }

  Copy-Item -LiteralPath $SourceHook -Destination $RuntimeHookPath
  $SettingsJson = $RuntimeSettings | ConvertTo-Json -Depth 100
  [System.IO.File]::WriteAllText($RuntimeSettingsPath, $SettingsJson + [Environment]::NewLine, $Encoding)

  $SourceHash = (Get-FileHash -LiteralPath $SourceHook -Algorithm SHA256).Hash
  $RuntimeHash = (Get-FileHash -LiteralPath $RuntimeHookPath -Algorithm SHA256).Hash
  if ($SourceHash -ne $RuntimeHash) {
    throw "Installed hook hash mismatch"
  }

  $VerifiedSettings = Get-Content -Raw -Encoding UTF8 $RuntimeSettingsPath | ConvertFrom-Json
  $ManagedEntries = @(
    $VerifiedSettings.hooks.PreToolUse | Where-Object {
      (@($_.hooks | ForEach-Object { [string]$_.command }) -join " ") -match "pretooluse-guard"
    }
  )
  if ($ManagedEntries.Count -ne 1 -or $ManagedEntries[0].matcher -ne "Bash") {
    throw "Installed settings do not contain exactly one managed Bash hook"
  }

  Write-Host "APPLIED: hook and settings installed"
  Write-Host "Backup: $ArchivePath"
  Write-Host "SHA256: $RuntimeHash"
} catch {
  if (Test-Path -LiteralPath (Join-Path $ArchivePath "settings.json") -PathType Leaf) {
    Copy-Item -LiteralPath (Join-Path $ArchivePath "settings.json") -Destination $RuntimeSettingsPath -Force
  }
  if (Test-Path -LiteralPath $RuntimeHookPath -PathType Leaf) {
    Remove-Item -LiteralPath $RuntimeHookPath -Force
  }
  foreach ($HookName in $MovedHookNames) {
    $ArchivedHook = Join-Path $ArchivePath $HookName
    if (Test-Path -LiteralPath $ArchivedHook -PathType Leaf) {
      Move-Item -LiteralPath $ArchivedHook -Destination (Join-Path $HooksRoot $HookName)
    }
  }
  throw
}
