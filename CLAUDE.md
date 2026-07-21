# CLAUDE.md

Всегда отвечай на русском, давай комментарии на русском.

Проект: email-ассеты OSQ (производитель экологичной пищевой упаковки).
Каждая рассылка — папка `YYYY-MM-DD-osq-email-<slug>/` с `index.html`,
`images/` и локальной `ref/` (материалы клиента, в git не попадает).
Ассеты деплоятся на GitHub и раздаются через jsDelivr CDN.

## Система (единая для Claude Code и Codex)

Перед любой работой над рассылкой прочитай:

1. **`.claude/skills/osq-campaign/SKILL.md`** — пайплайн этапов 1–6:
   приём архива → изучение → скелет (чекпойнт пользователя) → картинки →
   видео/GIF → Unisender. Там же: жёсткие константы вёрстки, «правило зума»
   мобильной Я.Почты, типографика v2, правила генерации картинок контейнеров.
2. **`.claude/skills/osq-voice/SKILL.md`** + `references/` — голос бренда
   для ВСЕХ текстов (профиль, лексикон, примеры, анти-примеры, чеклист).
3. **`AGENTS.md`** — детальные правила вёрстки (разделы 1–17).

## Быстрые команды

```bash
python scripts/new_campaign.py "<архив>" <slug>     # новая кампания из архива клиента
python scripts/check_email.py <папка> [--online]    # пре-флайт проверка письма
python scripts/deploy.py                            # git push + сброс кеша jsDelivr
python scripts/video2gif.py <video.mp4>             # mp4 -> сжатый mp4 + email-GIF
python scripts/unisender_push.py message <папка> --subject "…" --list-id N --sender-email …
python scripts/extract_corpus.py                    # обновить корпус стиля после утверждения
```

## Ключевые константы (детали — в скилле osq-campaign)

- Эталон письма: `templates/email-skeleton.html` (создан из утверждённого
  `2026-07-06-osq-email-smart-bowl-620` + типографика v2 «под зум»).
- Контейнер 640px max / 320px min; карточки 620, радиус 32; фон #F6F7F8;
  акцент teal #00A499; футер светлый #EEF7F5 (тёмных блоков НЕ делать).
- HEADER / HERO-каркас / FOOTER — фиксированные из скелета, не переизобретать.
- Смысловой текст ≥16px на десктопе (основной 19–20, H2 34, кнопки 22 при
  max-width 300px) — мобильная Я.Почта игнорирует media queries и просто
  сжимает десктоп ×0.5625.
- Шрифты Qanelas и логотип/социконки — из `shared/fonts/`, `shared/images/`.
- Картинки кроме hero: 16:9 / 5:4 / 1:1. Генерация — скилл `image-gen`
  (GPT Image 2) строго с `--ref` рендера контейнера. SVG запрещён. Сцены светлые.
- Секреты — в `.env` (не коммитится). Ключи: UNISENDER_API_KEY, FREEPIK_API_KEY.
- CDN: `https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/<путь>`.

## Что где лежит

- `templates/email-skeleton.html` — канонический скелет письма
- `scripts/` — весь пайплайн (см. выше)
- `shared/` — общие шрифты и повторяющиеся картинки (лого, социконки)
- `docs/corpus/` — автогенерируемый корпус текстов для стиля
- `docs/AUDIT-2026-07.md` — аудит недостатков и план улучшений
- `Примеры/` — референсы больших брендов (Яндекс, Citilink, Lazarev)
- `old design/` — архив старых кампаний
