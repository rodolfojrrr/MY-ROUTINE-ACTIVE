@echo off
setlocal
title My Routine Active - Limpar arquivos de compilacao
cd /d "%~dp0"

echo Este comando remove somente arquivos de compilacao.
echo Seus dados locais do aplicativo NAO serao apagados.
flutter clean
if errorlevel 1 (
  echo Falha ao limpar o projeto.
  pause
  exit /b 1
)
echo Limpeza concluida.
pause

