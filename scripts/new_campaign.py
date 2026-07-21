#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Этап 1 пайплайна: создание новой кампании из архива клиента.

Использование (из корня проекта):
  python scripts/new_campaign.py <путь-к-архиву-или-папке> <slug> [--date YYYY-MM-DD]

Пример:
  python scripts/new_campaign.py "C:/Users/user/Downloads/pillowl.rar" pillow

Что делает:
  1. Создаёт папку YYYY-MM-DD-osq-email-<slug>/ с подпапками ref/ и images/.
  2. Распаковывает архив (rar/zip/7z) или копирует папку в ref/
     (ref/ в git не попадает — см. .gitignore).
  3. Копирует templates/email-skeleton.html в index.html кампании,
     подставляя {{UTM_CAMPAIGN}} и {{CDN_BASE}}.
  4. Создаёт BRIEF.md — шаблон разбора материалов (Этап 2).
"""

import argparse
import datetime as dt
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEVEN_ZIP = Path("C:/Program Files/7-Zip/7z.exe")
CDN_PREFIX = "https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main"

BRIEF_TEMPLATE = """# BRIEF: {folder}

Заполняется на Этапе 2 (изучение материалов клиента). Файл локальный по смыслу,
но лёгкий — можно коммитить.

## Продукты рассылки

| Продукт | Объём/размер | Фасовка | Ключевые свойства |
|---|---|---|---|
| … | … | … | … |

## Что есть в ref/ (инвентарь)

- Презентация: …
- Продуктовые рендеры (белый фон): …
- Lifestyle-фото: …
- Прочее: …

## Каких картинок НЕ хватает (план генерации, Этап 4)

| Блок письма | Формат | Что изображено | Референс контейнера из ref/ |
|---|---|---|---|
| HERO | 620x390 | … | … |

## Черновой план блоков (Этап 3)

1. HERO — …
2. INTRO — …
3. …

## Ссылки кампании

- Каталог/лендинг: …
- UTM campaign: {utm}
"""


def run(cmd):
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Команда {cmd[0]} завершилась с ошибкой:\n{res.stderr[:2000]}")
    return res.stdout


def main():
    ap = argparse.ArgumentParser(description="Создание новой кампании OSQ")
    ap.add_argument("source", help="Архив (rar/zip/7z) или папка с материалами клиента")
    ap.add_argument("slug", help="Короткое имя продукта латиницей, например pillow")
    ap.add_argument("--date", default=dt.date.today().isoformat(), help="Дата кампании YYYY-MM-DD")
    args = ap.parse_args()

    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", args.date):
        sys.exit("[error] --date должен быть в формате YYYY-MM-DD")
    slug = re.sub(r"[^a-z0-9-]", "-", args.slug.lower()).strip("-")
    folder_name = f"{args.date}-osq-email-{slug}"
    campaign = ROOT / folder_name
    ref_dir = campaign / "ref"
    img_dir = campaign / "images"

    source = Path(args.source)
    if not source.exists():
        sys.exit(f"[error] Источник не найден: {source}")

    ref_dir.mkdir(parents=True, exist_ok=True)
    img_dir.mkdir(parents=True, exist_ok=True)

    # --- Материалы клиента -> ref/ ---
    if source.is_dir():
        for item in source.iterdir():
            target = ref_dir / item.name
            if item.is_dir():
                shutil.copytree(item, target, dirs_exist_ok=True)
            else:
                shutil.copy2(item, target)
        print(f"[ok] Папка скопирована в {ref_dir}")
    else:
        if not SEVEN_ZIP.exists():
            sys.exit("[error] Не найден 7z.exe — установите 7-Zip")
        run([str(SEVEN_ZIP), "x", "-y", str(source), f"-o{ref_dir}"])
        print(f"[ok] Архив распакован в {ref_dir}")

    # --- Скелет письма ---
    skeleton = ROOT / "templates" / "email-skeleton.html"
    index = campaign / "index.html"
    if index.exists():
        print(f"[skip] {index} уже существует — не перезаписываю")
    else:
        html = skeleton.read_text(encoding="utf-8")
        utm = f"{slug}_{args.date.replace('-', '_')}"
        html = html.replace("{{CDN_BASE}}", f"{CDN_PREFIX}/{folder_name}")
        html = html.replace("{{UTM_CAMPAIGN}}", utm)
        index.write_text(html, encoding="utf-8")
        print(f"[ok] Скелет письма: {index}")

    # --- BRIEF ---
    brief = campaign / "BRIEF.md"
    if not brief.exists():
        utm = f"{slug}_{args.date.replace('-', '_')}"
        brief.write_text(BRIEF_TEMPLATE.format(folder=folder_name, utm=utm), encoding="utf-8")
        print(f"[ok] Шаблон брифа: {brief}")

    print()
    print(f"Кампания создана: {campaign}")
    print("Дальше (Этап 2): изучить ref/, заполнить BRIEF.md, показать пользователю план блоков.")


if __name__ == "__main__":
    main()
