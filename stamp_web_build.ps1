# Añade ?v=timestamp a flutter_bootstrap.js y main.dart.js para evitar caché del navegador.
param(
    [Parameter(Mandatory = $true)]
    [string]$WebDir,
    [string]$BuildId = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($BuildId)) {
    $BuildId = Get-Date -Format 'yyyyMMddHHmmss'
}

$indexPath = Join-Path $WebDir 'index.html'
$bootstrapPath = Join-Path $WebDir 'flutter_bootstrap.js'

if (-not (Test-Path $indexPath)) {
    throw "No se encontró index.html en $WebDir"
}
if (-not (Test-Path $bootstrapPath)) {
    throw "No se encontró flutter_bootstrap.js en $WebDir"
}

$index = Get-Content $indexPath -Raw -Encoding UTF8
$index = $index -replace 'flutter_bootstrap\.js(\?v=[^"''>]*)?', "flutter_bootstrap.js?v=$BuildId"
$index = $index -replace 'content="__DTFLY_BUILD__"', "content=`"$BuildId`""
Set-Content -Path $indexPath -Value $index -Encoding UTF8 -NoNewline

$bootstrap = Get-Content $bootstrapPath -Raw -Encoding UTF8
$bootstrap = $bootstrap -replace 'main\.dart\.js(\?v=[^"''`]*)?', "main.dart.js?v=$BuildId"
Set-Content -Path $bootstrapPath -Value $bootstrap -Encoding UTF8 -NoNewline

Write-Host "Cache-bust aplicado: $BuildId" -ForegroundColor DarkGray
return $BuildId
