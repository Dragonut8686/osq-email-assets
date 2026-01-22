@echo off
chcp 65001 >nul

echo =========================================
echo    OSQ Email Assets - Auto Update
echo =========================================
echo.

REM Проверяем наличие git
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Git не найден в PATH. Установите git или добавьте его в переменные среды.
    pause
    exit /b 1
)

REM Проверяем, инициализирован ли репозиторий
if not exist ".git" (
    echo ⚠️ Репозиторий не инициализирован.
    echo Попробуйте сначала запустить deploy.bat или выполните git clone.
    pause
    exit /b 1
)

echo Получение последних изменений с GitHub...
echo.

REM Сначала скачиваем обновления
git fetch origin

REM Принудительно сбрасываем локальную ветку на состояние origin/main
REM ВНИМАНИЕ: Это уничтожит все локальные изменения в отслеживаемых файлах!
echo Принудительное обновление до версии GitHub...
git reset --hard origin/main

if %errorlevel% neq 0 (
    echo.
    echo ❌ Ошибка при обновлении.
    echo Проверьте соединение с интернетом или права доступа.
) else (
    echo.
    echo ✅ Обновление успешно завершено! Локальная версия идентична GitHub.
)

echo.
echo =========================================
echo.
pause
