# PROJECT_DESCRIPTION

## 1. Общее описание

Этот проект не является веб-приложением, SaaS-платформой или backend-системой. `osq-email-assets` — это production-репозиторий HTML email-рассылок и связанных ассетов для компании OSQ / OSQ Group. Внутри него хранятся готовые письма, локализованные версии, изображения, шрифты, референсы, промежуточные варианты и архив предыдущих кампаний. Основной артефакт каждой кампании — готовый HTML-файл письма, который затем используется в сервисе рассылок или вставляется в email-платформу вручную.

Репозиторий организован по папкам кампаний формата `YYYY-MM-DD-slug`. В корне сейчас лежат 6 активных кампаний `2025-11-05 ... 2026-03-16`, а в `old design/` хранится ещё 6 архивных кампаний `2025-07-25 ... 2025-11-17`. Всего в проекте 58 HTML-файлов, из них 14 основных `index.html` и 7 `index_eng.html`. Это важный сигнал: проект живой, используется регулярно, и в нём накапливается не только финальный production-код, но и тестовые, альтернативные и AI-сгенерированные варианты.

Бизнес-задача проекта — поддержка B2B-маркетинга и продаж OSQ. Через эти письма компания анонсирует новые упаковочные линейки, сезонные продукты, акции и преимущества конкретных SKU, ведёт трафик на каталог, продуктовые страницы и формы запроса образцов, а также поддерживает узнаваемость бренда через consistent visual style. Фактически это контентная и конверсионная инфраструктура для email-коммуникаций: письмо должно не просто красиво выглядеть, а корректно открываться в проблемных почтовых клиентах, доносить аргументы для закупщика и приводить к заявке, переходу в каталог или контакту с менеджером.

Целевая аудитория писем — B2B-клиенты OSQ: закупщики, партнёры, дистрибьюторы, производители готовой еды, ритейл, HoReCa, bakery/cafe-сегмент, сезонные продавцы, компании с доставкой и витринной выкладкой. Заказчик проекта — маркетинговая и коммерческая функция OSQ / OSQ Group. Для ENG-версий аудиторией также являются международные партнёры и экспортные/англоязычные контакты.

Текущий статус проекта: production-репозиторий с активной ручной разработкой. Это не MVP. Письма содержат реальные ссылки на `osqgroup.ru`, `osqgroup.com`, Bitrix24-формы, social-профили и browser-view mirror links, то есть используются в боевых коммуникациях. При этом внутри репозитория есть технический долг, неочищенные версии, тестовые HTML и следы ручного/AI-assisted процесса сборки.

## 2. Архитектура

### Общая схема

Архитектура проекта статическая и файловая:

- Источник правды: Git-репозиторий с HTML, картинками, шрифтами и референсами.
- Доставка ассетов: GitHub + jsDelivr CDN.
- Потребитель результата: внешняя email-платформа / сервис рассылок, куда вставляется итоговый HTML.
- Downstream-конверсии: переходы на сайт OSQ, каталог, product pages, Bitrix24 CRM-формы, иногда browser-view mirror pages.

Это не клиент-серверное приложение и не монолит в обычном software-смысле. Правильнее описывать его как static content repository + asset CDN + manual publishing workflow для email-маркетинга.

### Основные модули/компоненты и связи

1. Кампании в корне репозитория
- Каждая активная кампания лежит в отдельной папке.
- Обычно содержит `index.html`, иногда `index_eng.html`, `images/`, `fonts/`, дополнительные `ref/`, `test/`, `old versions/`, `PNG_исходники/`, `.txt`.
- Это главный production-модуль проекта.

2. Архив `old design/`
- Хранит исторические кампании и ранние версии шаблонов.
- Используется как визуальный и структурный референс.
- Не должен считаться текущим production-source, но важен для стилевой преемственности и reverse engineering рабочих решений.

3. Локальные ассеты кампаний
- `images/` содержит product renders, фото, баннеры, GIF, иконки соцсетей, логотипы.
- `fonts/` содержит семейство Qanelas, обычно в `.woff` и `.woff2`, локально дублируемое в каждой кампании.
- HTML зависит от этих ассетов напрямую.

4. Вспомогательные материалы
- `ref/` и `PNG_исходники/` содержат PDF, экспорт страниц презентаций, инструкционные PNG, референсы клиента.
- Нужны для написания текста, выбора структуры и наполнения блоков.

5. Скрипты публикации
- `deploy.bat`, `deploy.sh`, `update.bat`.
- Отвечают за git add/commit/push и генерацию CDN-ссылок.

6. Инструкции и операционные правила
- `AGENTS.md`, `CLAUDE.md`, `README.md`.
- Это не runtime-компоненты, но для внешней AI-системы это критичный operational layer: они задают ограничения по мобильной Я.Почте, CDN-путям, структуре кампаний, плейсхолдерам, RU/ENG симметрии, header/footer и качеству ссылок.

