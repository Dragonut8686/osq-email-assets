#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Пре-флайт проверка письма перед деплоем/загрузкой в Unisender.

Использование:
  python scripts/check_email.py <папка-кампании-или-index.html> [--online]

--online  дополнительно проверяет каждую CDN-ссылку HTTP-запросом (HEAD).

Выход: код 0 если нет ошибок (предупреждения допустимы), 1 если есть ошибки.
"""

import argparse
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CDN_PREFIX = "https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/"

MAX_SIZE_ERROR = 100 * 1024  # Gmail обрезает после ~102KB
MAX_SIZE_WARN = 90 * 1024


def check(path, online=False):
    p = Path(path)
    if p.is_dir():
        p = p / "index.html"
    if not p.exists():
        print(f"[error] Файл не найден: {p}")
        return 1

    html = p.read_text(encoding="utf-8", errors="ignore")
    errors, warns = [], []

    # 1. Размер
    size = p.stat().st_size
    if size > MAX_SIZE_ERROR:
        errors.append(f"HTML весит {size//1024} KB — Gmail обрежет письмо (лимит ~102 KB)")
    elif size > MAX_SIZE_WARN:
        warns.append(f"HTML весит {size//1024} KB — близко к лимиту Gmail, целевой запас 90 KB")
    else:
        print(f"[ok] Вес HTML: {size//1024} KB")

    # 2. Остатки шаблона (макросы Unisender — не ошибка)
    UNISENDER_MACROS = {"{{ReadUrl}}", "{{UnsubscribeUrl}}", "{{SubscribeUrl}}"}
    leftovers = sorted(
        t for t in set(re.findall(r"\{\{[^}]{0,60}\}\}", html))
        if t not in UNISENDER_MACROS
    )
    if leftovers:
        errors.append("Остались плейсхолдеры шаблона: " + ", ".join(leftovers[:10]))
    if "Плейсхолдер" in html or "плейсхолдер" in html:
        warns.append("В письме остались серые плейсхолдеры картинок (ок для Этапа 3, ошибка для финала)")
    for marker in ("TODO", "FIXME", "lorem"):
        if marker.lower() in html.lower():
            warns.append(f"Найден маркер '{marker}' — проверить")

    # 3. Локальные src
    local_src = re.findall(r'src="(?!https?://|data:)([^"]+)"', html)
    if local_src:
        errors.append(f"Локальные src (нужны CDN-ссылки): {local_src[:5]}")

    # 4. Мёртвые ссылки
    if re.search(r'href="#"', html):
        errors.append('Найдены href="#" — «В браузере»/«Отписаться» должны получить реальные ссылки или макросы Unisender')
    http_links = re.findall(r'(?:href|src)="(http://[^"]+)"', html)
    if http_links:
        warns.append(f"Ссылки без https: {http_links[:3]}")

    # 5. CDN-ссылки должны существовать локально
    cdn_urls = sorted(set(re.findall(re.escape(CDN_PREFIX) + r'[^")\s\']+', html)))
    missing_local = []
    for url in cdn_urls:
        rel = url[len(CDN_PREFIX):]
        rel = rel.split("?")[0]
        if not (ROOT / rel).exists():
            missing_local.append(rel)
    if missing_local:
        errors.append(f"CDN-ссылки на несуществующие локально файлы: {missing_local[:8]}")
    else:
        print(f"[ok] CDN-ссылок: {len(cdn_urls)}, все файлы существуют локально")

    # 6. alt у контентных картинок
    for m in re.finditer(r"<img\b[^>]*>", html):
        tag = m.group(0)
        alt = re.search(r'alt="([^"]*)"', tag)
        w = re.search(r'width="?(\d+)', tag)
        width = int(w.group(1)) if w else 0
        if alt is None:
            errors.append(f"<img> без alt: {tag[:80]}...")
        elif alt.group(1) == "" and width > 60:
            warns.append(f"Крупная картинка (width={width}) с пустым alt")

    # 7. Типографика под зум (мобильная Я.Почта): смысловой текст < 16px
    small = []
    for m in re.finditer(r"font-size:\s*(\d+)px", html):
        if int(m.group(1)) < 12:
            small.append(m.group(1))
    if small:
        warns.append(
            f"Найдены кегли меньше 12px ({len(small)} шт) — допустимо только для юр.сносок; "
            "смысловой текст должен быть ≥16px (правило зума Я.Почты)"
        )

    # 8. Прехедер и vk-snippet
    if "vk-snippet-end" not in html:
        warns.append("Нет <vk-snippet-end/> в прехедере")
    if 'class="preheader"' not in html:
        warns.append("Нет блока preheader")

    # 9. UTM
    if "utm_campaign=" not in html:
        warns.append("Нет utm_campaign в ссылках")

    # 10. Онлайн-проверка CDN (после деплоя)
    if online:
        print(f"[..] Проверяю {len(cdn_urls)} CDN-ссылок онлайн...")
        for url in cdn_urls:
            try:
                req = urllib.request.Request(url, method="HEAD")
                with urllib.request.urlopen(req, timeout=20) as resp:
                    if resp.status >= 400:
                        errors.append(f"CDN {resp.status}: {url}")
            except Exception as e:
                errors.append(f"CDN недоступен: {url} ({e})")
        print("[ok] Онлайн-проверка завершена")

    print()
    for w in warns:
        print(f"[warn] {w}")
    for e in errors:
        print(f"[ERROR] {e}")
    print()
    print(f"Итог: {len(errors)} ошибок, {len(warns)} предупреждений — {p}")
    return 1 if errors else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--online", action="store_true")
    args = ap.parse_args()
    sys.exit(check(args.path, args.online))
