@echo off
setlocal EnableExtensions DisableDelayedExpansion
title My Routine Active - Assinatura Android fixa
cd /d "%~dp0"

where keytool >nul 2>nul
if errorlevel 1 (
  echo ERRO: keytool nao foi encontrado.
  echo Instale o Android Studio ou um JDK 17 e tente novamente.
  pause
  exit /b 1
)

set "KEYSTORE=android\app\mra-release.jks"
set "ALIAS=my-routine-active"

if exist "%KEYSTORE%" (
  echo Ja existe uma chave em %KEYSTORE%.
  echo Nao gere outra chave se ja publicou APKs assinados com ela.
  pause
  exit /b 0
)

set /p "PASS=Crie uma senha forte para a assinatura: "
if not defined PASS (
  echo Senha vazia. Operacao cancelada.
  pause
  exit /b 1
)

keytool -genkeypair -v -keystore "%KEYSTORE%" -storepass "%PASS%" -keypass "%PASS%" -alias "%ALIAS%" -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=My Routine Active, OU=Personal, O=Rodolfo Junior, L=Local, ST=Local, C=BR"
if errorlevel 1 goto :erro

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes('%KEYSTORE%'))"`) do set "B64=%%A"

> ASSINATURA_ANDROID_SECRETS.txt echo Configure estes quatro Secrets no GitHub em Settings ^> Secrets and variables ^> Actions:
>> ASSINATURA_ANDROID_SECRETS.txt echo.
>> ASSINATURA_ANDROID_SECRETS.txt echo MRA_KEYSTORE_B64=%B64%
>> ASSINATURA_ANDROID_SECRETS.txt echo MRA_KEYSTORE_PASSWORD=%PASS%
>> ASSINATURA_ANDROID_SECRETS.txt echo MRA_KEY_ALIAS=%ALIAS%
>> ASSINATURA_ANDROID_SECRETS.txt echo MRA_KEY_PASSWORD=%PASS%
>> ASSINATURA_ANDROID_SECRETS.txt echo.
>> ASSINATURA_ANDROID_SECRETS.txt echo IMPORTANTE: guarde a chave mra-release.jks e a senha em local seguro. Nunca gere outra para o mesmo aplicativo.

echo.
echo Chave criada com sucesso.
echo Abra ASSINATURA_ANDROID_SECRETS.txt e cadastre os quatro valores como Secrets no GitHub.
echo Depois disso, os APKs do Actions terao a mesma assinatura em todas as atualizacoes.
pause
exit /b 0

:erro
echo Falha ao gerar a chave.
pause
exit /b 1
