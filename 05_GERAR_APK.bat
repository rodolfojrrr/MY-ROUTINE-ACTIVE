@echo off
setlocal
title My Routine Active - Gerar APK
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 goto :sem_flutter
flutter pub get
if errorlevel 1 goto :erro
flutter build apk --release
if errorlevel 1 goto :erro

if not exist "ENTREGAS" mkdir "ENTREGAS"
copy /y "build\app\outputs\flutter-apk\app-release.apk" "ENTREGAS\My-Routine-Active.apk" >nul
echo.
echo APK criado em:
echo %CD%\ENTREGAS\My-Routine-Active.apk
explorer "%CD%\ENTREGAS"
pause
exit /b 0

:sem_flutter
echo ERRO: Flutter nao foi encontrado. Execute 01_PREPARAR_PROJETO.bat.
pause
exit /b 1

:erro
echo.
echo Nao foi possivel gerar o APK. Confira a mensagem acima.
pause
exit /b 1

