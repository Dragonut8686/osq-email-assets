@echo off
setlocal

REM ================================
REM OSQ Email Assets – Auto Deploy
REM ================================

REM Получаем timestamp для cache-bust и тегов
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "TIMESTAMP=%%a"

echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo   Timestamp: %TIMESTAMP%
echo =========================================
echo.

pushd "%~dp0"

set "REPO_URL=https://github.com/Dragonut8686/osq-email-assets.git"

REM Инициализация git, если нужно
if not exist ".git" (
    echo [INFO] Git repo not found. Initializing...
    git init
)

REM Проверяем, есть ли origin
git remote | findstr /i "^origin$" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Adding origin remote...
    git remote add origin %REPO_URL%
) else (
    echo [INFO] Origin already exists.
)

REM Получаем изменения и переключаемся на main
echo [INFO] Fetching origin...
git fetch origin

git rev-parse --verify main >nul 2>&1
if errorlevel 1 (
    echo [INFO] Creating local main from origin/main...
    git switch -c main origin/main 2>nul || git switch -c main
) else (
    git switch main
    echo [INFO] Pulling origin/main...
    git pull --ff-only origin main 2>nul
)

REM Stage / commit / push
echo [INFO] Staging changes...
git add -A

git diff --cached --quiet
if errorlevel 1 (
    echo [INFO] Committing changes...
    git commit -m "Assets update %TIMESTAMP%"
) else (
    echo [INFO] No changes to commit.
)

echo [INFO] Pushing main branch...
git branch -M main
git push origin main

if errorlevel 0 (
    echo [INFO] Push succeeded.
) else (
    echo [WARN] Push may быть некорректным, продолжаем.
)

REM Тегируем
set "TAG=deploy-%TIMESTAMP%"
echo [INFO] Tagging as %TAG%...
git tag -f %TAG%
git push origin %TAG% --force

REM Запускаем PowerShell-патч
if exist "deploy.ps1" (
    echo [INFO] Running patch/build script...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Timestamp "%TIMESTAMP%"
) else (
    echo [ERROR] deploy.ps1 not found; skipping patch/build.
)

echo.
echo ========================================
echo   ✅ Deploy complete
echo ========================================
echo Final HTMLs: dist\<email-folder>\email-final.html
echo.

pause
popd
endlocal
