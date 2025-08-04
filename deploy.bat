@echo off
setlocal

REM ================================
REM OSQ Email Assets – Auto Deploy
REM ================================

REM Получаем timestamp в формате YYYYMMDDHHMMSS для cache-bust и коммита
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "TIMESTAMP=%%a"

echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo   Timestamp: %TIMESTAMP%
echo =========================================
echo.

pushd "%~dp0"

SET "REPO_URL=https://github.com/Dragonut8686/osq-email-assets.git"

REM 1. Инициализация git, если нужно
if not exist ".git" (
    echo [INFO] Git repository not found. Initializing...
    git init
)

REM 2. Убедимся, что origin есть
git remote | findstr /i "^origin$" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Adding origin remote...
    git remote add origin %REPO_URL%
) else (
    echo [INFO] Origin remote already exists.
)

REM 3. Подтягиваем и переключаемся на main
echo [INFO] Fetching origin...
git fetch origin

git rev-parse --verify main >nul 2>&1
if errorlevel 1 (
    echo [INFO] Creating local main from origin/main...
    git switch -c main origin/main 2>nul || git switch -c main
) else (
    git switch main
    echo [INFO] Fast-forward pulling origin/main...
    git pull --ff-only origin main 2>nul
)

REM 4. Стадируем, коммитим если есть изменения
echo [INFO] Staging all changes...
git add -A

git diff --cached --quiet
if errorlevel 1 (
    echo [INFO] Committing changes...
    git commit -m "Assets update %TIMESTAMP%"
) else (
    echo [INFO] No changes to commit.
)

REM 5. Пушим main
echo [INFO] Pushing main branch...
git branch -M main
git push origin main

if errorlevel 0 (
    echo [INFO] Push succeeded.
) else (
    echo [WARN] Push may have failed; continuing.
)

REM 6. Получаем короткий SHA текущего коммита
set "SHA="
for /f "delims=" %%h in ('git rev-parse --short=7 HEAD 2^>nul') do set "SHA=%%h"
if "%SHA%"=="" (
    echo [WARN] Could not resolve SHA, falling back to 'main'
    set "SHA=main"
) else (
    echo [INFO] Current commit SHA: %SHA%
)

REM 7. Тегируем
set "TAG=deploy-%TIMESTAMP%"
echo [INFO] Tagging as %TAG%...
git tag -f %TAG%
git push origin %TAG% --force

REM 8. Запускаем PowerShell-патчинг (cache-bust + финальный HTML)
if exist "deploy.ps1" (
    echo [INFO] Running patch/build script...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Sha "%SHA%" -Timestamp "%TIMESTAMP%"
) else (
    echo [ERROR] deploy.ps1 not found; skipping patch/build.
)

echo.
echo ========================================
echo   ✅ Deploy complete
echo ========================================
echo SHA used: %SHA%
echo jsDelivr fonts: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/fonts/
echo jsDelivr images: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/images/
echo Final HTMLs in dist\<email-folder>\email-final.html
echo.

pause
popd
endlocal
