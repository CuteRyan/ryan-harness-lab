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
    [Parameter(Mandatory = $true)][hashtable]$Payload
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
    [Parameter(Mandatory = $true)][string]$HookName,
    [Parameter(Mandatory = $true)][hashtable]$Payload,
    [Parameter(Mandatory = $true)][int]$ExpectedExitCode,
    [string]$ExpectedOutput
  )

  $Result = Invoke-Hook -HookName $HookName -Payload $Payload
  if ($Result.ExitCode -ne $ExpectedExitCode) {
    throw @"
[$Name] expected exit code $ExpectedExitCode, got $($Result.ExitCode)
Hook: $HookName
Output:
$($Result.Output)
"@
  }
  if ($ExpectedOutput -and $Result.Output -notlike "*$ExpectedOutput*") {
    throw @"
[$Name] expected output containing: $ExpectedOutput
Hook: $HookName
Actual output:
$($Result.Output)
"@
  }

  Write-Host "PASS $Name"
}

$TempRoot = Join-Path $env:TEMP ("harness-p2-test-" + [Guid]::NewGuid().ToString("N"))

try {
  New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot ".git") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot "src") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot "docs") -Force | Out-Null

  $CodeFile = Join-Path $TempRoot "src\app.py"
  $DocFile = Join-Path $TempRoot "docs\guide.md"
  $TargetDoc = Join-Path $TempRoot "docs\target.md"
  $DevChecklist = Join-Path $TempRoot ".dev-checklist.md"
  $DocChecklist = Join-Path $TempRoot ".doc-checklist.md"

  Write-Utf8File $CodeFile "print('hello')`n"
  Write-Utf8File $DocFile "# Guide`n"
  Write-Utf8File $TargetDoc "# Target`n"

  $TinyCodeEdit = @{
    tool_name = "Edit"
    tool_input = @{
      file_path = $CodeFile
      old_string = "print('helo')"
      new_string = "print('hello')"
    }
  }
  Assert-Hook "tiny code edit bypasses missing dev checklist" "dev-checklist-guard.sh" $TinyCodeEdit 0

  $LargeCodeEdit = @{
    tool_name = "Edit"
    tool_input = @{
      file_path = $CodeFile
      old_string = "a`nb`nc`nd"
      new_string = "a`nb`nc`nd"
    }
  }
  Assert-Hook "large code edit still requires dev checklist" "dev-checklist-guard.sh" $LargeCodeEdit 2

  $TinyDocEdit = @{
    tool_name = "Edit"
    tool_input = @{
      file_path = $DocFile
      old_string = "helo"
      new_string = "hello"
    }
  }
  Assert-Hook "tiny doc edit bypasses missing doc checklist" "doc-checklist-guard.sh" $TinyDocEdit 0

  $LargeDocEdit = @{
    tool_name = "Edit"
    tool_input = @{
      file_path = $DocFile
      old_string = "a`nb`nc`nd"
      new_string = "a`nb`nc`nd"
    }
  }
  Assert-Hook "large doc edit still requires doc checklist" "doc-checklist-guard.sh" $LargeDocEdit 1

  $PostCodePayload = @{ tool_name = "Edit"; tool_input = @{ file_path = $CodeFile } }
  Write-Utf8File $CodeFile "print('ok')`n"
  Assert-Hook "post verify accepts valid python" "post-edit-verify.sh" $PostCodePayload 0

  Write-Utf8File $CodeFile "def broken(:`n    pass`n"
  Assert-Hook "post verify blocks invalid python" "post-edit-verify.sh" $PostCodePayload 1 "Python"

  $PostDocPayload = @{ tool_name = "Edit"; tool_input = @{ file_path = $DocFile } }
  Write-Utf8File $DocFile "# Guide`n[Target](target.md)`n"
  Assert-Hook "post verify accepts valid markdown link" "post-edit-verify.sh" $PostDocPayload 0

  Write-Utf8File $DocFile "# Guide`n[Missing](missing.md)`n"
  Assert-Hook "post verify blocks broken markdown link" "post-edit-verify.sh" $PostDocPayload 1 "Markdown"

  Write-Utf8File $DocFile @"
---
title: Guide
type: design
---

# Guide
"@
  Assert-Hook "post verify blocks incomplete frontmatter" "post-edit-verify.sh" $PostDocPayload 1 "frontmatter"

  Write-Utf8File $DocFile @"
---
title: Guide
type: design
status: draft
created: 2026-04-15
---

# Guide
[Target](target.md)
"@
  Assert-Hook "post verify accepts complete frontmatter" "post-edit-verify.sh" $PostDocPayload 0

  Write-Utf8File (Join-Path $TempRoot ".harness.yml") @"
harness: true
features:
  doc_templates: true
"@
  $PostNewDocPayload = @{ tool_name = "Write"; tool_input = @{ file_path = (Join-Path $TempRoot "docs\new.md") } }
  Write-Utf8File (Join-Path $TempRoot "docs\new.md") "# New`n"
  Assert-Hook "post verify requires new doc frontmatter when feature enabled" "post-edit-verify.sh" $PostNewDocPayload 1 "frontmatter"

  $PostDevChecklistPayload = @{ tool_name = "Edit"; tool_input = @{ file_path = $DevChecklist } }
  Write-Utf8File $DevChecklist @"
status: approved

## Tasks
- [ ] Update implementation

## Changed Files
- [x] src/app.py

## Verification
- [ ] Run tests

## Double Check
- [x] approved
"@
  Assert-Hook "post verify accepts checked existing dev file" "post-edit-verify.sh" $PostDevChecklistPayload 0

  Write-Utf8File $DevChecklist @"
status: approved

## Tasks
- [ ] Update implementation

## Changed Files
- [x] src/missing.py

## Verification
- [ ] Run tests

## Double Check
- [x] approved
"@
  Assert-Hook "post verify blocks checked missing dev file" "post-edit-verify.sh" $PostDevChecklistPayload 1 "checklist"

  $PostDocChecklistPayload = @{ tool_name = "Edit"; tool_input = @{ file_path = $DocChecklist } }
  Write-Utf8File $DocChecklist @"
status: approved

## Scope
- [ ] Update docs

## Related Docs
- [x] docs/target.md

## Cross Check
- [ ] Review links

## Double Check
- [x] approved
"@
  Assert-Hook "post verify accepts checked existing related doc" "post-edit-verify.sh" $PostDocChecklistPayload 0

  Write-Utf8File $DocChecklist @"
status: approved

## Scope
- [ ] Update docs

## Related Docs
- [x] docs/missing.md

## Cross Check
- [ ] Review links

## Double Check
- [x] approved
"@
  Assert-Hook "post verify blocks checked missing related doc" "post-edit-verify.sh" $PostDocChecklistPayload 1 "checklist"
} finally {
  if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force
  }
}
