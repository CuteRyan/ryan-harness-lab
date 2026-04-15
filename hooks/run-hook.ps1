param(
  [Parameter(Mandatory = $true)]
  [string]$HookName
)

$ErrorActionPreference = "Stop"

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $Utf8NoBom
[Console]::OutputEncoding = $Utf8NoBom

$Bash = "C:\Program Files\Git\bin\bash.exe"
$HookPath = Join-Path $env:USERPROFILE ".claude\hooks\$HookName"

if (-not (Test-Path -LiteralPath $Bash)) {
  Write-Error "Git Bash not found: $Bash"
  exit 127
}

if (-not (Test-Path -LiteralPath $HookPath)) {
  Write-Error "Claude hook not found: $HookPath"
  exit 127
}

$InputBytes = New-Object System.IO.MemoryStream
if ([Console]::IsInputRedirected) {
  $Stdin = [Console]::OpenStandardInput()
  $Buffer = New-Object byte[] 8192
  while (($Read = $Stdin.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
    $InputBytes.Write($Buffer, 0, $Read)
  }
  $InputBytes.Position = 0
}

$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
$ProcessInfo.FileName = $Bash
$ProcessInfo.Arguments = '"' + $HookPath.Replace('"', '\"') + '"'
$ProcessInfo.UseShellExecute = $false
$ProcessInfo.RedirectStandardInput = $true
$ProcessInfo.RedirectStandardOutput = $true
$ProcessInfo.RedirectStandardError = $true

try {
  $ProcessInfo.StandardOutputEncoding = $Utf8NoBom
  $ProcessInfo.StandardErrorEncoding = $Utf8NoBom
} catch {
  # Older .NET runtimes may not expose these properties.
}

$Process = [System.Diagnostics.Process]::Start($ProcessInfo)
if ($InputBytes.Length -gt 0) {
  $Bytes = $InputBytes.ToArray()
  $Process.StandardInput.BaseStream.Write($Bytes, 0, $Bytes.Length)
}
$Process.StandardInput.Close()

$Stdout = $Process.StandardOutput.ReadToEnd()
$Stderr = $Process.StandardError.ReadToEnd()
$Process.WaitForExit()

if ($Stdout.Length -gt 0) {
  [Console]::Out.Write($Stdout)
}
if ($Stderr.Length -gt 0) {
  [Console]::Error.Write($Stderr)
}
exit $Process.ExitCode
