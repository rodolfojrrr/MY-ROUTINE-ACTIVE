@echo off
setlocal
chcp 65001 >nul
title My Routine Active - Validar projeto
cd /d "%~dp0"

if not exist "node_modules" (
  call "01_INSTALAR_DEPENDENCIAS.bat"
  if errorlevel 1 exit /b 1
)

set "BASH_EXE="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles(x86)%\Git\bin\bash.exe"

if not defined BASH_EXE (
  where bash >nul 2>&1
  if not errorlevel 1 set "BASH_EXE=bash"
)

if not defined BASH_EXE (
  echo.
  echo ERRO: Git Bash não foi encontrado.
  echo Instale o Git para Windows em https://git-scm.com/download/win
  echo.
  pause
  exit /b 1
)

echo.
echo Executando lint, compilação e testes...
echo.
"%BASH_EXE%" -lc "npm run lint && npm test"
if errorlevel 1 (
  echo.
  echo A validação encontrou um erro. Não envie ao GitHub antes de corrigir.
  echo.
  pause
  exit /b 1
)

echo.
echo Projeto aprovado em todas as validações.
echo.
pause
