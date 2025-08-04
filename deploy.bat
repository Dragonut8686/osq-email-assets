@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

REM =========================================
REM   OSQ Email Assets - Auto Deploy (v2)
REM   Repo:  Dragonut8686/osq-email-assets
REM   Project folder: 2025-07-25-osq-email
REM   Author: ChatGPT
REM =========================================

REM --- CONFIG ---
set "REPO_SLUG=Dragonut8686/osq-email-assets"
set "REPO_URL=https://github.com/%REPO_SLUG%.git"
set "PROJECT_DIR=2025-07-25-osq-email"
set "LOG_FILE=deploy-log.txt"
set "CHANGED_LIST=deploy-changed.txt"

REM --- TIMESTAMP ---
for /f "delims=" %%a in ('powershell -NoLogo -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"') do set "TIMESTAMP=%%a"

echo =========================================
echo   OSQ Email Assets - Auto Deploy (v2)
echo   %TIMESTAMP%
echo =========================================
echo.

REM --- GIT INIT / REMOTE ---
if not exist ".git" (
    echo [Init] Initializing Git repository...
    git init
)

REM ensure origin set correctly
for /f "delims=" %%r in ('git remote') do set "HAS_REMOTE=%%r"
if not defined HAS_REMOTE (
    echo [Init] Adding remote origin...
    git remote add origin "%REPO_URL%"
) else (
    REM If origin exists but URL differs, update it
    for /f "delims=" %%u in ('git remote get-url origin 2^>nul') do set "CUR_ORIGIN=%%u"
    if /I not "%CUR_ORIGIN%"=="%REPO_URL%" (
        echo [Init] Updating remote origin URL...
        git remote set-url origin "%REPO_URL%"
    )
)

REM --- SAFETY SETTINGS ---
REM Force case-sensitive tracking on Windows
git config core.ignorecase false

REM Ensure local identity exists
for /f "delims=" %%n in ('git config user.name 2^>nul') do set "GUSER=%%n"
for /f "delims=" %%m in ('git config user.email 2^>nul') do set "GMAIL=%%m"
if not defined GUSER (
    echo [Config] Setting user.name to OSQ Deploy Bot
    git config user.name "OSQ Deploy Bot"
)
if not defined GMAIL (
    echo [Config] Setting user.email to deploy@osqgroup.ru
    git config user.email "deploy@osqgroup.ru"
)

echo.
echo [Stage] Adding files...
git add -A

REM Save list of staged changes BEFORE commit
echo [Stage] Collecting staged changes...
> "%CHANGED_LIST%" (
    git diff --name-only --cached
)

REM Check if there are staged changes
git diff --staged --quiet
if %errorlevel% equ 0 (
    echo [Stage] No changes to commit.
) else (
    echo [Commit] Creating commit...
    git commit -m "Assets update %TIMESTAMP%"
)

REM Ensure branch is main
git branch -M main

echo [Push] Pushing to GitHub...
git push -u origin main
set "PUSH_RC=%ERRORLEVEL%"

if not "%PUSH_RC%"=="0" (
    echo.
    echo ========================================
    echo   ERROR: Push failed!
    echo   Check internet connection or access rights.
    echo ========================================
    echo.
    goto :AFTER
)

echo.
echo ========================================
echo   SUCCESS: Uploaded to GitHub!
echo ========================================
echo.

REM --- COMMIT INFO ---
for /f "delims=" %%h in ('git rev-parse HEAD') do set "COMMIT_FULL=%%h"
for /f "delims=" %%h in ('git rev-parse --short HEAD') do set "COMMIT_SHORT=%%h"

echo [Info] Commit FULL : %COMMIT_FULL%
echo [Info] Commit SHORT: %COMMIT_SHORT%
echo.

REM --- CDN BASES ---
set "CDN_BASE_MAIN=https://cdn.jsdelivr.net/gh/%REPO_SLUG%@main/%PROJECT_DIR%/"
set "CDN_BASE_VER =https://cdn.jsdelivr.net/gh/%REPO_SLUG%@%COMMIT_SHORT%/%PROJECT_DIR%/"

REM trim spaces in CDN_BASE_VER (safety)
for /f "tokens=* delims= " %%A in ("%CDN_BASE_VER%") do set "CDN_BASE_VER=%%A"

echo [CDN] Base (MAIN): %CDN_BASE_MAIN%
echo [CDN] Base (VER) : %CDN_BASE_VER%
echo.

echo [Links] Fonts:
echo   MAIN: %CDN_BASE_MAIN%fonts/
echo   VER : %CDN_BASE_VER%fonts/
echo [Links] Images:
echo   MAIN: %CDN_BASE_MAIN%images/
echo   VER : %CDN_BASE_VER%images/
echo.

