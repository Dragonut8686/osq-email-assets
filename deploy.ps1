param(
    [string]$Timestamp = ""
)

# Set working directory to script location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

if ([string]::IsNullOrEmpty($Timestamp)) {
    $Timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
}

Write-Host "[INFO] Patch run. Timestamp=$Timestamp"

# Try to get short commit SHA; fallback to "main"
$sha = "main"
try {
    $got = & git rev-parse --short=7 HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $got) {
        $sha = $got.Trim()
    } else {
        Write-Warning "Could not get git SHA, using 'main'."
    }
} catch {
    Write-Warning "Exception getting SHA, using 'main': $_"
}

Write-Host "[INFO] Using SHA=$sha"

# Regex for images
$imgRegex = '(\.(?:png|jpe?g|svg))(?:\?v=\d+)?'

# Patch all .html/.css/.js: add ?v= and replace @main/ with @<sha>/
Get-ChildItem -Recurse -Include *.html,*.css,*.js -ErrorAction SilentlyContinue | ForEach-Object {
    $path = $_.FullName
    try {
        $content = Get-Content -Raw -ErrorAction Stop $path
    } catch {
        Write-Warning ("Cannot read {0}: {1}" -f $path, $_)
        return
    }

    $updated = [regex]::Replace($content, $imgRegex, { param($m) "$($m.Groups[1].Value)?v=$Timestamp" })
    if ($sha -ne "main") {
        $updated = $updated -replace '@main/', "@$sha/"
    }

    if ($updated -ne $content) {
        Write-Host "[PATCHED] $path"
        Set-Content -LiteralPath $path -Encoding UTF8 $updated
    }
}

# Find all email folders containing index.html
$emailFolders = Get-ChildItem -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "index.html")
}

if (-not $emailFolders) {
    Write-Warning "No subfolders with index.html found; attempting fallback."
    $fallback = Get-ChildItem -Recurse -Filter index.html | Select-Object -First 1
    if ($fallback) {
        $emailFolders = @((Get-Item $fallback.DirectoryName))
    }
}

# Build final HTML per email folder
foreach ($folder in $emailFolders) {
    $name = $folder.Name
    $sourceIndex = Join-Path $folder.FullName "index.html"
    if (-not (Test-Path $sourceIndex)) {
        Write-Warning ("Skipping '{0}' - index.html not found." -f $name)
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
        if ($sha -ne "main") {
            $finalUpdated = $finalUpdated -replace '@main/', "@$sha/"
        }
        Set-Content -LiteralPath $finalPath -Encoding UTF8 $finalUpdated
        Write-Host ("[INFO] Built final HTML for '{0}' at {1}" -f $name, $finalPath)
    } catch {
        Write-Warning ("Failed to build final HTML for {0}: {1}" -f $name, $_)
    }
}
