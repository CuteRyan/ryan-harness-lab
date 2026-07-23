Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Installer = Join-Path $RepoRoot "scripts\install-global-hook.ps1"
$SourceHook = Join-Path $RepoRoot "hooks\pretooluse-guard.ps1"
$TempParent = Join-Path $env:TEMP ("harness-hook-install-" + [Guid]::NewGuid().ToString("N"))
$FakeClaudeRoot = Join-Path $TempParent ".claude"
$FakeHooksRoot = Join-Path $FakeClaudeRoot "hooks"
$Encoding = [System.Text.UTF8Encoding]::new($false)

try {
  New-Item -ItemType Directory -Path $FakeHooksRoot -Force | Out-Null

  $LegacyNames = @(
    "_harness_common.sh",
    "deploy-version-guard.sh",
    "doc-protection.sh",
    "pre-bash-guards.sh",
    "run-hook.ps1"
  )
  foreach ($Name in $LegacyNames) {
    [System.IO.File]::WriteAllText((Join-Path $FakeHooksRoot $Name), "legacy-$Name", $Encoding)
  }

  $FakeSettings = [ordered]@{
    env = [ordered]@{ KEEP_ME = "yes" }
    model = "keep-model"
    hooks = [ordered]@{
      PreToolUse = @(
        [ordered]@{
          matcher = "Agent"
          hooks = @([ordered]@{ type = "command"; command = "custom-agent-hook" })
        },
        [ordered]@{
          matcher = "Bash"
          hooks = @([ordered]@{ type = "command"; command = "run-hook.ps1 pre-bash-guards.sh" })
        },
        [ordered]@{
          matcher = "Edit|Write|MultiEdit"
          hooks = @([ordered]@{ type = "command"; command = "run-hook.ps1 doc-protection.sh" })
        }
      )
      PostToolUse = @(
        [ordered]@{
          matcher = "Edit"
          hooks = @([ordered]@{ type = "command"; command = "custom-post-hook" })
        }
      )
    }
  }
  [System.IO.File]::WriteAllText(
    (Join-Path $FakeClaudeRoot "settings.json"),
    ($FakeSettings | ConvertTo-Json -Depth 20),
    $Encoding
  )

  & $Installer -ClaudeRoot $FakeClaudeRoot
  if (Test-Path -LiteralPath (Join-Path $FakeHooksRoot "pretooluse-guard.ps1")) {
    throw "dry run changed the target"
  }
  Write-Host "PASS dry run makes no changes"

  & $Installer -ClaudeRoot $FakeClaudeRoot -Apply

  $InstalledHook = Join-Path $FakeHooksRoot "pretooluse-guard.ps1"
  if (-not (Test-Path -LiteralPath $InstalledHook -PathType Leaf)) {
    throw "new hook was not installed"
  }
  if ((Get-FileHash $SourceHook).Hash -ne (Get-FileHash $InstalledHook).Hash) {
    throw "installed hook hash differs from source"
  }
  foreach ($Name in $LegacyNames) {
    if (Test-Path -LiteralPath (Join-Path $FakeHooksRoot $Name)) {
      throw "legacy hook remains active: $Name"
    }
  }

  $Archive = Get-ChildItem (Join-Path $FakeClaudeRoot ".archive") -Directory
  if (@($Archive).Count -ne 1) {
    throw "expected exactly one archive"
  }
  foreach ($Name in $LegacyNames) {
    if (-not (Test-Path -LiteralPath (Join-Path $Archive.FullName $Name))) {
      throw "legacy hook was not archived: $Name"
    }
  }
  if (-not (Test-Path -LiteralPath (Join-Path $Archive.FullName "settings.json"))) {
    throw "settings backup was not created"
  }

  $InstalledSettings = Get-Content -Raw -Encoding UTF8 (Join-Path $FakeClaudeRoot "settings.json") | ConvertFrom-Json
  if ($InstalledSettings.env.KEEP_ME -ne "yes" -or $InstalledSettings.model -ne "keep-model") {
    throw "user-specific settings were not preserved"
  }
  if (@($InstalledSettings.hooks.PostToolUse).Count -ne 1) {
    throw "unrelated hook section was not preserved"
  }
  $PreToolUse = @($InstalledSettings.hooks.PreToolUse)
  if (@($PreToolUse | Where-Object matcher -eq "Agent").Count -ne 1) {
    throw "unrelated PreToolUse entry was not preserved"
  }
  $Managed = @(
    $PreToolUse | Where-Object {
      (@($_.hooks | ForEach-Object { [string]$_.command }) -join " ") -match "pretooluse-guard"
    }
  )
  if ($Managed.Count -ne 1 -or $Managed[0].matcher -ne "Bash") {
    throw "managed Bash entry was not installed exactly once"
  }
  Write-Host "PASS apply preserves settings and archives legacy hooks"
} finally {
  $ResolvedTempParent = [System.IO.Path]::GetFullPath($TempParent)
  $ResolvedSystemTemp = [System.IO.Path]::GetFullPath($env:TEMP)
  if ($ResolvedTempParent.StartsWith($ResolvedSystemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and
      (Test-Path -LiteralPath $ResolvedTempParent)) {
    Remove-Item -LiteralPath $ResolvedTempParent -Recurse -Force
  }
}
