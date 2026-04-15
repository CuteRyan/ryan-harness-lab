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

function Write-HarnessConfig {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$FeatureBody
  )

  Write-Utf8File (Join-Path $Root ".harness.yml") @"
harness: true
features:
$FeatureBody
"@
}

$TempRoot = Join-Path $env:TEMP ("harness-feature-test-" + [Guid]::NewGuid().ToString("N"))

try {
  New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot ".git") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot "docs") -Force | Out-Null
  New-Item -ItemType Directory -Path (Join-Path $TempRoot "src") -Force | Out-Null

  $DocFile = Join-Path $TempRoot "docs\guide.md"
  $CodeFile = Join-Path $TempRoot "src\app.py"
  Write-Utf8File $DocFile "# Guide`n"
  Write-Utf8File $CodeFile 'print("hello")'
  Write-Utf8File (Join-Path $TempRoot "docs\index.md") "# Index`n"

  $DocPayload = @{ tool_name = "Edit"; tool_input = @{ file_path = $DocFile } }
  $CodePayload = @{ tool_name = "Edit"; tool_input = @{ file_path = $CodeFile } }
  $WriteDocPayload = @{ tool_name = "Write"; tool_input = @{ file_path = (Join-Path $TempRoot "docs\new.md"); content = "# New`n" } }

  Assert-Hook "wiki guard no harness is silent" "wiki-index-guard.sh" $DocPayload 0

  Write-HarnessConfig $TempRoot "  wiki: false"
  Assert-Hook "wiki guard feature false is silent" "wiki-index-guard.sh" $DocPayload 0

  Write-HarnessConfig $TempRoot "  wiki: true"
  Assert-Hook "wiki guard feature true warns" "wiki-index-guard.sh" $DocPayload 0 "index.md"

  Write-HarnessConfig $TempRoot "  doc_templates: false"
  Assert-Hook "doc template feature false is silent" "doc-template-guard.sh" $WriteDocPayload 0

  Write-HarnessConfig $TempRoot "  doc_templates: true"
  Assert-Hook "doc template feature true blocks missing frontmatter" "doc-template-guard.sh" $WriteDocPayload 1 "YAML"

  Write-HarnessConfig $TempRoot "  code_doc_sync: false"
  Assert-Hook "code doc sync feature false is silent" "code-doc-sync.sh" $CodePayload 0

  Write-HarnessConfig $TempRoot "  code_doc_sync: true"
  Assert-Hook "code doc sync feature true without index is silent" "code-doc-sync.sh" $CodePayload 0

  Write-Utf8File (Join-Path $TempRoot "docs\.harness-index.json") @"
{
  "code_to_docs": {
    "src/app.py": ["docs/guide.md"]
  }
}
"@
  Assert-Hook "code doc sync feature true reminds with index" "code-doc-sync.sh" $CodePayload 0 "docs/guide.md"

  1..10 | ForEach-Object {
    Write-Utf8File (Join-Path $TempRoot "src\file$_.py") "print($_)`n"
  }

  Write-HarnessConfig $TempRoot "  graphify: false"
  Assert-Hook "graphify feature false is silent" "graphify-reminder.sh" $CodePayload 0

  Write-HarnessConfig $TempRoot "  graphify: true"
  Assert-Hook "graphify feature true warns" "graphify-reminder.sh" $CodePayload 0 "Graphify"
} finally {
  if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force
  }
}
