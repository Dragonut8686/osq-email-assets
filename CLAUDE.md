# CLAUDE.md
Всегда отвечай на русском, давай комментарии на русском

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an email assets repository for OSQ (packaging company). It stores HTML email templates with associated fonts and images, organized by date. Assets are deployed to GitHub and served via jsDelivr CDN.

## Project Structure

Each email campaign is a dated folder following the pattern `YYYY-MM-DD-osq-email[-description]/`:
- `index.html` - Main Russian email template (table-based HTML for email clients)
- `index_eng.html` - English version (when applicable)
- `fonts/` - Qanelas font family (.woff, .woff2)
- `images/` - Campaign-specific images (PNG, JPG, GIF)

Old/archived projects are moved to `old design/`.

## Deploy Commands

```bash
# Windows - deploy all changes
deploy.bat

# Windows - deploy specific project with direct link
deploy.bat "2025-12-25-osq-new-year" "images/filename.png"

# Unix/macOS
./deploy.sh
```

The deploy scripts auto-commit and push to GitHub. Assets become available at:
- CDN: `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/{project}/`
- Raw: `https://raw.githubusercontent.com/Dragonut8686/osq-email-assets/main/{project}/`

---

## ЭТАЛОННЫЙ ШАБЛОН: 2025-12-16-osq-email-round-bowl-620

Это основа для всех новых писем. Ключевые характеристики:

### Базовые параметры
- **DOCTYPE**: HTML 4.01 Transitional
- **Ширина контейнера**: 640px (max-width)
- **Border-radius блоков**: 32px (основные), 16px (карточки USP)
- **Фон письма**: #FFFFFF (белый)
- **Фон блоков**: #F6F7F8 (светло-серый)
- **Тёмный футер**: #1A1A1A
- **Акцентный цвет**: #00A499 (teal)
- **Цвет текста**: #151515 (заголовки), #555555 (основной текст), #777777 (подписи)

### Шрифты
```css
@font-face {
    font-family: 'Qanelas';
    src: url('https://cdn.jsdelivr.net/gh/Dragonut8686/osq-eemail-assets@main/2025-07-25-osq-email/fonts/Qanelas-Regular.woff2') format('woff2');
}
/* Веса: 400 (Regular), 500 (Medium), 700 (Bold), 800 (ExtraBold) */
```

