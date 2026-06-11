@echo off
REM Compila y copia DTFly a XAMPP. Doble clic para actualizar la web local.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_dtfly_xampp.ps1" -AbrirNavegador
pause
