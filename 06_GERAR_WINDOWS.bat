@echo off
setlocal
title Smart Routine SI - Gerar Windows
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 goto :sem_flutter
flutter config --enable-windows-desktop
flutter pub get
if errorlevel 1 goto :erro
flutter build windows --release
if errorlevel 1 goto :erro

if not exist "ENTREGAS" mkdir "ENTREGAS"
if exist "ENTREGAS\Smart-Routine-SI-Windows" rmdir /s /q "ENTREGAS\Smart-Routine-SI-Windows"
xcopy /e /i /y "build\windows\x64\runner\Release" "ENTREGAS\Smart-Routine-SI-Windows" >nul
powershell -NoProfile -Command "Compress-Archive -Path 'ENTREGAS\Smart-Routine-SI-Windows\*' -DestinationPath 'ENTREGAS\Smart-Routine-SI-Windows.zip' -Force"
if errorlevel 1 goto :erro

set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ISCC%" (
  echo Gerando instalador Setup.exe...
  "%ISCC%" "installer\MyRoutineActive.iss"
  if errorlevel 1 goto :erro
) else (
  echo.
  echo Inno Setup 6 nao encontrado. O pacote portatil foi criado normalmente.
  echo Para gerar tambem o Setup.exe, instale https://jrsoftware.org/isdl.php
)

echo.
echo Pacote Windows criado em:
echo %CD%\ENTREGAS\Smart-Routine-SI-Windows.zip
if exist "ENTREGAS\Smart-Routine-SI-Setup.exe" echo %CD%\ENTREGAS\Smart-Routine-SI-Setup.exe
explorer "%CD%\ENTREGAS"
pause
exit /b 0

:sem_flutter
echo ERRO: Flutter nao foi encontrado. Execute 01_PREPARAR_PROJETO.bat.
pause
exit /b 1

:erro
echo.
echo Nao foi possivel gerar o pacote Windows. Confira a mensagem acima.
pause
exit /b 1
