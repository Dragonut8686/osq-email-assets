@echo off
setlocal

REM ================================
REM OSQ Email Assets - Auto Deploy
REM ================================

:: Получаем timestamp для cache-bust и коммита
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "TIMESTAMP=%%a"

echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo   Timestamp: %TIMESTAMP%
echo =========================================
echo.

:: Проверяем, есть ли git-репозиторий
if not exist ".git" (
    echo [INFO] .git не найден. Инициализируем репозиторий...
    git init
)

:: Проверяем, задан ли origin
git remote | findstr /i "^origin$" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Добавляем remote origin...
    git remote add origin https://github.com/Dragonut8686/osq-email-assets.git
) else (
    echo [INFO] Remote origin уже существует.
)

:: Обновляем информацию с удалённого
echo [INFO] Получаем обновления из origin...
git fetch origin

:: Переключаемся на main (создаём и привязываем если нужно)
git rev-parse --verify main >nul 2>&1
if errorlevel 1 (
    echo [INFO] Ветка main отсутствует локально, создаём отслеживаемую из origin/main...
    git switch -c main origin/main 2>nul || git switch -c main
) else (
    git switch main
    echo [INFO] Обновляем локальную main из origin/main...
    git pull --ff-only origin main 2>nul
)

:: Добавляем все изменения
echo [INFO] Стадируем файлы...
git add -A

:: Проверяем, есть ли что коммитить
git diff --cached --quiet
if %errorlevel% equ 0 (
    echo [INFO] Нет изменений для коммита.
) else (
    echo [INFO] Коммитим изменения...
    git commit -m "Assets update %TIMESTAMP%"
)

:: Пушим ветку main
echo [INFO] Пушим на GitHub...
git branch -M main
git push -u origin main

if errorlevel 0 (
    echo [INFO] Успешно запушено.
) else (
    echo [ERROR] Ошибка при пуше. Проверьте доступ/аутентификацию.
)

:: Получаем короткий SHA текущего HEAD
for /f "delims=" %%h in ('git rev-parse --short=7 HEAD') do set "SHA=%%h"

echo [INFO] Текущий SHA: %SHA%

:: Тегируем деплой
set "TAG=deploy-%TIMESTAMP%"
echo [INFO] Тегируем как %TAG%...
git tag -f %TAG%
git push origin %TAG% --force

:: ================================
:: Cache-bust patch: заменяем @main/ на @<SHA>/ и добавляем ?v=<TIMESTAMP> к картинкам
:: ================================
echo.
echo [INFO] Применяем cache-bust к HTML/CSS/JS (замена @main/ и добавление ?v=)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$sha='%SHA%'; $ts='%TIMESTAMP%'; ^
    $regexImg='(\.(?:png|jpe?g|svg))(?:\?v=\d+)?'; ^
    Get-ChildItem -Recurse -Include *.html,*.css,*.js -ErrorAction SilentlyContinue | ForEach-Object { ^
        $path=$_.FullName; ^
        try { $text=Get-Content -Raw -ErrorAction Stop $path } catch { return }; ^
        $updated=[regex]::Replace($text,$regexImg,{ param($m) \"$($m.Groups[1].Value)?v=$ts\" }); ^
        if ($sha -ne 'main') { $updated=$updated -replace '@main/','@$sha/' }; ^
        if ($updated -ne $text) { Set-Content -LiteralPath $path -Encoding UTF8 $updated; Write-Host '[PATCHED]' $path } ^
    }"

echo.
echo ========================================
echo   ? Деплой завершён
echo ========================================
echo SHA для использования: %SHA%
echo Используй конкретный SHA в jsDelivr URL, чтобы сбросить CDN-кеш:
echo ?? Шрифты: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/fonts/
echo ??? Изображения: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/images/
echo.
echo Альтернативно, если URL уже в письме с @main/, после успешного пуша обнови ссылку на @%SHA%/ или добавь параметр ?v=%TIMESTAMP% к файлам, чтобы точно сбросить кэш.
echo.

pause
endlocal
