Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Split-HarnessShellSegments {
  param([Parameter(Mandatory = $true)][string]$Command)

  $Segments = [System.Collections.Generic.List[string]]::new()
  $Buffer = [System.Text.StringBuilder]::new()
  $InSingleQuote = $false
  $InDoubleQuote = $false
  $Escaped = $false

  foreach ($Character in $Command.ToCharArray()) {
    if ($Escaped) {
      [void]$Buffer.Append($Character)
      $Escaped = $false
      continue
    }

    if ($Character -eq "\" -and -not $InSingleQuote) {
      [void]$Buffer.Append($Character)
      $Escaped = $true
      continue
    }

    if ($Character -eq "'" -and -not $InDoubleQuote) {
      $InSingleQuote = -not $InSingleQuote
      [void]$Buffer.Append($Character)
      continue
    }

    if ($Character -eq '"' -and -not $InSingleQuote) {
      $InDoubleQuote = -not $InDoubleQuote
      [void]$Buffer.Append($Character)
      continue
    }

    if (-not $InSingleQuote -and -not $InDoubleQuote -and
        ($Character -eq ";" -or $Character -eq "|" -or $Character -eq "&" -or
         $Character -eq "`r" -or $Character -eq "`n")) {
      if ($Buffer.Length -gt 0) {
        $Segments.Add($Buffer.ToString())
        [void]$Buffer.Clear()
      }
      continue
    }

    [void]$Buffer.Append($Character)
  }

  if ($Buffer.Length -gt 0) {
    $Segments.Add($Buffer.ToString())
  }

  return $Segments
}

function ConvertTo-HarnessTokens {
  param([Parameter(Mandatory = $true)][string]$Segment)

  $Pattern = @'
"(?:\\.|[^"])*"|'(?:\\.|[^'])*'|[^\s]+
'@
  $Tokens = [System.Collections.Generic.List[string]]::new()

  foreach ($Match in [regex]::Matches($Segment, $Pattern.Trim())) {
    $Token = $Match.Value
    if ($Token.Length -ge 2 -and
        (($Token.StartsWith('"') -and $Token.EndsWith('"')) -or
         ($Token.StartsWith("'") -and $Token.EndsWith("'")))) {
      $Token = $Token.Substring(1, $Token.Length - 2)
    }
    $Tokens.Add($Token)
  }

  return $Tokens
}