### Структура блоков письма
1. **Header**: логотип + "В браузере" + "Каталог →"
2. **Hero-блок**: баннер с градиентом + бейдж + заголовок + описание
3. **Контентные блоки**: серые (#F6F7F8) с картинками и текстом
4. **USP-сетка**: 2×3 карточки на белом фоне внутри серого блока
5. **Zig-zag блоки**: чередование картинка слева/справа (dir="rtl")
6. **CTA**: pill-кнопки с border-radius: 50px
7. **Footer**: тёмный блок с соцсетями и контактами

### Отступы между блоками
- Между всеми основными блоками: **5px** (spacer)
- Padding блоков: `0 10px 5px 10px`
- Внутренние отступы контента: `30px 30px` или `35px 30px 40px 30px`

---

## ПРОДВИНУТЫЕ ТЕХНИКИ (из анализа 620 и Яндекс-письма)

### 1. VML для Outlook (фоновые изображения)
Outlook не поддерживает CSS background-image. Используем VML:

```html
<!--[if gte mso 9]>
<v:rect xmlns:v="urn:schemas-microsoft-com:vml" fill="true" stroke="false" style="width:620px; height:380px;">
    <v:fill type="frame" src="URL_ИЗОБРАЖЕНИЯ" />
    <v:textbox inset="0,0,0,0">
<![endif]-->

<!-- Контент поверх фона -->

<!--[if gte mso 9]>
    </v:textbox>
</v:rect>
<![endif]-->
```

Не забыть VML namespace в теге `<html>`:
```html
<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
```

### 2. Gmail iOS White Text Fix
Белый текст на тёмном фоне пропадает в Gmail iOS. Хак:

```css
@media only screen and (max-width: 500px) {
    u + .body .white_text {
        background: linear-gradient(#ffffff,#ffffff);
        background-clip: text;
        -webkit-background-clip: text;
        color: transparent !important;
    }
    div > u + .body .white_text {
        background-image: none;
        background-clip: inherit;
        -webkit-background-clip: inherit;
        color: #ffffff !important;
    }
}
```

Добавить `class="body"` на `<body>` и `class="white_text"` на белый текст.

### 3. VK Snippet Control
Тег `<vk-snippet-end />` обрезает сниппет письма в VK:

```html
<div class="preheader">Текст превью <vk-snippet-end/>͏‌͏͏‌  ͏‌  ͏‌ ...</div>
```

### 4. Невидимые символы для прехедера
Маскируют технический текст после превью:

```html
<!-- Вариант 1: Zero-width символы -->
͏‌͏͏‌  ͏‌  ͏‌  ͏‌

<!-- Вариант 2: Braille pattern blank -->
⠀⠀⠀⠀⠀⠀⠀⠀

<!-- Вариант 3: HTML entities -->
&nbsp;‌&nbsp;‌&nbsp;‌
```

### 5. dir="rtl" для смены порядка колонок
Меняет порядок ячеек таблицы (картинка справа вместо слева):

```html
<table dir="rtl">
    <tr>
        <td dir="ltr">Картинка (будет справа)</td>
        <td dir="ltr">Текст (будет слева)</td>
    </tr>
</table>
```

### 6. Адаптивные изображения в двухколоночных блоках
Для мобильных устройств background-image не работает. Решение:

```html
<td class="mob_100" background="URL" style="background-image: url('URL'); background-size: cover; height: 200px;">
    <div class="mob-gif-wrap" style="display:none; width:0; max-height:0; overflow:hidden;">
        <img src="URL" class="mob-gif-img" style="display: block; width: 100%; height: auto;">
    </div>
</td>
```

CSS:
```css
@media only screen and (max-width: 640px) {
    .mob_100 {
        display: block !important;
        width: 100% !important;
        background-image: none !important;
        height: auto !important;
    }
    .mob-gif-wrap {
        display: block !important;
        width: 100% !important;
        max-height: none !important;
    }
}
```

### 7. Pill-кнопки для Outlook
Outlook игнорирует padding в `<a>`. Используем mso-padding-alt:

```html
<td bgcolor="#00A499" style="border-radius: 50px; mso-padding-alt: 17px 40px;">
    <a href="URL" style="display: block; padding: 17px 40px; color: #ffffff; font-weight: bold;">
        Текст кнопки
    </a>
</td>
```

### 8. Градиентный оверлей на баннере
Улучшает читаемость текста поверх изображения:

```html
<td style="background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0) 65%);">
    <h1 class="white_text">Заголовок</h1>
</td>
```

---

## MOBILE CSS CLASSES

```css
.mobile-stack { display: block !important; width: 100% !important; }
.mobile-pad { padding-left: 20px !important; padding-right: 20px !important; }
.h1-mobile { font-size: 24px !important; line-height: 28px !important; }
.h2-mobile { font-size: 24px !important; line-height: 28px !important; }
.mob_100 { display: block !important; width: 100% !important; background: none !important; }
.mob-gif-wrap { display: block !important; width: 100% !important; }
.collection-card { display: block !important; width: 100% !important; padding: 5px 0 !important; }
.usp-card { padding: 15px !important; }
.mobile-text-pad { padding: 12px 15px !important; }
```

---

## ТИПОВАЯ СТРУКТУРА НОВОГО ПИСЬМА

```
1. DOCTYPE + <html> с VML namespace
2. <head>
   - meta charset, viewport, x-apple-disable-message-reformatting
   - <title>
   - @font-face для Qanelas
   - CSS стили + mobile media queries + Gmail iOS fix
3. <body class="body">
   - Preheader с <vk-snippet-end/>
   - Невидимые символы
   - Основная таблица 640px
     - HEADER (логотип, ссылки)
     - HERO (баннер + текст в сером блоке F6F7F8)
     - КОНТЕНТ (серые блоки, zig-zag, USP-сетки)
     - CTA (pill-кнопки)
     - FOOTER (тёмный блок 1A1A1A)
```

---

## ЧЕКЛИСТ ПЕРЕД ОТПРАВКОЙ

- [ ] Все изображения загружены на CDN
- [ ] Пути к изображениям ведут на jsdelivr CDN
- [ ] VML для Outlook добавлен на все background-image
- [ ] Gmail iOS fix применён к белому тексту
- [ ] Мобильные классы работают
- [ ] `<vk-snippet-end/>` в прехедере
- [ ] Ссылки UTM-меток настроены
- [ ] Alt-тексты заполнены
- [ ] Протестировано в Litmus/Email on Acid

---

## ПРИМЕРЫ ФАЙЛОВ ДЛЯ ИЗУЧЕНИЯ

- **Эталон оформления**: `2025-12-16-osq-email-round-bowl-620/index.html`
- **Пример Яндекс-техник**: `Примеры/example_1.html`
- **Case Bowl в новом стиле**: `2025-11-05-osq-email-case-bowl/index_620_style.html`
