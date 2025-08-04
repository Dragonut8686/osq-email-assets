param(
    [string]$Sha = "main",
    [string]$Timestamp = ""
)

# ------------------------------------------------------------------
# Cache-bust & final HTML builder для каждой папки с index.html
# ------------------------------------------------------------------

# Устанавливаем рабочую директорию на расположение скрипта
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

if ([string]::IsNullOrEmpty($Timestamp)) {
    $Timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
}

Write-Host "[INFO] Patch run with SHA=$Sha, Timestamp=$Timestamp"

# Регекс для картинок
$imgRegex = '(\.(?:png|jpe?g|svg))(?:\?v=\d+)?'

# 1. Патчим все .html/.css/.js в репо: добавляем ?v= и заменяем @main/ на @<Sha>/
Get-ChildItem -Recurse -Include *.html,*.css,*.js -ErrorAction SilentlyContinue | ForEach-Object {
    $path = $_.FullName
    try {
        $content = Get-Content -Raw -ErrorAction Stop $path
    } catch {
        Write-Warning ("Cannot read {0}: {1}" -f $path, $_)
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

# 2. Находим все подпапки, которые содержат index.html (email-письма)
$emailFolders = Get-ChildItem -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "index.html")
}

if (-not $emailFolders) {
    Write-Warning "Не найдены подпапки с index.html. Пытаемся найти любой index.html в дереве."
    $fallback = Get-ChildItem -Recurse -Filter index.html | Select-Object -First 1
    if ($fallback) {
        $emailFolders = @((Get-Item $fallback.DirectoryName))
    }
}

# 3. Собираем финальные HTML для каждой папки
foreach ($folder in $emailFolders) {
    $name = $folder.Name
    $sourceIndex = Join-Path $folder.FullName "index.html"
    if (-not (Test-Path $sourceIndex)) {
        Write-Warning "Пропускаю $name — index.html не найден."
        continue
    }

    $distDir = Join-Path "dist" $name
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
        Write-Host "[INFO] Built final HTML for '$name' at $finalPath"
    } catch {
        Write-Warning ("Не удалось собрать финальный HTML для {0}: {1}" -f $name, $_)
    }
}
