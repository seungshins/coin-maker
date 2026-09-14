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
        'test' {
            & $engine --headless --path $gamePath --script res://tests/test_combat.gd
            if ($LASTEXITCODE -ne 0) { throw 'Combat tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_first_playable.gd
            if ($LASTEXITCODE -ne 0) { throw 'Playable tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_town.gd
            if ($LASTEXITCODE -ne 0) { throw 'Town tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_todo.gd
            if ($LASTEXITCODE -ne 0) { throw 'TODO tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_ui_curses.gd
            if ($LASTEXITCODE -ne 0) { throw 'UI curse tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_loadout.gd
            if ($LASTEXITCODE -ne 0) { throw 'Loadout tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v024.gd
            if ($LASTEXITCODE -ne 0) { throw 'v024 tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v025.gd
            if ($LASTEXITCODE -ne 0) { throw 'v025 tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v026.gd
            if ($LASTEXITCODE -ne 0) { throw 'v026 tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v027.gd
            if ($LASTEXITCODE -ne 0) { throw 'v027 tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v028.gd
            if ($LASTEXITCODE -ne 0) { throw 'v028 tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v0210.gd
            if ($LASTEXITCODE -ne 0) { throw 'v0210 tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v0211.gd
            if ($LASTEXITCODE -ne 0) { throw 'v0211 tests failed.' }
            & $engine --headless --path $gamePath --script res://tests/test_v0211_progression.gd
            if ($LASTEXITCODE -ne 0) { throw "Progression tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_v0212.gd
            if ($LASTEXITCODE -ne 0) { throw "Journey tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_controls.gd
            if ($LASTEXITCODE -ne 0) { throw "Controls tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_balance100.gd
            if ($LASTEXITCODE -ne 0) { throw "Balance tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_v0213.gd
            if ($LASTEXITCODE -ne 0) { throw "v0213 tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_v0214.gd
            if ($LASTEXITCODE -ne 0) { throw "v0214 tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_v0215.gd
            if ($LASTEXITCODE -ne 0) { throw "v0215 tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_homing.gd
            if ($LASTEXITCODE -ne 0) { throw "Homing tests failed." }
            & $engine --headless --path $gamePath --script res://tests/test_latency21.gd
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & $engine --headless --path $gamePath --script res://tests/test_v20.gd
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & $engine --headless --path $gamePath --script res://tests/test_minion20.gd
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & $engine --headless --path $gamePath --script res://tests/test_v19.gd
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & $engine --headless --path $gamePath --script res://tests/test_v0218.gd
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & $engine --headless --path $gamePath --script res://tests/test_model17.gd
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            & $engine --headless --path $gamePath --script res://tests/test_boss_patterns.gd
        }
    }
    if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalData
}
