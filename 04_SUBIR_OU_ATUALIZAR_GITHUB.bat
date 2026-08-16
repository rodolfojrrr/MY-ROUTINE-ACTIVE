@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
title My Routine Active - Enviar ao GitHub
color 0A

cd /d "%~dp0"

set "REPO_URL=https://github.com/rodolfojrrr/MY-ROUTINE-ACTIVE.git"
set "DEFAULT_COMMIT=Atualizar My Routine Active"

echo.
echo ==============================================================
echo          MY ROUTINE ACTIVE - ENVIO PARA O GITHUB
echo ==============================================================
echo.
echo Repositorio configurado:
echo %REPO_URL%
echo.

where git >nul 2>&1
if errorlevel 1 goto git_missing

if exist ".git" goto repository_ready

echo Inicializando o repositorio local...
git init
if errorlevel 1 goto operation_error

:repository_ready
git branch -M main
if errorlevel 1 goto operation_error

git config --get user.name >nul 2>&1
if not errorlevel 1 goto check_email

echo O Git ainda nao possui um nome configurado nesta pasta.
set "GIT_USER_NAME="
set /p "GIT_USER_NAME=Digite seu nome [rodolfojrrr]: "
if not defined GIT_USER_NAME set "GIT_USER_NAME=rodolfojrrr"
git config user.name "%GIT_USER_NAME%"
if errorlevel 1 goto operation_error

:check_email
git config --get user.email >nul 2>&1
if not errorlevel 1 goto configure_remote

echo.
echo O Git ainda nao possui um e-mail configurado nesta pasta.
set "GIT_USER_EMAIL="
set /p "GIT_USER_EMAIL=Digite seu e-mail do GitHub [rodolfojrrr@users.noreply.github.com]: "
if not defined GIT_USER_EMAIL set "GIT_USER_EMAIL=rodolfojrrr@users.noreply.github.com"
git config user.email "%GIT_USER_EMAIL%"
if errorlevel 1 goto operation_error

:configure_remote
git remote get-url origin >nul 2>&1
if errorlevel 1 goto add_remote

git remote set-url origin "%REPO_URL%"
if errorlevel 1 goto operation_error
goto remote_ready

:add_remote
git remote add origin "%REPO_URL%"
if errorlevel 1 goto operation_error

:remote_ready
echo Adicionando os arquivos...
git add .
if errorlevel 1 goto operation_error

git diff --cached --quiet
if errorlevel 1 goto create_commit

echo.
echo Nenhuma alteracao nova para criar um commit.
goto send_to_github

:create_commit
echo.
set "COMMIT_MESSAGE="
set /p "COMMIT_MESSAGE=Mensagem do commit [%DEFAULT_COMMIT%]: "
if not defined COMMIT_MESSAGE set "COMMIT_MESSAGE=%DEFAULT_COMMIT%"

git commit -m "%COMMIT_MESSAGE%"
if errorlevel 1 goto operation_error

:send_to_github
echo.
echo Enviando para o GitHub...
echo Se uma janela de login aparecer, entre com sua conta do GitHub.
echo.
git push -u origin main
if errorlevel 1 goto push_error

echo.
echo ==============================================================
echo ENVIO CONCLUIDO COM SUCESSO!
echo Repositorio: %REPO_URL%
echo ==============================================================
echo.
pause
exit /b 0

:git_missing
color 0C
echo.
echo ERRO: o Git nao esta instalado ou nao foi encontrado no PATH.
echo Instale o Git para Windows em https://git-scm.com/download/win
echo Depois feche esta janela e execute este BAT novamente.
echo.
pause
exit /b 1

:push_error
color 0E
echo.
echo O commit foi criado, mas o GitHub recusou ou interrompeu o envio.
echo Confira sua autenticacao e se o repositorio esta vazio.
echo Nenhum arquivo local foi perdido.
echo.
pause
exit /b 1

:operation_error
color 0C
echo.
echo O processo foi interrompido por causa do erro exibido acima.
echo Nenhum arquivo local foi apagado.
echo.
pause
exit /b 1