7. Примеры и внешние референсы
- Папка `Примеры/` содержит сторонние HTML-референсы вроде CITILINK и другие примеры email-дизайна.
- Это вспомогательный дизайн-контекст, а не часть production-пайплайна OSQ.

### Потоки данных

Поток данных в проекте выглядит так:

1. Маркетинговая задача появляется в виде новой кампании.
2. В папку кампании попадают исходники: изображения, PDF, экспорт из презентации, текстовые черновики, иногда отдельные ENG-материалы.
3. На основе последней approved-рассылки вручную собирается HTML-письмо в табличной email-вёрстке.
4. В HTML прописываются ссылки:
- на CDN-ассеты кампании;
- на каталог и продуктовые страницы OSQ;
- на CRM-форму Bitrix24;
- на privacy/unsubscribe/browser-view ссылки;
- на соцсети и другие внешние destination URL.
5. Файлы коммитятся и пушатся в GitHub через `deploy.bat` или `deploy.sh`.
6. jsDelivr раздаёт изображения и шрифты по URL вида `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/<campaign>/images/...`.
7. Итоговый HTML вставляется во внешний сервис рассылки.
8. Получатель видит письмо в email-клиенте, а клики уходят на внешние сайты/формы.

Ключевая особенность: никаких внутренних API, очередей, worker-процессов и БД здесь нет. Весь pipeline файловый и largely manual.

### Внешние интеграции

Фактически используемые внешние платформы и домены:

- `github.com/Dragonut8686/osq-email-assets`
  Назначение: origin-репозиторий, источник для CDN.

- `cdn.jsdelivr.net`
  Назначение: раздача изображений и шрифтов письма.

- `raw.githubusercontent.com`
  Назначение: альтернативная прямая раздача файлов, используется как fallback в скриптах и тестах.

- `osqgroup.ru`
  Назначение: основной RU-сайт, каталог, product pages, privacy policy.

- `osqgroup.com`
  Назначение: ENG-сайт/production pages для англоязычных писем.

- `b24-0ioyfv.bitrix24.site`
  Назначение: lead capture / CRM-form, например заказ образцов или запрос условий.

- `osq-mail-url.lovable.app`
  Назначение: browser-view mirror links для открытия письма в браузере.

- `vk.com/osqgroup`, `t.me/osqpack`, `dzen.ru/osqgroup`
  Назначение: social links в footer.

- `disk.360.yandex.ru`
  Назначение: отдельные внешние media links, например watch video / материалы.

Важное замечание: сервис непосредственной отправки письма из репозитория однозначно не фиксируется. Исторически в `old design/2025-09-22-osq-email-bowl-line/ALTERNATIVE_SERVICES.md` зафиксирована проблема с Unisender, который переписывает `@font-face`, и рассматриваются альтернативы вроде SendPulse, DashaMail и Mailganer. Это operational concern, но не зафиксированный runtime stack.

## 3. Стек технологий

Ниже перечислен фактический стек, который реально виден в репозитории. Если версия не закреплена, это указано явно.

### Фронтенд

| Технология | Версия | Для чего используется | Замена |
|---|---|---|---|
| HTML email markup | HTML 4.01 Transitional DOCTYPE в большинстве production-файлов | Основа письма; конечный артефакт, который вставляется в email-платформу | Критичная зависимость. Можно заменить только на другой email-safe HTML, но не на SPA/современный web UI |
| XHTML namespaces (`xmlns`, `xmlns:v`, `xmlns:o`) | Без явной версии | Совместимость с Outlook/VML и различными email-клиентами | Практически обязательны для сложных писем под Outlook |
| Table-based layout (`table`, `tr`, `td`) | Без версии | Базовая верстка всех писем; устойчивость в email-клиентах, особенно Outlook и мобильной Я.Почте | Критичная зависимость. `flex`/`grid` здесь не являются безопасной заменой |
| CSS inline styles | Без версии | Основные стили, типографика, spacing, фоны, кнопки, радиусы | Критично для email; можно только частично дополнять `<style>`-блоком |
| Embedded CSS (`<style>`) | Без версии | Reset, `@font-face`, mobile utility classes, Gmail iOS fix | Частично заменяемо, но для ряда email-хаков необходимо |
| Media queries | Без версии | Вспомогательная адаптация, mobile utilities | Не критичная опора. По правилам проекта media queries не должны быть единственным механизмом адаптации |
| VML (`v:rect`, `v:roundrect`) | Outlook/Office VML, версия не закреплена | Background images и кнопки в Outlook | Почти незаменимо, если нужен богатый дизайн в Outlook |
| Conditional comments for Outlook (`<!--[if gte mso 9]>`) | Без версии | Outlook-specific branches | Практически обязательны при сложных блоках |
| Qanelas font family | Версия не указана; локально хранятся веса от UltraLight до Black | Брендовая типографика OSQ | Не критична функционально, но визуально важна. Можно заменить fallback-стеком или альтернативным брендовым шрифтом |
| GIF assets | Формат GIF | Анимация product/hero блоков | Заменяемо статикой или MP4-landing, но для email GIF остаётся практичным форматом |
| PNG/JPG assets | Форматы PNG/JPG/JPEG | Продуктовые фото, баннеры, иконки, логотипы | Частично заменяемо WebP вне email, но в текущем проекте PNG/JPG безопаснее |

