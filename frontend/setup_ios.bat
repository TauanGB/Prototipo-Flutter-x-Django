@echo off
REM Script de Setup para iOS - Projeto Flutter (Windows/PowerShell)
REM Este script automatiza a preparação do projeto para iOS

echo.
echo ========================================
echo Setup do Projeto Flutter para iOS
echo ========================================
echo.

REM Verificar se está no diretório correto
if not exist "pubspec.yaml" (
    echo [ERRO] Este script deve ser executado na pasta 'frontend' do projeto!
    pause
    exit /b 1
)

echo [OK] Diretorio correto detectado.
echo.

REM 1. Verificar Flutter
echo Verificando instalacao do Flutter...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Flutter nao encontrado! Instale o Flutter primeiro.
    pause
    exit /b 1
)
echo [OK] Flutter instalado!
echo.

REM 2. Limpar builds anteriores
echo Limpando builds anteriores...
call flutter clean
echo [OK] Build limpo!
echo.

REM 3. Obter dependências Flutter
echo Obtendo dependencias do Flutter...
call flutter pub get
echo [OK] Dependencias obtidas!
echo.

REM 4. Verificar Podfile
if not exist "ios\Podfile" (
    echo [ERRO] Podfile nao encontrado em ios\!
    echo [INFO] O Podfile deveria ter sido criado pela analise.
    pause
    exit /b 1
)
echo [OK] Podfile encontrado!
echo.

REM Instruções para Mac
echo ========================================
echo IMPORTANTE:
echo ========================================
echo.
echo Este projeto precisa ser compilado em um Mac para iOS!
echo.
echo No Mac, execute os seguintes comandos:
echo.
echo   cd frontend/ios
echo   pod install
echo   cd ..
echo   open ios/Runner.xcworkspace
echo.
echo Depois configure no Xcode:
echo   1. Signing ^& Capabilities ^> Team
echo   2. Bundle Identifier (unique)
echo   3. Background Modes (ja configurado)
echo.
echo Leia GUIA_RAPIDO_IOS.md para instrucoes detalhadas.
echo.
pause













