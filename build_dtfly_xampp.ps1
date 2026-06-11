# Compila DTFly para web y copia los archivos HTML/JS a XAMPP (htdocs).
#
# Uso básico (requiere XAMPP en C:\xampp):
#   .\build_dtfly_xampp.ps1
#
# Carpeta personalizada dentro de htdocs:
#   .\build_dtfly_xampp.ps1 -Carpeta mi_app
#
# Ruta distinta de htdocs:
#   .\build_dtfly_xampp.ps1 -Destino "D:\xampp\htdocs\dtfly"
#
# Solo compilar sin copiar (deja todo en build\web):
#   .\build_dtfly_xampp.ps1 -SoloCompilar
#
# URL resultante (por defecto): http://localhost/dtfly/

param(
    [string]$Destino = '',
    [string]$Carpeta = '',
    [string]$XamppHtdocs = '',
    [switch]$SoloCompilar,
    [switch]$AbrirNavegador
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$configFile = Join-Path $PSScriptRoot 'xampp.config.ps1'
if (Test-Path $configFile) {
    . $configFile
}

if ([string]::IsNullOrWhiteSpace($Carpeta)) { $Carpeta = 'dtfly' }
if ([string]::IsNullOrWhiteSpace($XamppHtdocs)) { $XamppHtdocs = 'C:\xampp\htdocs' }

function Resolve-Flutter {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        return 'flutter'
    }
    $candidates = @(
        'D:\app\flutter\flutter\bin\flutter.bat',
        'D:\app\flutter\bin\flutter.bat',
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

$flutter = Resolve-Flutter
Write-Host "Usando Flutter: $flutter" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($Destino)) {
    $Destino = Join-Path $XamppHtdocs $Carpeta
}

$baseHref = if ($Carpeta -eq '' -or $Carpeta -eq '/') { '/' } else { "/$Carpeta/" }

Write-Host "Compilando web (release) con base-href=$baseHref ..." -ForegroundColor Yellow
& $flutter pub get
& $flutter build web --release --base-href=$baseHref

$origen = Join-Path $PSScriptRoot 'build\web'
if (-not (Test-Path (Join-Path $origen 'index.html'))) {
    throw 'La compilación no generó build\web\index.html'
}

Write-Host 'Compilación OK: build\web\' -ForegroundColor Green

if ($SoloCompilar) {
    Write-Host ''
    Write-Host 'Archivos listos en:' -ForegroundColor Green
    Write-Host "  $origen" -ForegroundColor Green
    Write-Host ''
    Write-Host 'Para probar sin XAMPP (servidor temporal):' -ForegroundColor Cyan
    Write-Host "  cd build\web" -ForegroundColor White
    Write-Host "  python -m http.server 8080" -ForegroundColor White
    Write-Host '  Abrir: http://localhost:8080/' -ForegroundColor White
    exit 0
}

# Copia local de respaldo dentro del proyecto (útil si XAMPP no está instalado aún).
$backupLocal = Join-Path $PSScriptRoot 'web_local'
if (Test-Path $backupLocal) {
    Remove-Item $backupLocal -Recurse -Force
}
Copy-Item $origen $backupLocal -Recurse
Write-Host "Copia local: web_local\" -ForegroundColor DarkGray

if (-not (Test-Path $XamppHtdocs)) {
    Write-Host ''
    Write-Host "No se encontró XAMPP en: $XamppHtdocs" -ForegroundColor Yellow
    Write-Host 'Los archivos están en web_local\ — puedes:' -ForegroundColor Yellow
    Write-Host '  1) Instalar XAMPP y volver a ejecutar este script' -ForegroundColor Yellow
    Write-Host '  2) En XAMPP, apuntar DocumentRoot a web_local\' -ForegroundColor Yellow
    Write-Host '  3) Copiar manualmente web_local\ a tu carpeta htdocs' -ForegroundColor Yellow
    exit 0
}

if (Test-Path $Destino) {
    Remove-Item $Destino -Recurse -Force
}
New-Item -ItemType Directory -Path $Destino -Force | Out-Null
Copy-Item (Join-Path $origen '*') $Destino -Recurse -Force

$url = if ($baseHref -eq '/') { 'http://localhost/' } else { "http://localhost/$Carpeta/" }

Write-Host ''
Write-Host 'Listo. Archivos copiados a:' -ForegroundColor Green
Write-Host "  $Destino" -ForegroundColor Green
Write-Host ''
Write-Host 'Abre en el navegador (Apache de XAMPP debe estar iniciado):' -ForegroundColor Green
Write-Host "  $url" -ForegroundColor Green
Write-Host ''
Write-Host 'Archivos principales para revisar:' -ForegroundColor Cyan
Write-Host "  $Destino\index.html" -ForegroundColor White
Write-Host "  $Destino\flutter_bootstrap.js" -ForegroundColor White
Write-Host "  $Destino\main.dart.js" -ForegroundColor White

if ($AbrirNavegador) {
    Start-Process $url
}