Дополнительные email-specific техники, реально используемые:

- `vk-snippet-end`
- preheader masking invisible symbols
- `dir="rtl"` для реверса колонок
- `mso-padding-alt` для Outlook-friendly CTA
- Gmail iOS white text fix

### Бэкенд

Внутренний бэкенд в проекте отсутствует.

| Технология | Версия | Для чего используется | Замена |
|---|---|---|---|
| Нет собственного backend runtime | N/A | Репозиторий хранит только статические файлы и скрипты публикации | Не применимо |

### БД

Внутренняя база данных отсутствует.

| Технология | Версия | Для чего используется | Замена |
|---|---|---|---|
| Нет БД | N/A | Данные живут в файловой структуре репозитория | Не применимо |

### Инфраструктура

| Технология | Версия | Для чего используется | Замена |
|---|---|---|---|
| GitHub repository | Ветка `main`, version pinning отсутствует | Хранение исходников и источник CDN-ассетов | Заменяемо GitLab/Bitbucket/self-hosted git, но сейчас это ключевая инфраструктурная зависимость |
| jsDelivr GitHub CDN | Versionless service, URL чаще на `@main` | Раздача картинок и шрифтов письма | Заменяемо другим CDN или self-hosting, но критично для текущего workflow |
| raw.githubusercontent.com | Versionless fallback | Альтернативные прямые ссылки на файлы | Не критично, но полезный fallback |
| OSQ websites (`osqgroup.ru`, `osqgroup.com`) | Версии не известны из репозитория | Целевые страницы переходов, каталог, privacy policy | Логически заменяемо, но для бизнес-потока критично |
| Bitrix24 hosted form | Версия не известна | Сбор заявок / образцов / контактов | Заменяемо другой CRM-формой |
| Lovable-hosted browser mirror (`osq-mail-url.lovable.app`) | Версия не известна | Ссылка “В браузере” / “View in browser” | Заменяемо другим hosting/mirror solution |
| Yandex Disk public links | Версия не известна | Отдельные video/material links | Заменяемо любым file hosting |

### AI/ML

Runtime AI/ML в проекте отсутствует, но AI участвует в процессе создания и вариативности файлов.

| Технология | Версия | Для чего используется | Замена |
|---|---|---|---|
| AI-assisted drafting artifacts (`index_gpt.html`, `gemini_index.html`, `Grok.html`, `ChatGPT.html`, `Gemini*.html`) | Версии моделей не зафиксированы | Генерация альтернативных HTML-вариантов и экспериментов с макетом/текстом | Полностью заменяемо ручной работой; это не production dependency |
| `.claude/` config and worktree artifacts | Инструментальные, версия не важна для runtime | Среда AI-редактирования и вспомогательные рабочие копии | Полностью заменяемо другими AI IDE/агентами |

### DevOps

| Технология | Версия | Для чего используется | Замена |
|---|---|---|---|
| Git | Системная версия, не закреплена | Контроль версий, push ассетов | Критично для текущего workflow |
| `deploy.bat` | Custom script, versionless | Windows-публикация: `git add`, `commit`, `push`, генерация CDN/raw links | Заменяемо CI или другим скриптом |
| `deploy.sh` | Custom script, versionless | Unix/macOS-публикация | Заменяемо CI или другим скриптом |
| `update.bat` | Custom script, versionless | Принудительное обновление локальной копии до `origin/main` | Заменяемо обычным git workflow, но сейчас это операционный инструмент |
| `.vscode/settings.json` | Versionless | Локальные editor settings | Не критично |
| `.claude/settings*.json` | Versionless | Настройки AI-редактора | Не критично для production |

### Тестирование

Автоматический тестовый стек отсутствует. Есть только ручные HTML-песочницы и контрольные файлы.

| Технология | Версия | Для чего используется | Замена |
|---|---|---|---|
| Локальные test HTML (`test/`, `index-example-*`, `v1`, `v2`, `Grok`, `ChatGPT`) | Versionless | Ручная проверка рендеринга и альтернативных решений | Заменяемо специализированными email QA-сервисами, но сейчас это единственный тестовый слой |
| Ручная визуальная QA | N/A | Проверка ссылок, плейсхолдеров, Outlook/Yandex-safe структуры | Сейчас критична, так как автоматизации нет |

