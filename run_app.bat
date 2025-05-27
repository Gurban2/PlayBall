@echo off
echo ========================================
echo    Запуск PlayBall с Firebase
echo ========================================
echo.

set FLUTTER_PATH=C:\Users\USER\OneDrive\Desktop\flutter\bin\flutter

echo 🔥 Проверка Firebase настройки...
if exist "lib\firebase_options.dart" (
    echo ✅ Firebase конфигурация найдена
) else (
    echo ❌ Firebase конфигурация не найдена!
    pause
    exit /b 1
)

echo.
echo 📦 Установка зависимостей...
"%FLUTTER_PATH%" pub get
if %errorlevel% neq 0 (
    echo ❌ Ошибка установки зависимостей
    pause
    exit /b 1
)

echo.
echo 🚀 Выберите платформу для запуска:
echo 1. Chrome (Web) - рекомендуется для тестирования Firebase
echo 2. Windows (Desktop)
echo 3. Android (если подключено устройство)
echo.
set /p choice="Введите номер (1-3): "

if "%choice%"=="1" (
    echo.
    echo 🌐 Запуск в Chrome...
    "%FLUTTER_PATH%" run -d chrome
) else if "%choice%"=="2" (
    echo.
    echo 🖥️ Запуск на Windows...
    "%FLUTTER_PATH%" run -d windows
) else if "%choice%"=="3" (
    echo.
    echo 📱 Запуск на Android...
    "%FLUTTER_PATH%" run
) else (
    echo.
    echo 🌐 Запуск в Chrome по умолчанию...
    "%FLUTTER_PATH%" run -d chrome
)

echo.
echo ========================================
echo    Приложение запущено!
echo ========================================
echo.
echo 🧪 Для тестирования Firebase:
echo    1. Нажмите "Тестировать Firebase" в приложении
echo    2. Проверьте все функции подключения
echo.
pause 