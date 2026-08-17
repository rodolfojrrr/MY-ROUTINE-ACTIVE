@echo off
setlocal
title My Routine Active - Gerar Windows
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 goto :sem_flutter
flutter config --enable-windows-desktop
flutter pub get
if errorlevel 1 goto :erro
flutter build windows --release
if errorlevel 1 goto :erro

if not exist "ENTREGAS" mkdir "ENTREGAS"
if exist "ENTREGAS\My-Routine-Active-Windows" rmdir /s /q "ENTREGAS\My-Routine-Active-Windows"
xcopy /e /i /y "build\windows\x64\runner\Release" "ENTREGAS\My-Routine-Active-Windows" >nul
powershell -NoProfile -Command "Compress-Archive -Path 'ENTREGAS\My-Routine-Active-Windows\*' -DestinationPath 'ENTREGAS\My-Routine-Active-Windows.zip' -Force"
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
echo %CD%\ENTREGAS\My-Routine-Active-Windows.zip
if exist "ENTREGAS\My-Routine-Active-Setup.exe" echo %CD%\ENTREGAS\My-Routine-Active-Setup.exe
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
