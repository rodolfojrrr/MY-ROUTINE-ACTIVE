@echo off
setlocal
chcp 65001 >nul
title My Routine Active - Instalar dependências
cd /d "%~dp0"

where node >nul 2>&1
if errorlevel 1 (
  echo.
  echo ERRO: Node.js não foi encontrado.
  echo Instale o Node.js 22 LTS em https://nodejs.org/
  echo.
  pause
  exit /b 1
)

for /f "tokens=1 delims=." %%V in ('node -p "process.versions.node"') do set "NODE_MAJOR=%%V"
if %NODE_MAJOR% LSS 22 (
  echo.
  echo ERRO: este projeto exige Node.js 22 ou superior.
  node --version
  echo.
  pause
  exit /b 1
)

echo.
echo Instalando dependências do My Routine Active...
echo.
call npm ci
if errorlevel 1 (
  echo.
  echo A instalação não foi concluída. Confira sua internet e tente novamente.
  echo.
  pause
  exit /b 1
)

echo.
echo Dependências instaladas com sucesso.
echo.
pause
