@echo off
echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo =========================================

:: Получаем текущую дату и время
for /f "delims=" %%a in ('powershell -Command "Get-Date -Format 'dd.MM.yyyy HH:mm:ss'"') do set "timestamp=%%a"

:: Получаем версию для изображений (timestamp)
for /f "delims=" %%a in ('powershell -Command "Get-Date -Format 'yyyyMMddHHmmss'"') do set "version=%%a"

echo Текущее время: %timestamp%
echo Версия изображений: %version%
echo.

:: Обновляем версии всех изображений в HTML файле
echo 🔄 Обновление версий изображений...
powershell -ExecutionPolicy Bypass -File update-images.ps1 -version %version%
echo.

:: Проверяем, инициализирован ли git
if not exist ".git" (
    echo Инициализация Git репозитория...
    git init
    git remote add origin https://github.com/Dragonut8686/osq-email-assets.git
    echo.
)

:: Добавляем все файлы (включая структуру папок)
echo Добавление файлов...
git add .

:: Проверяем есть ли изменения
git diff --staged --quiet
if %errorlevel% equ 0 (
    echo Нет изменений для коммита.
    pause
    exit /b
)

:: Делаем коммит с автоматическим сообщением
echo Создание коммита...
git commit -m "Assets update %timestamp%"

:: Отправляем на GitHub
echo Отправка на GitHub...
git branch -M main
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   ✅ Успешно загружено на GitHub!
    echo ========================================
    echo.
    echo 🎯 Все изображения обновлены с версией: %version%
    echo 🔄 Кеш изображений сброшен - новые версии будут загружены
    echo.
    echo Ваши ссылки для текущего проекта 2025-07-25-osq-email:
    echo 📁 Шрифты: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/fonts/
    echo 🖼️ Изображения: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/
    echo.
    echo Для других проектов просто замените дату в URL
    echo.
) else (
    echo.
    echo ❌ Ошибка при загрузке!
    echo Проверьте подключение к интернету и права доступа.
    echo.
)

pause 