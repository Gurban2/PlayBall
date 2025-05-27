@echo off
echo ========================================
echo 🔄 ПЕРЕЗАПУСК ПРОЕКТА FLUTTER
echo ========================================
echo.

echo 1. Останавливаем все процессы Flutter...
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM chrome.exe /FI "WINDOWTITLE eq *localhost*" 2>nul
echo ✅ Процессы остановлены

echo.
echo 2. Очищаем кэш Flutter...
flutter clean
echo ✅ Кэш очищен

echo.
echo 3. Обновляем зависимости...
flutter pub get
echo ✅ Зависимости обновлены

echo.
echo 4. Проверяем статус Flutter...
flutter doctor --verbose
echo ✅ Проверка завершена

echo.
echo 5. Запускаем проект заново...
echo 🚀 Запуск на порту 3000...
start cmd /k "flutter run -d chrome --web-port=3000 --web-hostname=localhost"

echo.
echo ========================================
echo ✅ ПРОЕКТ ПЕРЕЗАПУЩЕН
echo ========================================
echo.
echo 🔧 ПОСЛЕ ЗАПУСКА:
echo 1. Дождитесь полной загрузки приложения
echo 2. Нажмите "Диагностика Auth" (фиолетовая кнопка)
echo 3. Проверьте что Authentication работает
echo 4. Запустите "Полная диагностика"
echo.
echo 📱 Приложение будет доступно по адресу:
echo    http://localhost:3000
echo.
pause 