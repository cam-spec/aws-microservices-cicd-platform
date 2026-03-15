# Build and start local microservices with Docker Compose.
# Usage: .\scripts\run-local.ps1

$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { Get-Location }
Set-Location $root

docker compose up --build -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Local services are running. Available URLs:"
Write-Host ""
Write-Host "  Customer service (port 3000):"
Write-Host "    http://localhost:3000/"
Write-Host "    http://localhost:3000/health"
Write-Host "    http://localhost:3000/suppliers"
Write-Host ""
Write-Host "  Employee service (port 3001):"
Write-Host "    http://localhost:3001/"
Write-Host "    http://localhost:3001/health"
Write-Host "    http://localhost:3001/admin/suppliers"
Write-Host ""
Write-Host "Run .\scripts\smoke-test.ps1 to verify endpoints. Run .\scripts\stop-local.ps1 to stop."
Write-Host ""
