@echo off
echo ========================================
echo    Проверка настройки Firebase
echo ========================================
echo.

echo 1. Проверка Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter не найден! Установите Flutter и добавьте в PATH.
    echo 📖 Инструкция: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)
echo ✅ Flutter установлен

echo.
echo 2. Проверка зависимостей...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Ошибка установки зависимостей
    pause
    exit /b 1
)
echo ✅ Зависимости установлены

echo.
echo 3. Проверка конфигурационных файлов...

if exist "android\app\google-services.json" (
    echo ✅ google-services.json найден
) else (
    echo ⚠️  google-services.json не найден в android\app\
    echo    Скачайте файл из Firebase Console
)

if exist "lib\firebase_options.dart" (
    echo ✅ firebase_options.dart найден
) else (
    echo ❌ firebase_options.dart не найден
)

echo.
echo 4. Проверка структуры проекта...

if exist "lib\services\auth_service.dart" (
    echo ✅ AuthService найден
) else (
    echo ❌ AuthService не найден
)

if exist "lib\services\firestore_service.dart" (
    echo ✅ FirestoreService найден
) else (
    echo ❌ FirestoreService не найден
)

echo.
echo 5. Анализ кода...
flutter analyze
if %errorlevel% neq 0 (
    echo ⚠️  Найдены проблемы в коде
) else (
    echo ✅ Анализ кода прошел успешно
)

echo.
echo ========================================
echo    Проверка завершена!
echo ========================================
echo.
echo 🚀 Для запуска приложения используйте:
echo    flutter run
echo.
echo 🧪 Для тестирования Firebase:
echo    1. Запустите приложение
echo    2. Нажмите "Тестировать Firebase"
echo.
pause 