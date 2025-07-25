# OSQ Email Assets

Репозиторий для хранения ресурсов (шрифты, изображения) для HTML-писем OSQ.

## 📁 Структура

```
osq-email-assets/
├── fonts/                 # Шрифты Qanelas
│   ├── qanelas-regular.woff2
│   ├── qanelas-regular.woff
│   ├── qanelas-medium.woff2
│   ├── qanelas-medium.woff
│   ├── qanelas-bold.woff2
│   ├── qanelas-bold.woff
│   └── qanelas-extrabold.woff2
├── images/                # Изображения для письма
│   ├── 01-image-01.png    # Основное изображение продукта
│   ├── 01-icon-1.svg      # Иконка "Два цветовых решения"
│   ├── 01-icon-2.svg      # Иконка "Уникальный внешний вид"
│   ├── 01-icon-3.svg      # Иконка "Устойчивое развитие"
│   ├── 01-icon-4.svg      # Иконка "Не требует сборки"
│   ├── 01-icon-5.svg      # Иконка "Подходит под запайку"
│   └── 01-icon-6.svg      # Иконка "Жесткий борт"
└── deploy scripts         # Скрипты автодеплоя
```

## 🚀 Быстрый деплой

### Windows
```bash
# Первый раз (полная настройка)
deploy.bat

# Быстрое обновление
quick-push.bat
```

### Linux/Mac
```bash
# Сделать исполняемым
chmod +x deploy.sh

# Запустить
./deploy.sh
```

## 🔗 CDN Ссылки

### Шрифты
```css
/* Regular */
https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/fonts/qanelas-regular.woff2

/* Medium */  
https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/fonts/qanelas-medium.woff2

/* Bold */
https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/fonts/qanelas-bold.woff2

/* Extra Bold */
https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/fonts/qanelas-extrabold.woff2
```

### Изображения
```html
<!-- Основное изображение -->
https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/images/01-image-01.png

<!-- Иконки -->
https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/images/01-icon-1.svg
https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/images/01-icon-2.svg
<!-- ... и так далее -->
```

## 📝 Примечания

- Все изображения оптимизированы для email
- Шрифты в форматах WOFF2 и WOFF для максимальной совместимости
- CDN ссылки обновляются в течение 1-2 минут после push
- Используйте `@main` для последней версии или `@v1.0` для фиксированной версии

## 🛠 Требования

- Git установлен и настроен
- Права доступа к репозиторию
- Интернет соединение

---

**Создано для OSQ Email проекта** 📧 