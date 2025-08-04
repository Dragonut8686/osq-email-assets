@echo off
chcp 65001 >nul
echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo =========================================

:: Get current date and time
for /f "delims=" %%a in ('powershell -Command "Get-Date -Format 'dd.MM.yyyy HH:mm:ss'"') do set "timestamp=%%a"

echo Current time: %timestamp%
echo.

:: Check if git is initialized
if not exist ".git" (
    echo Initializing Git repository...
    git init
    git remote add origin https://github.com/Dragonut8686/osq-email-assets.git
    echo.
)

:: Add all files (including folder structure)
echo Adding files...
git add .

:: Check if there are changes
git diff --staged --quiet
if %errorlevel% equ 0 (
    echo No changes to commit.
    pause
    exit /b
)

:: Make commit with automatic message
echo Creating commit...
git commit -m "Assets update %timestamp%"

:: Push to GitHub
echo Pushing to GitHub...
git branch -M main
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   SUCCESS: Uploaded to GitHub!
    echo ========================================
    echo.
    echo Your links for current project 2025-07-25-osq-email:
    echo Fonts: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/fonts/
    echo Images: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/
    echo.
    echo For other projects, just replace the date in the URL
    echo.
) else (
    echo.
    echo ERROR: Upload failed!
    echo Check your internet connection and access rights.
    echo.
)

pause 