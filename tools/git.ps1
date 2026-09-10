param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
$workspaceRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$gitRoot = Join-Path $workspaceRoot '.tools/git'
$previousPath = $env:PATH
try {
    $env:PATH = (Join-Path $gitRoot 'mingw64/bin') + ';' + $env:PATH
    & (Join-Path $gitRoot 'cmd/git.exe') @GitArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    $env:PATH = $previousPath
}
