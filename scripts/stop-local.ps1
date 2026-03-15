# Stop local microservices (Docker Compose down).
# Usage: .\scripts\stop-local.ps1

$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { Get-Location }
Set-Location $root

docker compose down
exit $LASTEXITCODE
