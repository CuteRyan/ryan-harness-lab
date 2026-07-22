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

# PowerShell에서 이미 받은 JSON을 한 번만 읽어 Bash 훅에 전달합니다.
# 파싱에 실패하면 기존 stdin 방식으로 돌아가므로 훅 호환성은 유지됩니다.
if ($InputBytes.Length -gt 0) {
  try {
    $Payload = $Utf8NoBom.GetString($InputBytes.ToArray()) | ConvertFrom-Json
    if ($null -ne $Payload.tool_name) {
      $ProcessInfo.EnvironmentVariables["HARNESS_TOOL_NAME"] = [string]$Payload.tool_name
    }
    if ($null -ne $Payload.tool_input.file_path) {
      $ProcessInfo.EnvironmentVariables["HARNESS_FILE_PATH"] = [string]$Payload.tool_input.file_path
    }
    if ($null -ne $Payload.tool_input.command) {
      $ProcessInfo.EnvironmentVariables["HARNESS_COMMAND"] = [string]$Payload.tool_input.command
    }
  } catch {
    # Bash 훅이 stdin JSON을 직접 읽습니다.
  }
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
