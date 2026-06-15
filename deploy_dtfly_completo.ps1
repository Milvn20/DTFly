# Compila y publica DTFly en XAMPP (localhost/dtfly) y Firebase Hosting.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$buildId = Get-Date -Format 'yyyyMMddHHmm'

Write-Host "=== DTFly deploy completo (build $buildId) ===" -ForegroundColor Cyan

Write-Host "`n[1/2] XAMPP localhost/dtfly ..." -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'build_dtfly_xampp.ps1') -BuildId $buildId

Write-Host "`n[2/2] Firebase Hosting ..." -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'deploy_dtfly_hosting.ps1') -BuildId $buildId

Write-Host ''
Write-Host 'Deploy completo.' -ForegroundColor Green
Write-Host '  Local:    http://localhost/dtfly/' -ForegroundColor Green
Write-Host '  Firebase: https://dtfly-d8997.web.app/' -ForegroundColor Green
Write-Host "  Build:    $buildId (debe verse en login y panel admin)" -ForegroundColor Green
