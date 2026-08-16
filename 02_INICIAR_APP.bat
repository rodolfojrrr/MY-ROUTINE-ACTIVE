@echo off
setlocal
chcp 65001 >nul
title My Routine Active - Desenvolvimento
cd /d "%~dp0"

if not exist "node_modules" (
  call "01_INSTALAR_DEPENDENCIAS.bat"
  if errorlevel 1 exit /b 1
)

set "WRANGLER_LOG_PATH=.wrangler\wrangler.log"

echo.
echo Iniciando o My Routine Active...
echo Para encerrar, pressione CTRL+C.
echo.
call npx vite --host 127.0.0.1
