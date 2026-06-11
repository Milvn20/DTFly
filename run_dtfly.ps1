# Ejecuta la app DTFly. Usa SIEMPRE esta carpeta (no la raiz del SDK de Flutter).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Write-Host "Carpeta del proyecto: $PSScriptRoot" -ForegroundColor Cyan
flutter pub get
flutter run @args
