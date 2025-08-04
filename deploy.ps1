param(
    [string]$Sha = "main",
    [string]$Timestamp = ""
)

# ------------------------------------------------------------------
# Cache-bust & final HTML builder for each email folder
# ------------------------------------------------------------------

# Ensure working dir is script location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

if ([string]::IsNullOrEmpty($Timestamp)) {
    $Timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
}

Write-Host "[INFO] Patch run with SHA=$Sha, Timestamp=$Timestamp"

# Regex for image extensions
$imgRegex = '(\.(?:png|jpe?g|svg))(?:\?v=\d+)?'

# 1. Patch all source .html/.css/.js globally: add ?v= and replace @main/ with @<Sha>/
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

# 2. Find all email folders containing index.html
$emailFolders = Get-ChildItem -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "index.html")
}

if (-not $emailFolders) {
    Write-Warning "No subfolders with index.html found; searching fallback."
    $fallback = Get-ChildItem -Recurse -Filter index.html | Select-Object -First 1
    if ($fallback) {
        $emailFolders = @((Get-Item $fallback.DirectoryName))
    }
}

# 3. Build final HTML per folder
foreach ($folder in $emailFolders) {
    $name = $folder.Name
    $sourceIndex = Join-Path $folder.FullName "index.html"
    if (-not (Test-Path $sourceIndex)) {
        Write-Warning ("Skipping '{0}' – index.html not found." -f $name)
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
        Write-Host ("[INFO] Built final HTML for '{0}' at {1}" -f $name, $finalPath)
    } catch {
        Write-Warning ("Failed to build final HTML for {0}: {1}" -f $name, $_)
    }
}
