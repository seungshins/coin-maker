$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$workspaceRoot = Split-Path $projectRoot -Parent
$manager = Join-Path $workspaceRoot '.tools/git/mingw64/bin/git-credential-manager.exe'
$previousStore = $env:GCM_CREDENTIAL_STORE
$previousStorePath = $env:GCM_DPAPI_STORE_PATH
try {
    $env:GCM_CREDENTIAL_STORE = 'dpapi'
    $env:GCM_DPAPI_STORE_PATH = Join-Path $workspaceRoot '.runtime/git-credentials'
    & $manager github login --device --no-ui --username seungshins
    if ($LASTEXITCODE -ne 0) { throw 'GitHub sign-in failed; no push was performed.' }
    & (Join-Path $PSScriptRoot 'git.ps1') -C $projectRoot -c http.sslBackend=openssl push -u origin main
    if ($LASTEXITCODE -ne 0) { throw 'GitHub push failed.' }
} finally {
    $env:GCM_CREDENTIAL_STORE = $previousStore
    $env:GCM_DPAPI_STORE_PATH = $previousStorePath
}
