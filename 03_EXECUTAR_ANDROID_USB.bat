@echo off
setlocal
title My Routine Active - Executar no Android
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 goto :sem_flutter
echo Conecte o celular por USB e ative a Depuracao USB.
flutter devices
echo.
flutter pub get
if errorlevel 1 goto :erro
flutter run
if errorlevel 1 goto :erro
exit /b 0

:sem_flutter
echo ERRO: Flutter nao foi encontrado. Execute 01_PREPARAR_PROJETO.bat.
pause
exit /b 1

:erro
echo.
echo Falha ao executar no Android. Confira o dispositivo e a saida acima.
pause
exit /b 1

