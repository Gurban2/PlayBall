@echo off
chcp 65001 >nul
echo ========================================
echo 🏐 PlayBall - Запуск с диагностикой
echo ========================================

echo.
echo 🔍 Проверяем системные требования...

:: Проверка Flutter
echo Проверяем Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter не найден!
    echo Установите Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo ✅ Flutter найден

:: Проверка Chrome
echo Проверяем Chrome...
where chrome >nul 2>&1
if %errorlevel% neq 0 (
    where "C:\Program Files\Google\Chrome\Application\chrome.exe" >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Chrome не найден!
        echo Установите Google Chrome для веб-разработки
        pause
        exit /b 1
    )
)
echo ✅ Chrome найден

:: Проверка интернет-соединения
echo Проверяем интернет-соединение...
ping -n 1 google.com >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ Проблемы с интернет-соединением
    echo Firebase может работать некорректно
) else (
    echo ✅ Интернет-соединение работает
)

echo.
echo 🔧 Подготовка проекта...

:: Очистка кэша
echo Очищаем кэш Flutter...
flutter clean >nul 2>&1

:: Получение зависимостей
echo Получаем зависимости...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Ошибка при получении зависимостей!
    pause
    exit /b 1
)

echo.
echo 🔥 Проверяем конфигурацию Firebase...

:: Проверка файлов конфигурации
if not exist "lib\firebase_options.dart" (
    echo ❌ Файл firebase_options.dart не найден!
    echo Выполните настройку Firebase
    pause
    exit /b 1
)
echo ✅ firebase_options.dart найден

if not exist "web\index.html" (
    echo ❌ Файл web\index.html не найден!
    pause
    exit /b 1
)
echo ✅ web\index.html найден

echo.
echo 🌐 Проверяем доступность Firebase...
echo Пытаемся подключиться к Firebase...

:: Проверка доступности Firebase
ping -n 1 firestore.googleapis.com >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ Проблемы с доступом к Firebase
    echo Проверьте интернет-соединение и настройки брандмауэра
) else (
    echo ✅ Firebase доступен
)

echo.
echo 🚀 Запускаем приложение...
echo.
echo Приложение будет доступно по адресу: http://localhost:8080
echo.
echo Для тестирования Firebase:
echo 1. Откройте приложение в браузере
echo 2. Нажмите кнопку "Тестировать Firebase"
echo 3. Выберите "Полная диагностика"
echo.
echo Для остановки приложения нажмите Ctrl+C
echo.

:: Запуск приложения
flutter run -d chrome --web-port=8080 --web-browser-flag="--disable-web-security"

echo.
echo 📊 Приложение завершено
echo.
echo Если возникли проблемы с Firebase:
echo 1. Проверьте правила безопасности в Firebase Console
echo 2. Убедитесь, что проект volleyball-a7d8d существует
echo 3. Проверьте настройки API ключей
echo 4. Запустите deploy_firestore_rules.bat для обновления правил
echo.
pause 