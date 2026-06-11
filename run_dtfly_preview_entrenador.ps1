# Vista previa del panel entrenador sin login ni Firebase.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Write-Host "Modo vista previa: entrenador (sin Firebase)" -ForegroundColor Yellow
flutter pub get
flutter run --dart-define=DTFLY_COACH_PREVIEW=true @args
