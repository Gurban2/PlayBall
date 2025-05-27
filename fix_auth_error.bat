@echo off
echo ========================================
echo 🚨 ИСПРАВЛЕНИЕ FIREBASE AUTH ERROR
echo ========================================
echo.

echo ❌ Ошибка: [firebase_auth/configuration-not-found]
echo 🎯 Причина: Authentication не включен в проекте
echo.

echo ⚡ АВТОМАТИЧЕСКОЕ ИСПРАВЛЕНИЕ:
echo.

echo 1. Открываем Firebase Console Authentication...
start https://console.firebase.google.com/project/volleyball-a7d8d/authentication
echo ✅ Браузер открыт

echo.
echo 2. ВЫПОЛНИТЕ ВРУЧНУЮ:
echo    - Нажмите "Начать работу" (Get Started)
echo    - Перейдите в "Sign-in method"
echo    - Включите "Email/Password"
echo    - Нажмите "Save"
echo.

echo 3. Перезапускаем Flutter приложение...
echo.

REM Останавливаем текущий процесс Flutter
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM dart.exe 2>nul

echo 4. Очищаем кэш Flutter...
flutter clean
flutter pub get

echo.
echo 5. Запускаем приложение заново...
start cmd /k "flutter run -d chrome --web-port=3000"

echo.
echo ========================================
echo ✅ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО
echo ========================================
echo.
echo 🔧 ПРОВЕРЬТЕ:
echo 1. Authentication включен в Firebase Console
echo 2. Email/Password метод активен
echo 3. Приложение перезапущено
echo 4. Нажмите "Диагностика Auth" в приложении
echo.
echo 📋 Если ошибка остается - проверьте FIX_AUTH_ERROR.md
echo.
pause 