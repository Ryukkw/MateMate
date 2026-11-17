# Install MateMate clipboard support into an existing native Windows Herdr setup.
# Run: powershell -NoProfile -File .\setup\bin\clipboard-windows.ps1
# Optional: -TerminalSettings <path> for a portable Windows Terminal install.
param([string]$TerminalSettings)
$ErrorActionPreference = 'Stop'
$MateRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$MatePlugin = Join-Path $MateRoot 'setup\plugins\clipboard'
foreach ($MateTool in @('node', 'npm.cmd', 'herdr')) {
    if (-not (Get-Command $MateTool -ErrorAction SilentlyContinue)) {
        throw "Install prerequisite first: $MateTool"
    }
}
if (-not $TerminalSettings) {
    $MateCandidates = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )
    $TerminalSettings = $MateCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $TerminalSettings) { throw 'Open Windows Terminal once or specify -TerminalSettings <path>.' }
& npm.cmd ci --prefix $MatePlugin --ignore-scripts --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { throw 'Clipboard dependency installation failed' }
& herdr plugin link $MatePlugin --enabled
if ($LASTEXITCODE -ne 0) { throw 'Herdr plugin installation failed' }
& node (Join-Path $MatePlugin 'configure.mjs') --terminal-settings $TerminalSettings
if ($LASTEXITCODE -ne 0) { throw 'Clipboard key configuration failed' }
& herdr config check
if ($LASTEXITCODE -ne 0) { throw 'Herdr configuration is invalid' }
& herdr server reload-config
if ($LASTEXITCODE -ne 0) { throw 'Open Herdr and run: herdr server reload-config' }
Write-Host 'Ready: Ctrl+V pastes image file paths or text. Enter in the agent sends the message.'
Write-Host 'Windows Terminal now sends Ctrl+V to programs; outside Herdr use Ctrl+Shift+V for text paste.'
