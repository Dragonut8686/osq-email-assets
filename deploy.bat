@echo off
REM ============================================================
REM OSQ Email Assets - Auto Deploy (v2.5)
REM MUST be saved as UTF-8 WITHOUT BOM
REM ============================================================

chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

REM ---- config ----
set "REPO_SLUG=Dragonut8686/osq-email-assets"
set "REPO_URL=https://github.com/%REPO_SLUG%.git"
set "PROJECT_DIR=2025-07-25-osq-email"
set "LOG_FILE=deploy-log.txt"
set "CHANGED_LIST=deploy-changed.txt"
REM -----------------

REM timestamp
for /f "delims=" %%a in ('
  powershell -NoLogo -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""
') do set "TIMESTAMP=%%a"

echo =========================================
echo   Deploy start: %TIMESTAMP%
echo =========================================
echo.

REM init if needed
if not exist ".git" (
    echo [init] initializing git repository...
    git init
)

REM ensure origin remote
for /f "delims=" %%r in ('git remote') do set "HAS_REMOTE=%%r"
if not defined HAS_REMOTE (
    git remote add origin "%REPO_URL%"
) else (
    for /f "delims=" %%u in ('git remote get-url origin') do set "CUR_ORIGIN=%%u"
    if /I not "%CUR_ORIGIN%"=="%REPO_URL%" (
        echo [init] resetting origin URL...
        git remote set-url origin "%REPO_URL%"
    )
)

REM safety
git config core.ignorecase false

REM identity
for /f "delims=" %%n in ('git config user.name 2^>nul') do set "GIT_USER=%%n"
for /f "delims=" %%m in ('git config user.email 2^>nul') do set "GIT_EMAIL=%%m"
if not defined GIT_USER (
    git config user.name "OSQ Deploy Bot"
)
if not defined GIT_EMAIL (
    git config user.email "deploy@osqgroup.ru"
)

REM stage changes
echo [stage] adding all changes...
git add -A

REM record staged files
git diff --name-only --cached > "%CHANGED_LIST%"

REM commit if any
git diff --cached --quiet
if errorlevel 1 (
    echo [commit] creating commit...
    git commit -m "Assets update %TIMESTAMP%"
) else (
    echo [commit] no changes to commit
)

git branch -M main

REM push
echo [push] pushing to origin main...
git push -u origin main
if errorlevel 1 (
    echo [error] push failed
    goto :push_fail
)

REM commit info
for /f "delims=" %%h in ('git rev-parse HEAD') do set "COMMIT_FULL=%%h"
for /f "delims=" %%h in ('git rev-parse --short HEAD') do set "COMMIT_SHORT=%%h"

set "CDN_BASE_MAIN=https://cdn.jsdelivr.net/gh/%REPO_SLUG%@main/%PROJECT_DIR%/"
set "CDN_BASE_VER=https://cdn.jsdelivr.net/gh/%REPO_SLUG%@%COMMIT_SHORT%/%PROJECT_DIR%/"

echo.
echo [info] commit full : %COMMIT_FULL%
echo [info] commit short: %COMMIT_SHORT%
echo [info] CDN main    : %CDN_BASE_MAIN%
echo [info] CDN version : %CDN_BASE_VER%
echo.

echo [links] fonts:
echo   MAIN: %CDN_BASE_MAIN%fonts/
echo   VER : %CDN_BASE_VER%fonts/
echo [links] images:
echo   MAIN: %CDN_BASE_MAIN%images/
echo   VER : %CDN_BASE_VER%images/
echo.

REM append to log
(
    echo =========================================
    echo %TIMESTAMP%
    echo Commit FULL : %COMMIT_FULL%
    echo Commit SHORT: %COMMIT_SHORT%
    echo CDN MAIN    : %CDN_BASE_MAIN%
    echo CDN VER     : %CDN_BASE_VER%
    echo Changed files:
) >> "%LOG_FILE%"

if exist "%CHANGED_LIST%" (
    for /f "usebackq delims=" %%f in ("%CHANGED_LIST%") do (
        echo   - %%f>> "%LOG_FILE%"
    )
) else (
    echo   - none>> "%LOG_FILE%"
)

:: ---------- Быстрый HEAD-чек ----------
set "CHECK_FILE=%PROJECT_DIR%/images/01-icon-2.png"
if exist "%CHECK_FILE%" (
    rem Удаляем %PROJECT_DIR%/ из пути и заменяем обратные слэши на прямые
    set "_TMP_PATH=%CHECK_FILE:/=\%"
    setlocal enabledelayedexpansion
    set "_TMP_PATH=!_TMP_PATH:%PROJECT_DIR%\=!"
    set "_TMP_PATH=!_TMP_PATH:\=/!"
    endlocal & set "CDN_PATH=%_TMP_PATH%"
    set "URL_MAIN=%CDN_BASE_MAIN%%CDN_PATH%"
    set "URL_VER=%CDN_BASE_VER%%CDN_PATH%"
    echo [HEAD] Проверка CDN (MAIN)...
    echo   MAIN: %URL_MAIN%
    powershell -NoLogo -NoProfile -Command ^
      "Invoke-WebRequest -Method Head -Uri '%URL_MAIN%' -UseBasicParsing | ForEach-Object {Write-Host ('  STATUS: ' + $_.StatusCode)}"
    echo [HEAD] Проверка CDN (VER)...
    echo   VER : %URL_VER%
    powershell -NoLogo -NoProfile -Command ^
      "Invoke-WebRequest -Method Head -Uri '%URL_VER%' -UseBasicParsing | ForEach-Object {Write-Host ('  STATUS: ' + $_.StatusCode)}"
)

del "%CHANGED_LIST%" >nul 2>&1

goto :eof

:push_fail
    echo.
    echo ========= ОШИБКА PUSH =========
    echo Проверьте соединение или токен доступа.
    echo =================================
    goto :end

:end
    pause
    exit /b 0

