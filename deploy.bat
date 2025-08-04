@echo off
setlocal

REM ================================
REM OSQ Email Assets – Auto Deploy
REM ================================

REM Получаем timestamp
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "TIMESTAMP=%%a"

echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo   Timestamp: %TIMESTAMP%
echo =========================================
echo.

pushd "%~dp0"

SET "REPO_URL=https://github.com/Dragonut8686/osq-email-assets.git"

REM Инициализация git, если ещё нет
if not exist ".git" (
    echo [INFO] Git repo not found. Initializing...
    git init
)

REM Проверяем/устанавливаем origin
git remote | findstr /i "^origin$" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Adding origin remote...
    git remote add origin %REPO_URL%
) else (
    echo [INFO] Origin already configured.
    REM Убедимся, что URL правильный (опционально)
    REM git remote set-url origin %REPO_URL%
)

REM Получаем обновления
echo [INFO] Fetching origin...
git fetch origin

REM Переключаемся на main (создаём, если нужно)
git rev-parse --verify main >nul 2>&1
if errorlevel 1 (
    echo [INFO] Creating and tracking main from origin/main...
    git switch -c main origin/main 2>nul || git switch -c main
) else (
    git switch main
    echo [INFO] Fast-forward pulling origin/main...
    git pull --ff-only origin main 2>nul
)

REM Стадируем все изменения
echo [INFO] Staging changes...
git add -A

REM Коммитим, если есть
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
git push origin main

if errorlevel 0 (
    echo [INFO] Push succeeded.
) else (
    echo [ERROR] Push failed. Continuing to attempt cache-bust anyway.
)

REM Получаем короткий SHA текущего коммита
set "SHA="
for /f "delims=" %%h in ('git rev-parse --short=7 HEAD 2^>nul') do set "SHA=%%h"

if "%SHA%"=="" (
    echo [WARN] Could not get SHA, falling back to 'main'
    set "SHA=main"
) else (
    echo [INFO]
