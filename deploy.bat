@echo off
chcp 65001 >nul

echo =========================================
echo    OSQ Email Assets - Auto Deploy
echo =========================================

REM Получаем текущую дату и время
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "date=%%a %%b %%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "time=%%a:%%b"
set "timestamp=%date% %time%"

echo Текущее время: %timestamp%
echo.

REM Проверяем, инициализирован ли git
if not exist ".git" (
    echo Инициализация Git репозитория...
    git init
    git remote add origin https://github.com/Dragonut8686/osq-email-assets.git
    echo.
)

REM Добавляем все файлы (включая структуру папок)
echo Добавление файлов...
git add .

REM Проверяем есть ли изменения
git diff --staged --quiet
if %errorlevel% equ 0 (
    echo Нет изменений для коммита.
    pause
    exit /b 0
)

REM Делаем коммит с автоматическим сообщением
echo Создание коммита...
git commit -m "Assets update %timestamp%"

REM Отправляем на GitHub
echo Отправка на GitHub...
git branch -M main
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    ✅ Успешно загружено на GitHub!
    echo ========================================
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