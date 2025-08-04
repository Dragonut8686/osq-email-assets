@echo off
setlocal

REM ================================
REM OSQ Email Assets - Auto Deploy
REM ================================

:: �������� timestamp ��� cache-bust � �������
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "TIMESTAMP=%%a"

echo =========================================
echo   OSQ Email Assets - Auto Deploy
echo   Timestamp: %TIMESTAMP%
echo =========================================
echo.

:: ���������, ���� �� git-�����������
if not exist ".git" (
    echo [INFO] .git �� ������. �������������� �����������...
    git init
)

:: ���������, ����� �� origin
git remote | findstr /i "^origin$" >nul 2>&1
if errorlevel 1 (
    echo [INFO] ��������� remote origin...
    git remote add origin https://github.com/Dragonut8686/osq-email-assets.git
) else (
    echo [INFO] Remote origin ��� ����������.
)

:: ��������� ���������� � ���������
echo [INFO] �������� ���������� �� origin...
git fetch origin

:: ������������� �� main (������ � ����������� ���� �����)
git rev-parse --verify main >nul 2>&1
if errorlevel 1 (
    echo [INFO] ����� main ����������� ��������, ������ ������������� �� origin/main...
    git switch -c main origin/main 2>nul || git switch -c main
) else (
    git switch main
    echo [INFO] ��������� ��������� main �� origin/main...
    git pull --ff-only origin main 2>nul
)

:: ��������� ��� ���������
echo [INFO] ��������� �����...
git add -A

:: ���������, ���� �� ��� ���������
git diff --cached --quiet
if %errorlevel% equ 0 (
    echo [INFO] ��� ��������� ��� �������.
) else (
    echo [INFO] �������� ���������...
    git commit -m "Assets update %TIMESTAMP%"
)

:: ����� ����� main
echo [INFO] ����� �� GitHub...
git branch -M main
git push -u origin main

if errorlevel 0 (
    echo [INFO] ������� ��������.
) else (
    echo [ERROR] ������ ��� ����. ��������� ������/��������������.
)

:: �������� �������� SHA �������� HEAD
for /f "delims=" %%h in ('git rev-parse --short=7 HEAD') do set "SHA=%%h"

echo [INFO] ������� SHA: %SHA%

:: �������� ������
set "TAG=deploy-%TIMESTAMP%"
echo [INFO] �������� ��� %TAG%...
git tag -f %TAG%
git push origin %TAG% --force

:: ================================
:: Cache-bust patch: �������� @main/ �� @<SHA>/ � ��������� ?v=<TIMESTAMP> � ���������
:: ================================
echo.
echo [INFO] ��������� cache-bust � HTML/CSS/JS (������ @main/ � ���������� ?v=)...
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
echo   ? ������ ��������
echo ========================================
echo SHA ��� �������������: %SHA%
echo ��������� ���������� SHA � jsDelivr URL, ����� �������� CDN-���:
echo ?? ������: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/fonts/
echo ??? �����������: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@%SHA%/2025-07-25-osq-email/images/
echo.
echo �������������, ���� URL ��� � ������ � @main/, ����� ��������� ���� ������ ������ �� @%SHA%/ ��� ������ �������� ?v=%TIMESTAMP% � ������, ����� ����� �������� ���.
echo.

pause
endlocal
