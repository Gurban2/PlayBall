@echo off
chcp 65001 >nul
echo ========================================
echo 🔧 Исправление ошибок WebChannel Firebase
echo ========================================

echo.
echo 🚨 Обнаружена ошибка WebChannel:
echo [2025-05-26T15:15:20.677Z] @firebase/firestore: Firestore (11.7.0): 
echo WebChannelConnection RPC 'Write' stream 0x22098801 transport errored
echo.

echo 🔍 Диагностика проблемы...
echo.

:: Проверка сетевого подключения
echo 1️⃣ Проверка подключения к Firebase...
ping -n 1 firestore.googleapis.com >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Нет подключения к Firebase
    echo 💡 Проверьте интернет-соединение
) else (
    echo ✅ Подключение к Firebase доступно
)

echo.
echo 2️⃣ Проверка процессов Flutter...
tasklist /FI "IMAGENAME eq flutter.exe" 2>nul | find /I "flutter.exe" >nul
if %errorlevel% equ 0 (
    echo ⚠️ Обнаружены запущенные процессы Flutter
    echo 💡 Рекомендуется перезапустить приложение
) else (
    echo ✅ Нет конфликтующих процессов Flutter
)

echo.
echo 🛠️ Применение исправлений...

echo.
echo 3️⃣ Очистка кэша Flutter...
"/c/Users/USER/OneDrive/Desktop/flutter/bin/flutter" clean >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Кэш Flutter очищен
) else (
    echo ❌ Ошибка при очистке кэша
)

echo.
echo 4️⃣ Обновление зависимостей...
"/c/Users/USER/OneDrive/Desktop/flutter/bin/flutter" pub get >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Зависимости обновлены
) else (
    echo ❌ Ошибка при обновлении зависимостей
)

echo.
echo 5️⃣ Проверка версии Firebase SDK в web/index.html...
findstr "firebase-app.js" "web\index.html" >nul
if %errorlevel% equ 0 (
    echo ✅ Используется стабильная версия Firebase SDK
) else (
    echo ⚠️ Возможно используется нестабильная версия SDK
)

echo.
echo 🚀 Запуск приложения с исправлениями...
echo.
echo Приложение будет запущено с:
echo - Отключенной безопасностью веб-браузера
echo - Портом 8080
echo - Улучшенными настройками Firestore
echo.

echo Для тестирования исправлений:
echo 1. Дождитесь загрузки приложения
echo 2. Откройте "Тестировать Firebase"
echo 3. Нажмите "Сброс соединения" если проблемы остались
echo 4. Запустите "Полная диагностика"
echo.

echo Запуск через 3 секунды...
timeout /t 3 /nobreak >nul

:: Запуск с улучшенными параметрами
"/c/Users/USER/OneDrive/Desktop/flutter/bin/flutter" run -d chrome --web-port=8080 --web-browser-flag="--disable-web-security" --web-browser-flag="--disable-features=VizDisplayCompositor"

echo.
echo 📊 Результат запуска:
if %errorlevel% equ 0 (
    echo ✅ Приложение запущено успешно
) else (
    echo ❌ Ошибка при запуске приложения
)

echo.
echo 🔧 Дополнительные рекомендации:
echo.
echo Если ошибки WebChannel остались:
echo 1. Очистите кэш браузера (Ctrl+Shift+Delete)
echo 2. Попробуйте другой браузер (Firefox, Edge)
echo 3. Отключите VPN если используется
echo 4. Проверьте настройки брандмауэра
echo 5. Перезагрузите роутер
echo.
echo Для переключения на современную версию Firebase:
echo switch_index_version.bat
echo.
echo Для развертывания правил Firestore:
echo deploy_firestore_rules.bat
echo.
pause 