function Get-HarnessGitInvocation {
  param([Parameter(Mandatory = $true)][string]$Segment)

  $Tokens = @(ConvertTo-HarnessTokens ($Segment.Trim().TrimStart("(", "{")))
  if ($Tokens.Count -eq 0) {
    return $null
  }

  $Index = 0
  while ($Index -lt $Tokens.Count -and $Tokens[$Index] -match '^[A-Za-z_][A-Za-z0-9_]*=') {
    $Index++
  }

  if ($Index -lt $Tokens.Count -and $Tokens[$Index].ToLowerInvariant() -eq "command") {
    $Index++
  }

  if ($Index -ge $Tokens.Count) {
    return $null
  }

  $Executable = $Tokens[$Index].Replace("\", "/")
  $ExecutableName = ($Executable -split "/")[-1].ToLowerInvariant()
  if ($ExecutableName -notin @("git", "git.exe")) {
    return $null
  }
  $Index++

  $OptionsWithSeparateValue = @("-c", "--config-env", "--exec-path", "--git-dir", "--namespace", "--super-prefix", "--work-tree")
  while ($Index -lt $Tokens.Count) {
    $Token = $Tokens[$Index]
    $LowerToken = $Token.ToLowerInvariant()

    if ($LowerToken -eq "-c") {
      $Index += 2
      continue
    }
    if ($LowerToken -eq "-C") {
      $Index += 2
      continue
    }
    if ($OptionsWithSeparateValue -contains $LowerToken) {
      $Index += 2
      continue
    }
    if ($LowerToken -match '^--(config-env|exec-path|git-dir|namespace|super-prefix|work-tree)=') {
      $Index++
      continue
    }
    if ($LowerToken.StartsWith("-")) {
      $Index++
      continue
    }
    break
  }

  if ($Index -ge $Tokens.Count) {
    return $null
  }

  $Arguments = @()
  if (($Index + 1) -lt $Tokens.Count) {
    $Arguments = @($Tokens[($Index + 1)..($Tokens.Count - 1)])
  }

  [pscustomobject]@{
    Subcommand = $Tokens[$Index].ToLowerInvariant()
    Arguments = $Arguments
  }
}

function Get-HarnessGitDecision {
  param([Parameter(Mandatory = $true)][string]$Command)

  foreach ($Segment in Split-HarnessShellSegments $Command) {
    $Invocation = Get-HarnessGitInvocation $Segment
    if ($null -eq $Invocation) {
      continue
    }

    $Arguments = @($Invocation.Arguments)
    $LowerArguments = @($Arguments | ForEach-Object { $_.ToLowerInvariant() })

    switch ($Invocation.Subcommand) {
      "rm" {
        return [pscustomobject]@{ Action = "block"; Reason = "git rm deletes working-tree files" }
      }
      "clean" {
        if ($LowerArguments | Where-Object { $_ -eq "--force" -or $_ -match '^-[^-]*f' }) {
          return [pscustomobject]@{ Action = "block"; Reason = "forced git clean deletes untracked files" }
        }
      }
      "reset" {
        if ($LowerArguments -contains "--hard") {
          return [pscustomobject]@{ Action = "block"; Reason = "git reset --hard discards uncommitted changes" }
        }
      }
      "restore" {
        $StagedOnly = ($LowerArguments -contains "--staged") -and ($LowerArguments -notcontains "--worktree")
        if (-not $StagedOnly) {
          return [pscustomobject]@{ Action = "block"; Reason = "git restore can discard working-tree changes" }
        }
      }
      "checkout" {
        if ($LowerArguments -contains "--") {
          return [pscustomobject]@{ Action = "block"; Reason = "git checkout -- can discard working-tree changes" }
        }
      }
      "push" {
        $HasForce = $false
        $HasLease = $false
        $HasForcedRefspec = $false

        foreach ($Argument in $LowerArguments) {
          if ($Argument -eq "--force" -or $Argument -match '^--force=' -or $Argument -match '^-[^-]*f') {
            $HasForce = $true
          } elseif ($Argument -match '^--force-with-lease(?:=|$)' -or $Argument -eq "--force-if-includes") {
            $HasLease = $true
          } elseif ($Argument.StartsWith("+") -and $Argument.Length -gt 1) {
            $HasForcedRefspec = $true
          }
        }

        if ($HasForce -or $HasForcedRefspec) {
          return [pscustomobject]@{ Action = "block"; Reason = "forced push can overwrite remote history" }
        }
        if ($HasLease) {
          return [pscustomobject]@{ Action = "warn"; Reason = "force-with-lease can rewrite remote history" }
        }
      }
    }
  }

  return [pscustomobject]@{ Action = "allow"; Reason = "" }
}

function Get-HarnessDeleteDecision {
  param([Parameter(Mandatory = $true)][string]$Command)

  $DeleteExecutables = @("rm", "rm.exe", "rmdir", "rd", "del", "erase", "unlink", "shred", "trash", "remove-item", "ri")

  foreach ($Segment in Split-HarnessShellSegments $Command) {
    $Tokens = @(ConvertTo-HarnessTokens ($Segment.Trim().TrimStart("(", "{")))
    if ($Tokens.Count -eq 0) {
      continue
    }

    $Index = 0
    while ($Index -lt $Tokens.Count -and $Tokens[$Index] -match '^[A-Za-z_][A-Za-z0-9_]*=') {
      $Index++
    }
    if ($Index -lt $Tokens.Count -and $Tokens[$Index].ToLowerInvariant() -eq "command") {
      $Index++
    }
    if ($Index -ge $Tokens.Count) {
      continue
    }

    $ExecutableName = ($Tokens[$Index].Replace("\", "/") -split "/")[-1].ToLowerInvariant()
    if ($DeleteExecutables -contains $ExecutableName) {
      return [pscustomobject]@{ Action = "ask"; Reason = "deletion command '$ExecutableName' requires explicit user confirmation" }
    }

    $LowerTokens = @($Tokens | ForEach-Object { $_.ToLowerInvariant() })
    if ($LowerTokens -contains "remove-item" -or $LowerTokens -contains "-delete") {
      return [pscustomobject]@{ Action = "ask"; Reason = "deletion inside command requires explicit user confirmation" }
    }
  }

  return [pscustomobject]@{ Action = "allow"; Reason = "" }
}

function Read-HarnessHookCommand {
  $InputStream = [Console]::OpenStandardInput()
  $Reader = [System.IO.StreamReader]::new($InputStream, [System.Text.UTF8Encoding]::new($false), $true)
  $RawInput = $Reader.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($RawInput)) {
    return ""
  }

  try {
    $Payload = $RawInput | ConvertFrom-Json
    return [string]$Payload.tool_input.command
  } catch {
    return ""
  }
}

function Invoke-HarnessPreToolUseGuard {
  $Command = Read-HarnessHookCommand
  if ([string]::IsNullOrWhiteSpace($Command)) {
    return 0
  }

  $Decision = Get-HarnessGitDecision $Command
  switch ($Decision.Action) {
    "block" {
      [Console]::Error.WriteLine("[hook] Blocked destructive Git command: $($Decision.Reason)")
      # Exit 2 is the documented blocking code for PreToolUse hooks.
      return 2
    }
    "warn" {
      [Console]::Error.WriteLine("[hook] Warning: $($Decision.Reason)")
    }
  }

  $DeleteDecision = Get-HarnessDeleteDecision $Command
  if ($DeleteDecision.Action -eq "ask") {
    $Response = @{
      hookSpecificOutput = @{
        hookEventName            = "PreToolUse"
        permissionDecision       = "ask"
        permissionDecisionReason = "pretooluse-guard: $($DeleteDecision.Reason)"
      }
    }
    [Console]::Out.WriteLine(($Response | ConvertTo-Json -Compress -Depth 4))
  }

  return 0
}

if ($MyInvocation.InvocationName -ne ".") {
  exit (Invoke-HarnessPreToolUseGuard)
}
