@echo off
chcp 65001 >nul
echo ========================================
echo 🚫 Исправление ошибки 400 Bad Request
echo ========================================

echo.
echo 🚨 Обнаружена ошибка 400 Bad Request:
echo https://firestore.googleapis.com/google.firestore.v1.Firestore/Write/channel
echo 400 (Bad Request)
echo.

echo 🔍 Диагностика проблемы...
echo.

:: Проверка существования проекта
echo 1️⃣ Проверка конфигурации Firebase...
if exist "lib\firebase_options.dart" (
    echo ✅ Файл firebase_options.dart найден
    findstr "volleyball-a7d8d" "lib\firebase_options.dart" >nul
    if %errorlevel% equ 0 (
        echo ✅ Project ID: volleyball-a7d8d
    ) else (
        echo ❌ Project ID не найден в конфигурации
    )
) else (
    echo ❌ Файл firebase_options.dart не найден!
    pause
    exit /b 1
)

echo.
echo 2️⃣ Проверка правил Firestore...
if exist "firestore.rules" (
    echo ✅ Файл правил найден
    findstr "allow read, write: if true" "firestore.rules" >nul
    if %errorlevel% equ 0 (
        echo ✅ Правила разрешают доступ
    ) else (
        echo ⚠️ Правила могут блокировать доступ
    )
) else (
    echo ❌ Файл правил не найден - создаем...
    echo rules_version = '2'; > firestore.rules
    echo service cloud.firestore { >> firestore.rules
    echo   match /databases/{database}/documents { >> firestore.rules
    echo     match /{document=**} { >> firestore.rules
    echo       allow read, write: if true; >> firestore.rules
    echo     } >> firestore.rules
    echo   } >> firestore.rules
    echo } >> firestore.rules
    echo ✅ Правила созданы
)

echo.
echo 🛠️ Применение исправлений...

echo.
echo 3️⃣ Развертывание правил Firestore...
if exist "firebase.json" (
    echo ℹ️ Попытка развертывания правил...
    firebase deploy --only firestore:rules 2>nul
    if %errorlevel% equ 0 (
        echo ✅ Правила развернуты успешно
    ) else (
        echo ⚠️ Не удалось развернуть правила автоматически
        echo 💡 Разверните правила вручную в Firebase Console:
        echo    1. Откройте https://console.firebase.google.com/
        echo    2. Выберите проект volleyball-a7d8d
        echo    3. Перейдите в Firestore Database → Rules
        echo    4. Замените правила на:
        echo.
        echo    rules_version = '2';
        echo    service cloud.firestore {
        echo      match /databases/{database}/documents {
        echo        match /{document=**} {
        echo          allow read, write: if true;
        echo        }
        echo      }
        echo    }
        echo.
    )
) else (
    echo ⚠️ firebase.json не найден
    echo 💡 Разверните правила вручную в Firebase Console
)

echo.
echo 4️⃣ Проверка статуса Firestore...
echo ℹ️ Убедитесь, что Firestore включен в проекте:
echo 1. Откройте https://console.firebase.google.com/project/volleyball-a7d8d/firestore
echo 2. Если Firestore не создан, нажмите "Создать базу данных"
echo 3. Выберите режим "Тестирование" для начала
echo 4. Выберите регион (рекомендуется europe-west1)

echo.
echo 5️⃣ Очистка кэша и перезапуск...
"/c/Users/USER/OneDrive/Desktop/flutter/bin/flutter" clean >nul 2>&1
"/c/Users/USER/OneDrive/Desktop/flutter/bin/flutter" pub get >nul 2>&1
echo ✅ Кэш очищен

echo.
echo 🚀 Запуск приложения с исправлениями...
echo.
echo Приложение будет запущено с:
echo - Улучшенной обработкой ошибок 400
echo - Диагностикой конфигурации Firebase
echo - Проверкой доступности API
echo.

echo После запуска:
echo 1. Откройте "Тестировать Firebase"
echo 2. Нажмите "Диагностика 400" для подробной проверки
echo 3. Если ошибка остается, нажмите "Полная диагностика"
echo 4. Проверьте логи в консоли браузера (F12)
echo.

echo Запуск через 3 секунды...
timeout /t 3 /nobreak >nul

:: Запуск с улучшенными параметрами для диагностики
"/c/Users/USER/OneDrive/Desktop/flutter/bin/flutter" run -d chrome --web-port=8080 --web-browser-flag="--disable-web-security" --web-browser-flag="--disable-features=VizDisplayCompositor" --verbose

echo.
echo 📊 Результат запуска:
if %errorlevel% equ 0 (
    echo ✅ Приложение запущено успешно
) else (
    echo ❌ Ошибка при запуске приложения
)

echo.
echo 🔧 Если ошибка 400 остается:
echo.
echo 1. КРИТИЧНО: Проверьте, что Firestore включен в проекте
echo    https://console.firebase.google.com/project/volleyball-a7d8d/firestore
echo.
echo 2. Проверьте правильность Project ID:
echo    - Должен быть: volleyball-a7d8d
echo    - Проверьте в lib/firebase_options.dart
echo.
echo 3. Убедитесь, что API ключи корректны:
echo    - Скачайте новую конфигурацию из Firebase Console
echo    - Обновите firebase_options.dart
echo.
echo 4. Проверьте статус Firebase:
echo    https://status.firebase.google.com/
echo.
echo 5. Попробуйте создать новый проект Firebase для тестирования
echo.
pause 