## 4. Модели данных

Проект не имеет БД, поэтому “модель данных” здесь — файловая и контентная.

### Основные сущности

1. Campaign
- Физически: папка вида `YYYY-MM-DD-slug`
- Примеры:
  - `2025-12-16-osq-email-round-bowl-620`
  - `2026-02-23-osq-email-bake-500`
  - `2026-03-16-osq-email-jumpl`
- Поля на практике:
  - дата
  - slug/тема
  - RU template
  - ENG template
  - image pack
  - font pack
  - reference materials
  - draft/test variants

2. LocalizedTemplate
- Файлы:
  - `index.html`
  - `index_eng.html`
  - альтернативные `index_new.html`, `index_gpt.html`, `index_old.html`, `index_620_style.html`
- Содержит:
  - `title`
  - preheader
  - header
  - hero
  - product/value blocks
  - CTA
  - footer/legal
  - hardcoded URLs

3. AssetImage
- Файлы в `images/`
- Типы:
  - баннеры
  - фото продукта
  - анимированные GIF
  - иконки преимуществ
  - логотипы
  - иконки соцсетей

4. FontAsset
- Файлы в `fonts/`
- Реально хранящиеся веса: `UltraLight`, `Thin`, `Light`, `Regular`, `Medium`, `SemiBold`, `Bold`, `ExtraBold`, `Heavy`, `Black` + italic variants
- В production HTML обычно используются только веса 400/500/700/800

5. ReferenceMaterial
- Файлы в `ref/`, `PNG_исходники/`, иногда `.txt`, `.docx`
- Это входные материалы для контента и верстки, а не runtime assets

6. ExternalLinkSet
- Набор ссылок внутри шаблона:
  - main site
  - catalog
  - product pages
  - privacy policy
  - unsubscribe
  - social
  - browser view
  - form CTA

7. DraftVariant
- Нефинальные или альтернативные варианты, часто AI-generated
- Используются для сравнения, но создают неоднозначность “что считать финалом”

### Ключевые связи между сущностями

- Один `Campaign` содержит один или несколько `LocalizedTemplate`.
- Каждый `LocalizedTemplate` зависит от множества `AssetImage`.
- Каждый `LocalizedTemplate` может ссылаться на `FontAsset`, но не всегда корректно:
  - иногда через jsDelivr CDN;
  - иногда через локальный путь `fonts/...`, что нежелательно для финального письма.
- `ReferenceMaterial` помогает создать `LocalizedTemplate`, но не должен попадать в финальный runtime поток.
- `DraftVariant` связан с `Campaign`, но не должен автоматически считаться финальной production-версией.

### Форматы данных

- HTML:
  Главный формат результата. В большинстве production-файлов это email-safe HTML с HTML 4.01 Transitional DOCTYPE.

- CSS:
  Находится внутри `<style>` и inline-атрибутов `style`.

- Изображения:
  - `.png`
  - `.jpg` / `.jpeg`
  - `.gif`

- Шрифты:
  - `.woff`
  - `.woff2`

- Документы и референсы:
  - `.pdf`
  - `.docx`
  - `.txt`

- Editor/AI configs:
  - `.json` в `.claude/` и `.vscode/`

Явных JSON-схем, TypeScript interfaces, SQL-таблиц или protobuf-моделей в проекте нет.

### Де-факто схемы и соглашения

1. Именование кампаний
- Regex-концепт: `^\d{4}-\d{2}-\d{2}-[a-z0-9-]+$`

2. CDN-путь
- Ожидаемый паттерн:
  `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/<campaign>/images/<file>`

3. UTM-метки
- Часто встречаются:
  - `utm_source=email` или `utm_source=osq_newsletter`
  - `utm_medium=promo|newsletter|email`
  - `utm_campaign=<campaign_slug>`
  - `utm_content=<button_or_block_identifier>`

4. Структурные блоки письма
- header
- preheader
- hero
- intro
- product/value cards
- CTA
- footer with legal/social/privacy/unsubscribe

## 5. Ключевые модули

### 5.1. Campaign Package

Назначение:
- Хранить всю кампанию целиком в одной папке.

Входы:
- текст от клиента
- изображения
- PDF/референсы
- approved reference из прошлой кампании

Выходы:
- готовый `index.html`
- опционально `index_eng.html`
- комплект ассетов для CDN

Зависимости:
- root conventions
- шрифты
- изображения
- внешние ссылки

Что зависит от него:
- публикация через GitHub/jsDelivr
- сервис рассылок
- AI/человек, анализирующий проект

### 5.2. Localized HTML Template

Назначение:
- Быть конечным доставляемым email-документом.

Входы:
- маркетинговый текст
- ссылки
- изображения и GIF
- брендовые шрифты

