param([ValidateSet('all','windows','macos','linux')][string]$Target='all')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$workspace=Split-Path $project -Parent
$engine=Join-Path $workspace '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$version=(Get-Content -LiteralPath (Join-Path $project 'VERSION') -Raw).Trim()
if ($version -notmatch '^0\.2\.\d+$') { throw 'VERSION must be 0.2.N' }
$dist=Join-Path $project ('dist/' + $version)
New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (-not (Test-Path -LiteralPath $engine)) { throw 'Godot 4.7.2 editor and official export templates required.' }
$targets=@(@('windows','Windows Desktop',"Odyssey-v$version.exe"),@('macos','macOS',"Odyssey-v$version-macOS.zip"),@('linux','Linux',"Odyssey-v$version.x86_64"))
foreach($entry in $targets) {
    if($Target -ne 'all' -and $Target -ne $entry[0]) { continue }
    & $engine --headless --path (Join-Path $project 'game') --export-release $entry[1] (Join-Path $dist $entry[2])
    if($LASTEXITCODE -ne 0) { throw "Export failed: $($entry[1])" }
}
if(Test-Path -LiteralPath (Join-Path $dist "Odyssey-v$version.exe")) {
    Compress-Archive -LiteralPath (Join-Path $dist "Odyssey-v$version.exe") -DestinationPath (Join-Path $dist "Odyssey-v$version-Windows.zip") -Force
}
$hashes = foreach($file in Get-ChildItem -LiteralPath $dist -File) {
    if ($file.Name -eq 'SHA256SUMS.txt') { continue }
    $stream = [IO.File]::OpenRead($file.FullName)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','').ToLower() + '  ' + $file.Name }
    finally { $stream.Dispose(); $sha.Dispose() }
}
$hashes | Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS.txt') -Encoding ASCII
$hashes
