# Получаем версию из аргумента командной строки
param([string]$version = (Get-Date -Format "yyyyMMddHHmmss"))

Write-Host "Обновление версий изображений с версией: $version"

# Путь к HTML файлу
$htmlFile = "2025-07-25-osq-email/index.html"

# Проверяем существование файла
if (Test-Path $htmlFile) {
    # Читаем содержимое файла
    $content = Get-Content $htmlFile -Encoding UTF8 -Raw
    
    # Обновляем PNG изображения
    $content = $content -replace 'https://cdn\.jsdelivr\.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/([^"\s]+\.png)(?:\?v=\d+)?', "https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/`$1?v=$version"
    
    # Обновляем SVG изображения
    $content = $content -replace 'https://cdn\.jsdelivr\.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/([^"\s]+\.svg)(?:\?v=\d+)?', "https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/`$1?v=$version"
    
    # Обновляем JPG изображения
    $content = $content -replace 'https://cdn\.jsdelivr\.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/([^"\s]+\.jpg)(?:\?v=\d+)?', "https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/`$1?v=$version"
    
    # Обновляем JPEG изображения
    $content = $content -replace 'https://cdn\.jsdelivr\.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/([^"\s]+\.jpeg)(?:\?v=\d+)?', "https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/`$1?v=$version"
    
    # Записываем обновленный файл
    Set-Content $htmlFile $content -Encoding UTF8
    
    Write-Host "✅ Версии изображений обновлены"
} else {
    Write-Host "❌ Файл $htmlFile не найден!"
    exit 1
} 