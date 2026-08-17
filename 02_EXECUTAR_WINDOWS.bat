@echo off
setlocal
title My Routine Active - Executar no Windows
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 goto :sem_flutter
flutter config --enable-windows-desktop
flutter pub get
if errorlevel 1 goto :erro
flutter run -d windows
if errorlevel 1 goto :erro
exit /b 0

:sem_flutter
echo ERRO: Flutter nao foi encontrado. Execute 01_PREPARAR_PROJETO.bat.
pause
exit /b 1

:erro
echo.
echo Falha ao executar. Confira o README.md e a saida acima.
pause
exit /b 1

