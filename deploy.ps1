# deploy.ps1 — cache-bust + jsDelivr SHA, патчит файлы, строит финальный HTML,
# делает commit/push/tag если это git-репозиторий.

$ErrorActionPreference = 'Continue'

# 0. Отладка: текущая директория и содержимое верхнего уровня
Write-Host "[DEBUG] Current directory: $(Get-Location)"
Write-Host "[DEBUG] Top-level entries:"
Get-ChildItem -Force | ForEach-Object { Write-Host "  $_" }

# 1. Timestamp для cache-bust
$timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
Write-Host "[INFO] Cache-bust version: $timestamp"

# 2. Проверка наличия git
$hasGit = Test-Path ".git"
if ($hasGit) {
    Write-Host "[INFO] Git repository detected."
} else {
    Write-Warning "[WARN] .git not found. Git operations will be skipped."
}

# 3. Получаем SHA ветки main для jsDelivr, если можно
$short = "main"
if ($hasGit) {
    $remoteRepo = "https://github.com/Dragonut8686/osq-email-assets.git"
    Write-Host "[INFO] Fetching remote SHA from $remoteRepo"
    $lsOutput = & git ls-remote $remoteRepo refs/heads/main 2>$null
    if ($lsOutput) {
        $parts = $lsOutput -split "`t"
        $sha = $parts[0].Trim()
        if ($sha.Length -ge 7) {
            $short = $sha.Substring(0,7)
        } else {
            $short = $sha
        }
        Write-Host "[INFO] Using jsDelivr commit: $short"
    } else {
        Write-Warning "[WARN] Could not fetch remote SHA; leaving '@main/' in URLs."
    }
}

# 4. Патчим все .html/.css/.js: обновляем ?v= и подставляем SHA
$imgRegex = '(\.(?:png|jpe?g|svg))(?:\?v=\d+)?'
$files = Get-ChildItem -Recurse -Include *.html,*.css,*.js -ErrorAction SilentlyContinue

foreach ($file in $files) {
    $path = $file.FullName
    try {
        $content = Get-Content -Raw -ErrorAction Stop $path
    } catch {
        Write-Warning "Cannot read file $path"
        continue
    }

    # Обновление ?v=<timestamp>
    $updated = [regex]::Replace($content, $imgRegex, { param($m) "$($m.Groups[1].Value)?v=$timestamp" })

    # Замена @main/ на @<short>/, только если у нас не fallback
    if ($short -ne "main") {
        $updated = $updated -replace '@main/', "@$short/"
    }

    if ($updated -ne $content) {
        Write-Host "[PATCHED] $path"
        Set-Content -LiteralPath $path -Encoding UTF8 $updated
    }
}

# 5. Собираем финальный HTML: ищем index.html (сначала явный путь, потом рекурсивно)
$distDir = "dist"
$sourceIndex = $null
$explicit = Join-Path "2025-07-25-osq-email" "index.html"

if (Test-Path $explicit) {
    $sourceIndex = $explicit
    Write-Host "[INFO] Found source index via explicit path: $sourceIndex"
} else {
    $found = Get-ChildItem -Recurse -Filter index.html | Select-Object -First 1
    if ($found) {
        $sourceIndex = $found.FullName
        Write-Host "[INFO] Found source index via search: $sourceIndex"
    }
}

if ($null -ne $sourceIndex) {
    if (-not (Test-Path $distDir)) {
        New-Item -ItemType Directory -Path $distDir | Out-Null
    }
    $finalPath = Join-Path $distDir "email-final.html"
    try {
        $indexContent = Get-Content -Raw -ErrorAction Stop $sourceIndex
        $finalUpdated = [regex]::Replace($indexContent, $imgRegex, { param($m) "$($m.Groups[1].Value)?v=$timestamp" })
        if ($short -ne "main") {
            $finalUpdated = $finalUpdated -replace '@main/', "@$short/"
        }
        Set-Content -LiteralPath $finalPath -Encoding UTF8 $finalUpdated
        Write-Host "[INFO] Final HTML written to: $finalPath"
    } catch {
        Write-Warning "Failed to build final HTML from source index: $_"
    }
} else {
    Write-Warning "index.html not found anywhere; skipping final HTML build."
}

# 6. Git: add / commit / push / tag (если есть .git)
if ($hasGit) {
    Write-Host "[INFO] Staging changes..."
    & git add -A

    # Проверка: есть ли что коммитить
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[INFO] No staged changes to commit."
    } else {
        Write-Host "[INFO] Committing changes..."
        & git commit -m "Deploy: cache-bust $timestamp, jsDelivr @$short"
    }

    Write-Host "[INFO] Pushing current branch..."
    & git push origin HEAD

    $tag = "deploy-$timestamp"
    Write-Host "[INFO] Tagging as $tag..."
    & git tag -f $tag
    & git push origin $tag --force
} else {
    Write-Host "[INFO] Skipping git operations because .git is missing."
}

Write-Host "[INFO] Done. jsDelivr reference: @$short; images have ?v=$timestamp. Final HTML (if created) in '$distDir'."
