@echo off
chcp 65001 >nul
echo ========================================
echo 🔄 Переключение версий index.html
echo ========================================

echo.
echo Доступные версии:
echo 1. Стабильная (текущая) - Firebase v8, стандартные токены
echo 2. Современная - Firebase v9, улучшенная обработка
echo 3. Показать текущую версию
echo 4. Создать резервную копию
echo.

set /p choice="Выберите действие (1-4): "

if "%choice%"=="1" (
    echo.
    echo 📁 Переключение на стабильную версию...
    if exist "web\index_backup.html" (
        copy "web\index_backup.html" "web\index.html" >nul
        echo ✅ Переключено на стабильную версию
    ) else (
        echo ℹ️ Стабильная версия уже используется
    )
) else if "%choice%"=="2" (
    echo.
    echo 📁 Переключение на современную версию...
    if not exist "web\index_backup.html" (
        copy "web\index.html" "web\index_backup.html" >nul
        echo 💾 Создана резервная копия текущей версии
    )
    copy "web\index_modern.html" "web\index.html" >nul
    echo ✅ Переключено на современную версию
    echo.
    echo ⚠️ Внимание: Современная версия может требовать дополнительной настройки
) else if "%choice%"=="3" (
    echo.
    echo 📋 Анализ текущей версии...
    findstr "firebase-app-compat" "web\index.html" >nul
    if %errorlevel% equ 0 (
        echo 🆕 Используется современная версия (Firebase v9)
    ) else (
        findstr "firebase-app.js" "web\index.html" >nul
        if %errorlevel% equ 0 (
            echo 🔒 Используется стабильная версия (Firebase v8)
        ) else (
            echo ❓ Неизвестная версия
        )
    )
    
    findstr "loadEntrypoint" "web\index.html" >nul
    if %errorlevel% equ 0 (
        echo 📱 Flutter: loadEntrypoint (стабильный)
    ) else (
        echo 📱 Flutter: load (современный)
    )
) else if "%choice%"=="4" (
    echo.
    echo 💾 Создание резервной копии...
    copy "web\index.html" "web\index_backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%.html" >nul
    echo ✅ Резервная копия создана
) else (
    echo ❌ Неверный выбор
)

echo.
echo 📝 Рекомендации:
echo - Стабильная версия: для продакшена и отладки
echo - Современная версия: для разработки с новыми функциями
echo - Всегда создавайте резервные копии перед переключением
echo.
pause 