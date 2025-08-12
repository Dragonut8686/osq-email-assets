@echo off
chcp 65001 >nul

echo =========================================
echo    OSQ Email Assets - Auto Deploy
echo =========================================

REM =====================
REM Аргументы скрипта
REM %1 - папка проекта (например: 2025-08-12-osq-podpis)
REM %2 - относительный путь к файлу внутри папки проекта (например: images/podpis-logo-grey.png)
REM =====================
set "PROJECT_DIR=%~1"
set "REL_FILE=%~2"

REM Если папка проекта не указана, выбираем самую новую директорию, начинающуюся на 20
if "%PROJECT_DIR%"=="" (
    for /f "delims=" %%d in ('dir /ad /o-d /b 20*') do (
        set "PROJECT_DIR=%%d"
        goto :projSelected
    )
    echo Не найдены директории вида 20* в корне проекта.
    echo Укажите папку проекта первым параметром. Пример:
    echo    deploy.bat "2025-08-12-osq-podpis" "images/podpis-logo-grey.png"
    pause
    exit /b 1
)

:projSelected

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
set "NO_CHANGES=0"
if %errorlevel% equ 0 (
    set "NO_CHANGES=1"
    echo Нет изменений для коммита. Пропускаю шаги commit/push.
)

if "%NO_CHANGES%"=="0" (
    REM Делаем коммит с автоматическим сообщением
    echo Создание коммита...
    git commit -m "Assets update %timestamp%"

    REM Отправляем на GitHub
    echo Отправка на GitHub...
    git branch -M main
    git push -u origin main
)

echo.
echo ========================================
if "%NO_CHANGES%"=="0" (
    echo    ✅ Успешно загружено на GitHub!
) else (
    echo    ℹ️ Ссылки сгенерированы. Новых файлов для загрузки не было.
)
echo ========================================
echo.

set "BASE_URL=https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/%PROJECT_DIR%"
set "RAW_BASE=https://raw.githubusercontent.com/Dragonut8686/osq-email-assets/main/%PROJECT_DIR%"

echo Выбранный проект: %PROJECT_DIR%
echo 📁 Шрифты: %BASE_URL%/fonts/
echo 🖼️ Изображения: %BASE_URL%/images/

if not "%REL_FILE%"=="" (
    echo 🔗 Прямая ссылка ^(CDN^) на файл: %BASE_URL%/%REL_FILE%
    echo 🔗 Альтернативная ^(raw.githubusercontent^) : %RAW_BASE%/%REL_FILE%
)

echo.
echo Подсказка: можно передать параметры, например:
echo    deploy.bat "2025-08-12-osq-podpis" "images/podpis-logo-grey.png"
echo.

pause 