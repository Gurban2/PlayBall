@echo off
echo 🔄 БЫСТРЫЙ ПЕРЕЗАПУСК...

REM Останавливаем процессы
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM dart.exe 2>nul

REM Очищаем и обновляем
flutter clean
flutter pub get

REM Запускаем
echo 🚀 Запуск приложения...
flutter run -d chrome --web-port=3000 