Выходы:
- один self-contained HTML email file с inline styles и внешними asset URLs

Зависимости:
- `images/`
- `fonts/` или CDN font URLs
- ссылки на внешние сайты/формы
- совместимость с Outlook/Yandex/Gmail/iOS

Что зависит от него:
- итоговая рассылка
- mirror-view page
- ручная QA

### 5.3. Asset Pack (`images/`, `fonts/`)

Назначение:
- Обеспечивать визуальное наполнение письма.

Входы:
- экспорт дизайна
- product renders
- logo/social icons
- исходники от маркетинга/дизайна

Выходы:
- CDN-доступные файлы для `<img>`, `background`, `@font-face`

Зависимости:
- naming consistency
- корректный commit/push в GitHub

Что зависит от него:
- все HTML-шаблоны кампании

### 5.4. Reference Materials (`ref/`, `PNG_исходники/`, `.txt`, `.docx`)

Назначение:
- Служить сырьём для создания смысла письма и структуры блоков.

Входы:
- презентации, PDF, инструкции, текстовые черновики

Выходы:
- адаптированный email-copy и layout decisions

Зависимости:
- ручная интерпретация человеком/AI

Что зависит от него:
- контент шаблона
- качество структуры и аргументации

### 5.5. Deploy Scripts

Назначение:
- Быстро публиковать изменения и давать готовые CDN/raw ссылки.

Входы:
- локальные изменения в файловой системе
- git remote origin

Выходы:
- commit
- push в `main`
- текстовые ссылки для использования

Зависимости:
- Git
- сетевой доступ
- корректная локальная git-конфигурация

Что зависит от него:
- появление свежих ассетов на CDN

### 5.6. Test/Experiment Layer

Назначение:
- Хранить тестовые HTML, альтернативные версии, проверочные макеты, AI-эксперименты.

Входы:
- идеи по layout
- задачи по Outlook/Yandex/Gmail fixes
- AI-generated варианты

Выходы:
- test files
- проверенные решения для будущих писем

Зависимости:
- текущая кампания или historical references

Что зависит от него:
- future campaign refinements

### 5.7. Instruction Layer (`AGENTS.md`, `CLAUDE.md`, `README.md`)

Назначение:
- Фиксировать рабочие правила и ограничения проекта.

Входы:
- накопленный опыт команды
- требования заказчика
- ограничения email-клиентов

Выходы:
- обязательные правила для человека и AI

Зависимости:
- фактический процесс команды

Что зависит от него:
- качество и consistency новых кампаний
- корректность AI-generated изменений

## 6. Текущие проблемы и ограничения

### Известные баги или технический долг

1. В `2025-12-16-osq-email-round-bowl-620/index.html` есть unresolved merge conflict markers:
- `<<<<<<< HEAD`
- `=======`
- `>>>>>>> ...`

Это серьёзный сигнал. Документация в `CLAUDE.md` называет именно эту кампанию эталонным шаблоном, но checked-in файл в репозитории сейчас находится в конфликтном состоянии. Для внешней AI-системы это означает: conceptual reference exists, but repository hygiene is imperfect.

2. В нескольких production или quasi-production файлах остаются placeholder unsubscribe links `href="#"`:
- `2026-02-03-osq-email-promo/index.html`
- `2026-02-23-osq-email-bake-500/index.html`
- `2026-02-23-osq-email-bake-500/index_eng.html`
- `2026-03-16-osq-email-jumpl/index.html`
- `2025-12-25-osq-new-year/index.html`
- `2025-12-25-osq-new-year/index_eng.html`

Это операционный риск, так как проектные правила требуют не оставлять пустые или фальшивые ссылки в финале, если реальные URL уже должны быть известны.

3. В `2026-03-16-osq-email-jumpl/index.html` `@font-face` указывает на локальные `fonts/Qanelas-*.woff2`, а не на CDN. Это противоречит правилам проекта, где финальное письмо должно тянуть реальные ассеты по ссылке, а не локальным путём.

4. Во многих письмах шрифты тянутся с URL, содержащего репозиторий `osq-eemail-assets` вместо `osq-email-assets`. Это встречается в активных шаблонах, например:
- `2025-11-05-osq-email-case-bowl/index.html`
- `2025-11-05-osq-email-case-bowl/index_eng.html`
- `2025-12-16-osq-email-round-bowl-620/index.html`
- `2025-12-16-osq-email-round-bowl-620/index_eng.html`
- `2025-12-25-osq-new-year/index.html`
- `2025-12-25-osq-new-year/index_eng.html`
- `2026-02-03-osq-email-promo/index.html`
- `2026-02-23-osq-email-bake-500/index.html`
- `2026-02-23-osq-email-bake-500/index_eng.html`

Если это не отдельный реально существующий repo-алиас, то это системная ошибка путей к шрифтам.

