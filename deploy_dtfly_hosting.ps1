# Compila DTFly para web y publica en Firebase Hosting.
param(
    [string]$BuildId = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Resolve-Flutter {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        return 'flutter'
    }
    $candidates = @(
        'D:\app\flutter\bin\flutter.bat',
        'D:\app\flutter\flutter\bin\flutter.bat',
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        'C:\src\flutter\bin\flutter.bat',
        'C:\flutter\bin\flutter.bat'
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    throw 'No se encontró Flutter. Instálalo o agrégalo al PATH.'
}

if ([string]::IsNullOrWhiteSpace($BuildId)) {
    $BuildId = Get-Date -Format 'yyyyMMddHHmm'
}

$flutter = Resolve-Flutter
Write-Host "Usando Flutter: $flutter" -ForegroundColor Cyan

Write-Host "Compilando web (release) build=$BuildId ..." -ForegroundColor Yellow
& $flutter pub get
& $flutter build web --release --no-wasm-dry-run --dart-define=DTFLY_BUILD=$BuildId

if (-not (Test-Path 'build\web\index.html')) {
    throw 'La compilación no generó build\web\index.html'
}

& (Join-Path $PSScriptRoot 'stamp_web_build.ps1') -WebDir (Join-Path $PSScriptRoot 'build\web') -BuildId $BuildId | Out-Null

Write-Host 'Desplegando Firebase Hosting...' -ForegroundColor Yellow
firebase deploy --only hosting

Write-Host ''
Write-Host 'Listo. URL:' -ForegroundColor Green
Write-Host '  https://dtfly-d8997.web.app' -ForegroundColor Green
Write-Host '  https://dtfly-d8997.firebaseapp.com' -ForegroundColor Green
Write-Host "  Build: $BuildId" -ForegroundColor Green
