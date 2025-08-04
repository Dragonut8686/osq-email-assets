# validate-final-html.ps1
# Проверяет output HTML (email-final.html) на:
#  * оставшиеся @main/ (должны быть заменены на конкретный SHA)
#  * image src без ?v= (нужно cache-bust)
#  * базовый jsDelivr URL (если есть) — извлекает и показывает

$errors = 0
$files = Get-ChildItem -Recurse -Filter 'email-final.html' -ErrorAction SilentlyContinue

if (-not $files) {
    Write-Error "Не найден ни один email-final.html в dist/. Сначала запусти deploy.bat."
    exit 1
}

foreach ($f in $files) {
    Write-Host "`n=== Проверка $($f.FullName) ==="
    $content = Get-Content -Raw -ErrorAction Stop $f

    # 1. Проверка @main/
    if ($content -match '@main/') {
        Write-Warning "Найдено '@main/' — должно быть заменено на конкретный SHA, чтобы не вытягивалось старое кешированное содержимое."
        $errors++
    } else {
        Write-Host "✓ Нет '@main/'."
    }

    # 2. Проверка image src без ?v=
    $regexNoCacheBust = 'src=["'']([^"''?]+\.(?:png|jpe?g|svg))(?!\?v=)["'']'
    $matches = [regex]::Matches($content, $regexNoCacheBust)
    if ($matches.Count -gt 0) {
        Write-Warning "Найдено изображений без ?v= (cache-bust): $($matches.Count)"
        foreach ($m in $matches) {
            Write-Host "  - " $m.Groups[1].Value
        }
        $errors += $matches.Count
    } else {
        Write-Host "✓ Все image src имеют ?v= или не подпадают под проверку."
    }

    # 3. Вытащить используемый jsDelivr SHA (если есть)
    $jsdelivrMatches = [regex]::Matches($content, 'cdn\.jsdelivr\.net/gh/Dragonut8686/osq-email-assets@([^/]+)/')
    if ($jsdelivrMatches.Count -gt 0) {
        $used = $jsdelivrMatches[0].Groups[1].Value
        Write-Host "ℹ Используемый jsDelivr ref: @$used"
        if ($used -eq 'main') {
            Write-Warning "Текущий reference — '@main'. Рекомендуется использовать конкретный SHA для детерминированности."
            $errors++
        }
    } else {
        Write-Host "ℹ jsDelivr ссылки не найдены или не стандартные."
    }
}

if ($errors -eq 0) {
    Write-Host "`n✅ Все проверки пройдены. Проблем не обнаружено."
    exit 0
} else {
    Write-Host "`n❌ Всего найдено проблем: $errors"
    exit 2
}
