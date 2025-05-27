@echo off
REM Удобные команды Flutter для проекта

set FLUTTER_PATH="C:\Users\USER\OneDrive\Desktop\flutter\bin\flutter"

echo ========================================
echo 🚀 КОМАНДЫ FLUTTER
echo ========================================
echo.

if "%1"=="clean" (
    echo 🧹 Очистка проекта...
    %FLUTTER_PATH% clean
    goto end
)

if "%1"=="get" (
    echo 📦 Обновление зависимостей...
    %FLUTTER_PATH% pub get
    goto end
)

if "%1"=="run" (
    echo 🚀 Запуск приложения...
    %FLUTTER_PATH% run -d chrome --web-port=3000
    goto end
)

if "%1"=="restart" (
    echo 🔄 Полный перезапуск...
    taskkill /F /IM dart.exe 2>nul
    taskkill /F /IM flutter.exe 2>nul
    %FLUTTER_PATH% clean
    %FLUTTER_PATH% pub get
    %FLUTTER_PATH% run -d chrome --web-port=3000
    goto end
)

if "%1"=="doctor" (
    echo 🩺 Диагностика Flutter...
    %FLUTTER_PATH% doctor -v
    goto end
)

echo ========================================
echo 📋 ДОСТУПНЫЕ КОМАНДЫ:
echo ========================================
echo.
echo flutter_commands clean    - Очистить кэш
echo flutter_commands get      - Обновить зависимости  
echo flutter_commands run      - Запустить приложение
echo flutter_commands restart  - Полный перезапуск
echo flutter_commands doctor   - Диагностика Flutter
echo.

:end 