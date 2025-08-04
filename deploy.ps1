param(
    [string]$Sha = "main",
    [string]$Timestamp = ""
)

# ------------------------------------------------------------------
# Cache-bust & final HTML builder
# ------------------------------------------------------------------

# Установим рабочую директорию на расположение скрипта
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

if ([string]::IsNullOrEmpty($Timestamp)) {
    $Timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
}

Write-Host "[INFO] Patch run with SHA=$Sha, Timestamp=$Timestamp"

# Регекс для изображений
$imgRegex = '(\.(?:png|jpe?g|svg))(?:\?v=\d+)?'

# Обновляем все HTML/CSS/JS: добавляем ?v=timestamp и подменяем @main/ на @<Sha>/
Get-ChildItem -Recurse -Include *.html,*.css,*.js -ErrorAction SilentlyContinue | ForEach-Object {
    $path = $_.FullName
    try {
        $content = Get-Content -Raw -ErrorAction Stop $path
    } catch {
        Write-Warning "Cannot read $path: $_"
        return
    }

    $updated = [regex]::Replace($content, $imgRegex, { param($m) "$($m.Groups[1].Value)?v=$Timestamp" })

    if ($Sha -ne "main") {
        $updated = $updated -replace '@main/', "@$Sha/"
    }

    if ($updated -ne $content) {
        Write-Host "[PATCHED] $path"
        Set-Content -LiteralPath $path -Encoding UTF8 $updated
    }
}

# Собираем финальный HTML
$distDir = "dist"
$sourceIndex = Join-Path "2025-07-25-osq-email" "index.html"

if (-not (Test-Path $sourceIndex)) {
    $found = Get-ChildItem -Recurse -Filter index.html | Select-Object -First 1
    if ($found) {
        $sourceIndex = $found.FullName
    }
}

if (Test-Path $sourceIndex) {
    if (-not (Test-Path $distDir)) {
        New-Item -ItemType Directory -Path $distDir | Out-Null
    }
    $finalPath = Join-Path $distDir "email-final.html"
    try {
        $indexContent = Get-Content -Raw -ErrorAction Stop $sourceIndex
        $finalUpdated = [regex]::Replace($indexContent, $imgRegex, { param($m) "$($m.Groups[1].Value)?v=$Timestamp" })
        if ($Sha -ne "main") {
            $finalUpdated = $finalUpdated -replace '@main/', "@$Sha/"
        }
        Set-Content -LiteralPath $finalPath -Encoding UTF8 $finalUpdated
        Write-Host "[INFO] Final HTML written to: $finalPath"
    } catch {
        Write-Warning "Failed to build final HTML: $_"
    }
} else {
    Write-Warning "index.html not found; skipping final HTML."
}
