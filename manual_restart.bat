@echo off
echo ========================================
echo 🔄 РУЧНОЙ ПЕРЕЗАПУСК ПРОЕКТА
echo ========================================
echo.

echo 1. Останавливаем процессы...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
echo ✅ Процессы остановлены

echo.
echo ========================================
echo ⚠️  ВЫПОЛНИТЕ ВРУЧНУЮ:
echo ========================================
echo.
echo 1. Откройте новый терминал (Command Prompt или PowerShell)
echo 2. Перейдите в папку проекта:
echo    cd "%~dp0"
echo.
echo 3. Выполните команды:
echo    flutter clean
echo    flutter pub get
echo    flutter run -d chrome --web-port=3000
echo.
echo ========================================
echo 🎯 ПОСЛЕ ЗАПУСКА:
echo ========================================
echo.
echo 1. Дождитесь загрузки приложения
echo 2. Нажмите "Диагностика Auth" (фиолетовая кнопка)
echo 3. Проверьте: ✅ Authentication API доступен
echo 4. Запустите "Полная диагностика"
echo.
echo 📱 Приложение: http://localhost:3000
echo.
pause 