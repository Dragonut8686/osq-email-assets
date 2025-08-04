@echo off
setlocal

REM ================================
REM OSQ Email Assets - Auto Deploy
REM ================================

REM Устанавливаем UTF-8 вывод (опционально, чтобы минимизировать кракозябры)
chcp 65001 >nul

REM Получаем timestamp вида 20250804133243
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "TIMESTAMP=%%a"

echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo   Timestamp: %TIMESTAMP%
echo =========================================
echo.

REM Поднимаемся в директорию скрипта
pushd "%~dp0"

REM Устанавливаем URL репозитория
set "REPO_URL=https://github.com/Dragonut8686/osq-email-assets.git"

REM Инициализируем git, если нужно
if not exist ".git" (
    echo [INFO] Git repo not found. Initializing...
    git init
)

REM Добавляем remote origin, если нет
git remote | findstr /i "^origin$" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Adding origin remote...
    git remote add origin %REPO_URL%
) else (
    echo [INFO] Origin remote already exists.
)

REM Подтягиваем и переключаемся на main
echo [INFO] Fetching origin...
git fetch origin

git rev-parse --verify main >nul 2>&1
if errorlevel 1 (
    echo [INFO] Creating local main tracking origin/main...
    git switch -c main origin/main 2>nul || git switch -c main
) else (
    git switch main
    echo [INFO] Fast-forward pulling origin/main...
    git pull --ff-only origin main 2>nul
)

REM Стадируем все изменения
echo [INFO] Staging all changes...
git add -A

REM Коммитим, если есть изменения
git diff --cached --quiet
if errorlevel 1 (
    echo [INFO] Committing changes...
    git commit -m "Assets update %TIMESTAMP%"
) else (
    echo [INFO] No changes to commit.
)

REM Пушим main
echo [INFO] Pushing main branch...
git branch -M main
git push -u origin main

if errorlevel 0 (
    echo [INFO] Push succeeded.
) else (
    echo [ERROR] Push failed.
)

REM Берём короткий SHA текущего HEAD
for /f "delims=" %%h in ('git rev-parse --short=7 HEAD') do set "SHA=%%h"
if not defined SHA set "SHA=main"

echo [INFO] Current commit SHA: %SHA%

REM Тегируем деплой
set "TAG=deploy-%TIMESTAMP%"
echo [INFO] Tagging as %TAG%...
git tag -f %TAG%
git push origin %TAG% --force

REM Запускаем PowerShell-скрипт для cache-bust и финального HTML
if exist "deploy.ps1" (
    echo [INFO] Running patch script (cache-bust)...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Sha %SHA% -Timestamp %TIMESTAMP%
) else (
    echo [WARN] deploy.ps1 not found, skipping cache-bust step.
)

echo.
echo ========================================
echo   ✅ Deploy complete
echo ========================================
echo SHA: %SHA%
echo jsDelivr fonts: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/fonts/
echo jsDelivr images: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/images/
echo Final HTML: dist\email-final.html
echo.

pause
popd
endlocal
