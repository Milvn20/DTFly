# Ejecuta DTFly en el navegador con hot-reload (desarrollo).
# Para XAMPP / archivos HTML locales, usa: .\build_dtfly_xampp.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Resolve-Flutter {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        return 'flutter'
    }
    $candidates = @(
        'D:\app\flutter\flutter\bin\flutter.bat',
        'D:\app\flutter\bin\flutter.bat'
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    throw 'No se encontró Flutter.'
}

$flutter = Resolve-Flutter
Write-Host "Modo desarrollo web → http://localhost:8080" -ForegroundColor Cyan
& $flutter run -d chrome --web-port=8080 @args
