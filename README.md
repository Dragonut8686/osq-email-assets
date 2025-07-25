# OSQ Email Assets

Репозиторий для хранения ассетов email-рассылок с сохранением структуры по датам.

## Структура проекта

```
osq-email-assets/
├── 2025-07-25-osq-email/
│   ├── fonts/
│   ├── images/
│   └── index.html
├── 2025-08-15-osq-email/  # следующие проекты
│   ├── fonts/
│   ├── images/
│   └── index.html
└── deploy.bat              # скрипт деплоя для Windows
└── deploy.sh               # скрипт деплоя для Unix/macOS
```

## Деплой

### Для Windows:
```bash
deploy.bat
```

### Для Unix/macOS:
```bash
chmod +x deploy.sh
./deploy.sh
```

## Использование ссылок

После деплоя ваши ассеты будут доступны по ссылкам:

### Для проекта 2025-07-25-osq-email:
- **Шрифты**: `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/fonts/`
- **Изображения**: `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/`

### Для других проектов:
Просто замените дату в URL на нужную:
- **Шрифты**: `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/ДАТА-osq-email/fonts/`
- **Изображения**: `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/ДАТА-osq-email/images/`

## Добавление нового проекта

1. Создайте новую папку с датой: `YYYY-MM-DD-osq-email`
2. Добавьте в неё папки `fonts/` и `images/` с нужными файлами
3. Запустите скрипт деплоя из корневой папки проекта 