5. В ENG-файлах есть несогласованность по контактным email и доменам:
- `2025-12-16-osq-email-round-bowl-620/index_eng.html` содержит подозрительный `mailto:@oclientssquared.com` и видимый текст `clients@osquared.com`.
- В других ENG-кампаниях используются `clients@osqgroup.com`.

Это создаёт риск broken contact path и брендовой несогласованности.

6. В репозитории много конкурирующих вариантов одной кампании:
- `index.html`
- `index_new.html`
- `index_gpt.html`
- `index_old.html`
- `index_620_style.html`
- AI-версии в `old versions/`

Это затрудняет определение canonical final file.

7. Git-окружение в текущей рабочей копии выглядит нестабильно из-за `worktree`-артефактов и Windows-path incompatibility. Обычный `git status` в этом окружении завершался ошибкой `fatal: not a git repository: .claude/worktrees/...`. Это не обязательно баг production-репозитория как такового, но это реальный operational issue для автоматизации и анализа.

8. `.claude/worktrees/` содержит дубли контента. Для внешней AI-системы это шум, который нельзя принимать за отдельные кампании.

### Узкие места производительности

Здесь нет классических CPU/DB bottleneck, но есть свои “узкие места”:

1. Производительность человека
- Письма собираются вручную.
- Текст, ссылки, локализация, VML, мобильные ограничения, footer/legal и CDN-пути проверяются вручную.

2. Производительность изменений
- Нет shared template engine или partials.
- Header/footer/style patterns копируются между кампаниями.
- Любая правка типового блока требует manual propagation.

3. Вес кампаний
- Некоторые папки довольно тяжёлые:
  - `2025-12-16-osq-email-round-bowl-620`: ~38M
  - `2026-02-03-osq-email-promo`: ~32M
  - `2026-02-23-osq-email-bake-500`: ~19M
  - `2026-03-16-osq-email-jumpl`: ~15M
- Архив `old design/` весит ~110M.
- Это замедляет навигацию, поиск canonical assets и потенциально commit/push workflow.

4. Дублирование шрифтов
- В 8 кампаний многократно копируется полный набор Qanelas.
- Это удобно для изоляции кампаний, но неэффективно для хранения и поддержки.

### Что хотелось бы улучшить, но пока не сделано

1. Автоматическая проверка ссылок
- локальные `src`
- broken CDN paths
- `href="#"` placeholders
- расхождение RU/ENG ссылок

2. Автоматическая проверка HTML-гигиены
- merge conflict markers
- незакрытые комментарии
- stray placeholders
- mixed domains/contact emails

3. Единый canonical template layer
- сейчас шаблон наследуется копированием прошлой кампании, а не из общего base-template.

4. Явная metadata per campaign
- сейчас дата, slug, назначение, язык, целевой продукт и статус финальности определяются по именам файлов и содержимому.
- удобнее было бы иметь `campaign.json` / `campaign.yaml` / `README.md` внутри каждой кампании.

5. Автоматизированный email QA
- нет Litmus/Email on Acid-подобного контура
- нет screenshot diff
- нет проверки критичных клиентов

6. Централизованная стратегия шрифтов
- сейчас одновременно встречаются:
  - локальные `fonts/...`
  - CDN на `osq-email-assets`
  - CDN на `osq-eemail-assets`
  - historical experiments с Yandex/Google fonts

### Архитектурные ограничения

1. Email-верстка как среда крайне ограничена
- нельзя рассчитывать на современный CSS
- нужно поддерживать Outlook, Gmail, webmail и мобильную Я.Почту

2. Мобильная Я.Почта — ключевой ограничитель
- по правилам проекта mobile view фактически сжимает desktop layout
- значит дизайн должен быть устойчивым даже без media queries

3. Нет разделения контента и представления
- тексты, ссылки, структура, цвета, футер и лейаут жёстко смешаны в одном HTML

4. Нет внутренней компонентной системы
- reuse достигается копированием предыдущих файлов

5. Нет CI/CD и нет semantic versioning
- публикация идёт через push в `main`
- CDN чаще привязан к `@main`, а не к immutable commit/tag

## 7. Планы развития

Явного roadmap-файла в репозитории нет, поэтому ниже перечислены разумные планы, выведенные из структуры проекта, исторических файлов и наблюдаемого техдолга. Это inference, а не формально утверждённый roadmap.

### Что, вероятно, планируется или напрашивается в ближайшее время

1. Продолжение регулярного выпуска новых продуктовых и сезонных кампаний
- Паттерн датированных папок показывает устойчивый cadence.

2. Сохранение и развитие шаблона “больших карточек”
- `CLAUDE.md` фиксирует `2025-12-16-osq-email-round-bowl-620` как reference style.

3. Поддержка RU и ENG версий для части кампаний
- уже есть в нескольких активных и архивных папках.

