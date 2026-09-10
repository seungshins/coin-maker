param([ValidateSet('play', 'editor', 'test')][string]$Mode = 'play')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$workspaceRoot = Split-Path $projectRoot -Parent
$engine = Join-Path $workspaceRoot '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $engine)) { throw "Godot 4.7.2 not found: $engine" }
# Keep development user data inside the workspace, without changing system settings.
$runtimeRoot = Join-Path $workspaceRoot '.runtime'
New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
$previousAppData = $env:APPDATA
$previousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $runtimeRoot
    $env:LOCALAPPDATA = $runtimeRoot
    $gamePath = Join-Path $projectRoot 'game'
    switch ($Mode) {
        'editor' { & $engine --path $gamePath --editor }
        'play' { & $engine --path $gamePath }
        'test' { & $engine --headless --path $gamePath --script res://tests/test_combat.gd }
    }
    if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalData
}
