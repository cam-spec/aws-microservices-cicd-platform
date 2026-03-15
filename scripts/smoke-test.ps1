# Smoke test for local customer-service (3000) and employee-service (3001).
# Usage: .\scripts\smoke-test.ps1
# Exits with 0 if all endpoints pass, non-zero otherwise.

$ErrorActionPreference = 'Stop'

$endpoints = @(
    'http://localhost:3000/',
    'http://localhost:3000/health',
    'http://localhost:3000/suppliers',
    'http://localhost:3001/',
    'http://localhost:3001/health',
    'http://localhost:3001/admin/suppliers'
)

$failed = 0
foreach ($url in $endpoints) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
        if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) {
            Write-Host "PASS  $url"
        } else {
            Write-Host "FAIL  $url (HTTP $($r.StatusCode))"
            $failed++
        }
    } catch {
        Write-Host "FAIL  $url ($($_.Exception.Message))"
        $failed++
    }
}

if ($failed -gt 0) {
    Write-Host "`n$failed endpoint(s) failed."
    exit 1
}
Write-Host "`nAll endpoints passed."
exit 0
