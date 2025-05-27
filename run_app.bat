@echo off
chcp 65001 >nul
echo ========================================
echo 🏐 PlayBall - Запуск приложения
echo ========================================

echo.
echo 🔧 Подготовка проекта...
flutter pub get

echo.
echo 🚀 Запускаем приложение...
echo Приложение будет доступно в браузере
echo Для остановки нажмите Ctrl+C
echo.

flutter run -d chrome

pause 