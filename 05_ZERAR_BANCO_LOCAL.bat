@echo off
setlocal
chcp 65001 >nul
title My Routine Active - Zerar banco local
cd /d "%~dp0"

echo.
echo Este procedimento apaga somente o banco e os arquivos locais de teste.
echo Ele não altera a versão publicada nem o banco de produção.
echo.
set /p "CONFIRMACAO=Digite ZERAR para continuar: "

if /I not "%CONFIRMACAO%"=="ZERAR" (
  echo.
  echo Operação cancelada.
  echo.
  pause
  exit /b 0
)

if exist ".wrangler\state" (
  rmdir /s /q ".wrangler\state"
)

if exist ".wrangler\registry" (
  rmdir /s /q ".wrangler\registry"
)

echo.
echo Banco local zerado com sucesso.
echo.
pause