REM --- LOG WRITE ---
echo [Log] Writing %LOG_FILE% ...
(
    echo ========================================
    echo %TIMESTAMP%
    echo Commit FULL : %COMMIT_FULL%
    echo Commit SHORT: %COMMIT_SHORT%
    echo CDN MAIN: %CDN_BASE_MAIN%
    echo CDN VER : %CDN_BASE_VER%
    echo Changed files (staged before commit):
    if exist "%CHANGED_LIST%" (
        for /f "usebackq delims=" %%f in ("%CHANGED_LIST%") do echo   - %%f
    ) else (
        echo   - n/a
    )
) >> "%LOG_FILE%"

REM --- SHOW URLS FOR CHANGED FILES (if any) ---
set "FIRST_CHECK_FILE="
if exist "%CHANGED_LIST%" (
    for /f "usebackq delims=" %%f in ("%CHANGED_LIST%") do (
        if not defined FIRST_CHECK_FILE (
            set "FIRST_CHECK_FILE=%%f"
        )
        REM Print both URLs for each changed file located under the project dir
        echo [URL] %%f
        echo   MAIN: https://cdn.jsdelivr.net/gh/%REPO_SLUG%@main/%%f
        echo   VER : https://cdn.jsdelivr.net/gh/%REPO_SLUG%@%COMMIT_SHORT%/%%f
    )
)

REM If nothing changed or first file is empty, fall back to a known icon
if not defined FIRST_CHECK_FILE (
    if exist "%PROJECT_DIR%\images\01-icon-2.png" (
        set "FIRST_CHECK_FILE=%PROJECT_DIR%\images\01-icon-2.png"
    )
)

echo.
echo [Check] Quick CDN HEAD check (MAIN and VER)...
if defined FIRST_CHECK_FILE (
    set "URL_MAIN=https://cdn.jsdelivr.net/gh/%REPO_SLUG%@main/%FIRST_CHECK_FILE%"
    set "URL_VER=https://cdn.jsdelivr.net/gh/%REPO_SLUG%@%COMMIT_SHORT%/%FIRST_CHECK_FILE%"

    echo   MAIN: %URL_MAIN%
    powershell -NoLogo -NoProfile -Command ^
      "$u='%URL_MAIN%';" ^
      "try{" ^
      "  $r=Invoke-WebRequest -Method Head -Uri $u -UseBasicParsing -Headers @{'Cache-Control'='no-cache'};" ^
      "  '  STATUS: ' + $r.StatusCode;" ^
      "  if($r.Headers.ETag){ '  ETag  : ' + $r.Headers.ETag }" ^
      "  if($r.Headers.Age){ '  Age   : ' + $r.Headers.Age }" ^
      "  if($r.Headers['x-cache']){ '  x-cache: ' + $r.Headers['x-cache'] }" ^
      "  if($r.Headers['x-jsdelivr-cache']){ '  x-jsdelivr-cache: ' + $r.Headers['x-jsdelivr-cache'] }" ^
      "}catch{ '  ERROR: ' + $_.Exception.Message }"

    echo   VER : %URL_VER%
    powershell -NoLogo -NoProfile -Command ^
      "$u='%URL_VER%';" ^
      "try{" ^
      "  $r=Invoke-WebRequest -Method Head -Uri $u -UseBasicParsing -Headers @{'Cache-Control'='no-cache'};" ^
      "  '  STATUS: ' + $r.StatusCode;" ^
      "  if($r.Headers.ETag){ '  ETag  : ' + $r.Headers.ETag }" ^
      "  if($r.Headers.Age){ '  Age   : ' + $r.Headers.Age }" ^
      "  if($r.Headers['x-cache']){ '  x-cache: ' + $r.Headers['x-cache'] }" ^
      "  if($r.Headers['x-jsdelivr-cache']){ '  x-jsdelivr-cache: ' + $r.Headers['x-jsdelivr-cache'] }" ^
      "}catch{ '  ERROR: ' + $_.Exception.Message }"

) else (
    echo   (skip) No file to check.
)

echo.
echo =========================================
echo   Done.
echo   Summary saved to: %LOG_FILE%
echo =========================================
echo.
goto :END

:AFTER
REM In case of push errors, still print latest known commit (if any)
for /f "delims=" %%h in ('git rev-parse HEAD 2^>nul') do set "COMMIT_FULL=%%h"
if defined COMMIT_FULL (
    for /f "delims=" %%h in ('git rev-parse --short HEAD') do set "COMMIT_SHORT=%%h"
    echo [Info] Local commit FULL : %COMMIT_FULL%
    echo [Info] Local commit SHORT: %COMMIT_SHORT%
)
echo.
echo =========================================
echo   EXIT WITH ERRORS
echo =========================================
echo.

:END
if exist "%CHANGED_LIST%" del "%CHANGED_LIST%" >nul 2>&1
pause
endlocal