4. Очистка и стандартизация текущих production шаблонов
- merge conflict cleanup
- единые unsubscribe links
- единый email/domain policy
- нормализация font URLs

5. Усиление опоры на входные референсы
- в новых кампаниях уже есть `ref/` и PDF/PNG-материалы
- этот workflow, вероятно, сохранится

### Какие технологии логично рассматривать для внедрения

1. Email QA / rendering test tools
- Litmus-like or Email on Acid-like сервисы
- либо любые адекватные аналоги с Outlook/Gmail/webmail screenshot testing

2. Линтеры и валидаторы для email HTML
- проверка ссылок
- проверка локальных путей
- placeholder detection
- merge marker detection

3. Metadata layer per campaign
- `campaign.yaml` / `campaign.json`
- хранение языка, продукта, целей, owner, status, canonical files, assets base URL

4. Template generation helpers
- не “генератор красивого HTML”, а инструмент, который безопасно генерирует email-safe tables/VML/CTA/footer blocks

5. Visual diff / regression testing
- особенно для Outlook и Yandex-heavy layouts

6. Инструменты подготовки референсов
- extract текст и изображения из PDF/презентаций
- быстрое сравнение версий дизайна

7. Контур публикации на immutable asset versions
- commit hash вместо `@main`
- либо controlled release tags

8. Проверка ESP совместимости
- особенно если брендовый Qanelas остаётся обязательным

### Направления роста проекта

1. Из репозитория файлов в более формализованную content system
- кампании + metadata + validators + canonical template library

2. Из ручной QA в semi-automated email operations
- link checks
- render checks
- localization checks

3. Из “папка с ассетами” в marketing production kit
- с шаблонами
- инструкциями
- генераторами UTM/link maps
- registry of approved blocks

4. Интеграция с внешней AI-системой
- именно для оценки релевантности новостей и инструментов
- текущий файл `PROJECT_DESCRIPTION.md` как раз может стать такой knowledge-base опорой

## 8. Критерии полезности новостей

Ниже самый важный раздел для внешней AI-системы.

### Какие типы инструментов и новостей реально полезны

#### 1. Всё, что касается HTML email compatibility

Очень полезны новости и инструменты по темам:

- Outlook-specific email rendering
- VML background/button techniques
- Gmail iOS text rendering issues
- Яндекс.Почта mobile behavior
- webmail-safe CSS
- table-based email layout best practices
- inline CSS tooling for email
- email-safe responsive patterns without strong dependency on media queries

Почему это полезно:
- Это core technical medium проекта.
- Ошибки здесь ломают письмо у получателя, а не только developer experience.

#### 2. Инструменты тестирования email-рендеринга

Очень полезны:

- сервисы screenshot testing для email-клиентов
- инструменты сравнения рендеров между Outlook/Gmail/Yandex/webmail
- visual diff для HTML email
- локальные preview/debug инструменты для email HTML

Почему:
- В проекте нет автоматического тестового контура.
- Сейчас QA largely manual.

#### 3. Линтеры и валидаторы для email HTML

Очень полезны:

- детекторы локальных `src`/`href`
- детекторы placeholder-ссылок (`href="#"`)
- детекторы merge conflict markers
- link checker для UTM/canonical URLs
- правила валидации footer/legal/privacy/unsubscribe
- инструменты, проверяющие broken asset URLs на CDN

Почему:
- Эти проблемы уже реально присутствуют в репозитории.

#### 4. Инструменты для работы с ассетами и CDN

Полезны:

- image optimization для email
- GIF compression/optimization
- asset path validators
- инструменты публикации статических файлов на CDN
- cache-busting/versioning strategies для jsDelivr/GitHub assets

Почему:
- Письма heavily depend on external asset delivery.
- Ошибки в CDN-путях или слишком тяжёлые GIF напрямую ухудшают результат.

#### 5. Инструменты для подготовки контента из PDF/презентаций/референсов

Полезны:

- PDF/PPT/image text extraction
- image slicing/export helpers
- tools for turning presentation pages into reusable email assets
- OCR и контент-extraction utilities для маркетинговых референсов

Почему:
- В новых кампаниях реально используются `ref/`, `PNG_исходники/`, PDF и презентационные материалы.

#### 6. ESP/сервисы рассылок, которые не ломают HTML

Особенно полезны новости о сервисах, которые:

- не переписывают `@font-face`
- не портят кастомный HTML
- сохраняют inline styles
- дают browser-view links
- поддерживают корректную подстановку unsubscribe
- нормально работают с русским B2B email-маркетингом

Почему:
- Исторически зафиксирована проблема с Unisender.
- Для проекта критичны шрифты, layout fidelity и полное сохранение ручной вёрстки.

#### 7. Инструменты локализации и RU/ENG consistency checking

Полезны:

