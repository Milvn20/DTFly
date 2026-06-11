@echo off
title DTFly - Instalar en XAMPP
cd /d "%~dp0"

echo.
echo ============================================
echo   DTFly - Publicar en XAMPP (local)
echo ============================================
echo.
echo PASO 1: Abre XAMPP Control Panel
echo PASO 2: Pulsa START en Apache (debe quedar en verde)
echo.
pause

echo.
echo Compilando y copiando archivos...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_dtfly_xampp.ps1" -AbrirNavegador

echo.
echo ============================================
echo   Si no abrio solo, prueba en el navegador:
echo   http://localhost/dtfly/
echo ============================================
echo.
pause
