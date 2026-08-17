@echo off
setlocal
title My Routine Active - Preparar projeto
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERRO: Flutter nao foi encontrado no PATH.
  echo Instale o Flutter conforme o README.md e abra este BAT novamente.
  pause
  exit /b 1
)

echo Verificando Flutter...
flutter --version
if errorlevel 1 goto :erro

echo.
echo Instalando dependencias do projeto...
flutter pub get
if errorlevel 1 goto :erro

echo.
echo Projeto preparado com sucesso.
pause
exit /b 0

:erro
echo.
echo O processo foi interrompido por causa do erro exibido acima.
pause
exit /b 1