- двуязычные QA-инструменты
- diff tools для RU/ENG HTML
- link parity checks
- translation QA для marketing copy

Почему:
- Проект регулярно делает ENG версии.
- Сейчас встречаются расхождения по контактам, доменам и ссылкам.

#### 8. Инструменты управления шаблонами и reusable blocks

Полезны:

- partial/template systems, если они умеют генерировать именно email-safe HTML
- block libraries для header/footer/CTA/USP cards
- безопасные preprocessor-инструменты для email, а не обычного веба

Почему:
- В проекте сильное копирование из прошлых кампаний.
- Нет общего canonical template engine.

#### 9. Git/content-ops инструменты для статических маркетинговых репозиториев

Полезны:

- pre-commit checks
- content repository hygiene tools
- duplicate detection
- canonical-file detection
- repo organization aids for design-heavy static projects

Почему:
- В репозитории много дублей и конкурирующих версий.

### Какие задачи сейчас решаются неоптимально

1. Проверка финальности письма
- Сейчас сложно автоматически понять, какой файл в папке финальный.
- Нужны canonical markers, metadata или naming discipline.

2. Проверка ссылок
- Реально встречаются `href="#"`.
- Нужен автоматический контроль.

3. Проверка путей к шрифтам и ассетам
- Есть локальные font paths.
- Есть потенциально ошибочный `osq-eemail-assets`.

4. Проверка RU/ENG согласованности
- Контакты и домены не всегда унифицированы.

5. Проверка гигиены репозитория
- Есть merge conflict markers.
- Есть tool-generated duplicates.

6. Тестирование email rendering
- Почти полностью manual.

7. Повторное использование шаблонов
- Сейчас copy-paste from previous campaign.

### Какие технологии из стека особенно нуждаются в новостях/альтернативах

1. ESP / сервис отправки писем
- Особенно если сервис модифицирует HTML или шрифты.

2. CDN delivery strategy
- Новости про надёжную раздачу статики для email.

3. Font delivery in email
- Особенно custom fonts + fallbacks + client compatibility.

4. Email HTML authoring tooling
- Инструменты, которые помогают писать не web HTML, а именно email HTML.

5. QA automation for email
- Это один из самых явных незакрытых gaps.

### Типы инструментов, которые точно пригодятся

- библиотеки и генераторы для email-safe HTML/VML
- валидаторы email-ссылок и UTM-меток
- инструменты screenshot/regression testing для email-клиентов
- инструменты автоматического инлайнинга CSS для email
- оптимизаторы GIF/JPG/PNG для email
- PDF/PPT/image extraction tools
- визуальные diff tools для email-макетов
- детекторы broken CDN URLs
- инструменты проверки локальных путей в HTML
- инструменты сравнения RU и ENG версий
- контентные AI-инструменты, умеющие работать с табличной email-вёрсткой, а не только с “лендингами”
- сервисы рассылки, не переписывающие пользовательский HTML и `@font-face`
- repo hygiene tools для content-heavy static repositories

### Какие новости и инструменты полезны условно, а не всегда

- general-purpose AI code assistants
  Полезны только если умеют стабильно работать с email HTML и соблюдают проектные правила.

- новые фронтенд CSS-фреймворки
  Обычно бесполезны, если не адаптированы под email clients.

- static site generators
  Могут быть полезны только как источник templating/partials, если на выходе дают чистый email-safe HTML.

### Какие новости и инструменты точно НЕ пригодятся

Практически нерелевантны:

- мобильная разработка iOS/Android
- backend framework releases
- микросервисы и service mesh
- Kubernetes и container orchestration
- базы данных, ORM, SQL optimization
- blockchain / Web3 / crypto
- game dev
- AR/VR
- desktop app frameworks
- realtime messaging infrastructure
- auth/SSO platforms
- data warehouses / BI platforms
- LLM fine-tuning infrastructure для inference-serving
- MLOps платформы
- browser SPA frameworks как React/Vue/Angular news сами по себе
- CSS utility frameworks типа Tailwind в обычном web-смысле
- browser performance optimization для web apps

Причина:
- В проекте нет приложения, backend, БД или runtime AI-платформы.
- Конечный артефакт здесь — статический HTML email и ассеты для него.

### Как внешней AI-системе отличать релевантную новость от шума

Новость, инструмент или технология релевантны, если они улучшают хотя бы одно из следующего:

- качество и устойчивость HTML email в проблемных клиентах
- скорость сборки письма из референсов
- проверку ссылок, ассетов и footer/legal элементов
- RU/ENG consistency
- публикацию ассетов на CDN
- отсутствие поломок в Outlook/Yandex/Gmail
- сохранение кастомного HTML и брендовых шрифтов в ESP
- повторное использование шаблонных блоков без риска сломать email compatibility

Новость нерелевантна, если она не влияет ни на один из этих аспектов.

