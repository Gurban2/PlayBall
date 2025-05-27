@echo off
echo ========================================
echo Развертывание правил безопасности Firestore
echo ========================================

echo.
echo Проверяем наличие Firebase CLI...
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI не установлен!
    echo.
    echo Установите Firebase CLI:
    echo npm install -g firebase-tools
    echo.
    echo Или скачайте с: https://firebase.google.com/docs/cli
    pause
    exit /b 1
)

echo ✅ Firebase CLI найден

echo.
echo Проверяем авторизацию...
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Вы не авторизованы в Firebase!
    echo.
    echo Выполните авторизацию:
    firebase login
    pause
    exit /b 1
)

echo ✅ Авторизация в порядке

echo.
echo Развертываем правила Firestore...
firebase deploy --only firestore:rules --project volleyball-a7d8d

if %errorlevel% equ 0 (
    echo.
    echo ✅ Правила Firestore успешно развернуты!
    echo.
    echo Теперь попробуйте запустить приложение снова.
) else (
    echo.
    echo ❌ Ошибка при развертывании правил!
    echo.
    echo Возможные причины:
    echo - Неправильный ID проекта
    echo - Нет прав на изменение проекта
    echo - Синтаксическая ошибка в правилах
)

echo.
pause 