@echo off
setlocal EnableExtensions DisableDelayedExpansion
title My Routine Active - Enviar ao GitHub
cd /d "%~dp0"
set "REPO_URL=https://github.com/rodolfojrrr/MY-ROUTINE-ACTIVE.git"
set "COMMIT_MSG="
set "NEW_REPO="

where git >nul 2>nul
if errorlevel 1 (
  echo ERRO: Git nao foi encontrado no PATH.
  echo Instale o Git para Windows e abra este BAT novamente.
  pause
  exit /b 1
)

if not exist ".git" (
  echo Inicializando o repositorio local...
  git init
  if errorlevel 1 goto :erro
  set "NEW_REPO=1"
)

git remote get-url origin >nul 2>nul
if errorlevel 1 (
  git remote add origin "%REPO_URL%"
) else (
  git remote set-url origin "%REPO_URL%"
)
if errorlevel 1 goto :erro

if defined NEW_REPO (
  echo Verificando o historico que ja existe no GitHub...
  git fetch origin main
  if not errorlevel 1 git reset --mixed FETCH_HEAD
)

git branch -M main
if errorlevel 1 goto :erro

git config user.name >nul 2>nul
if errorlevel 1 git config user.name "Rodolfo Junior"
git config user.email >nul 2>nul
if errorlevel 1 git config user.email "rodolfojrrr@users.noreply.github.com"

git add -A
if errorlevel 1 goto :erro

git diff --cached --quiet
if not errorlevel 1 goto :sem_alteracoes

set /p "COMMIT_MSG=Mensagem do commit [Atualizar My Routine Active]: "
if not defined COMMIT_MSG set "COMMIT_MSG=Atualizar My Routine Active"
git commit -m "%COMMIT_MSG%"
if errorlevel 1 goto :erro

:enviar
echo.
echo Enviando para %REPO_URL%...
git push -u origin main
if errorlevel 1 goto :erro
echo.
echo Projeto enviado com sucesso.
echo Abra a aba Actions do GitHub para baixar o APK e o pacote Windows.
pause
exit /b 0

:sem_alteracoes
echo Nenhuma alteracao nova para criar commit.
goto :enviar

:erro
echo.
echo O processo foi interrompido por causa do erro exibido acima.
pause
exit /b 1
