@echo off
setlocal
title My Routine Active - Validar
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 goto :sem_flutter
flutter pub get
if errorlevel 1 goto :erro
flutter analyze
if errorlevel 1 goto :erro
flutter test
if errorlevel 1 goto :erro

echo.
echo Analise e testes concluidos com sucesso.
pause
exit /b 0

:sem_flutter
echo ERRO: Flutter nao foi encontrado. Execute 01_PREPARAR_PROJETO.bat.
pause
exit /b 1

:erro
echo.
echo A validacao encontrou um problema. Leia a mensagem acima.
pause
exit /b 1

