#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Извлечение текстового корпуса OSQ для стилевого профиля (skill osq-voice).

Источники:
  1. Telegram-выгрузка канала OSQ  -> docs/corpus/telegram-posts.md
  2. Все прошлые рассылки (index.html) -> docs/corpus/emails-text.md

Запуск из корня проекта:
  python scripts/extract_corpus.py

Скрипт перезаписывает файлы корпуса целиком — запускать после каждой
новой утверждённой рассылки, чтобы корпус оставался актуальным.
"""

import json
import re
import sys
from html import unescape
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "docs" / "corpus"


def find_telegram_json():
    """Самая свежая выгрузка Telegram: ChatExport_* или *telegram-export*."""
    candidates = []
    for pattern in ("ChatExport_*", "*telegram-export*"):
        for d in ROOT.glob(pattern):
            rj = d / "result.json"
            if rj.exists():
                candidates.append(rj)
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


TELEGRAM_JSON = find_telegram_json()

# Папки кампаний: YYYY-MM-DD-*
CAMPAIGN_RE = re.compile(r"^20\d{2}-\d{2}-\d{2}-")


def flatten_tg_text(text):
    """Telegram export хранит text либо строкой, либо списком кусков."""
    if isinstance(text, str):
        return text
    parts = []
    for chunk in text:
        if isinstance(chunk, str):
            parts.append(chunk)
        elif isinstance(chunk, dict):
            parts.append(chunk.get("text", ""))
    return "".join(parts)


def extract_telegram():
    if TELEGRAM_JSON is None or not TELEGRAM_JSON.exists():
        print("[skip] выгрузка Telegram не найдена (ChatExport_*/result.json)")
        return
    print(f"[info] Telegram-выгрузка: {TELEGRAM_JSON.parent.name}")
    data = json.loads(TELEGRAM_JSON.read_text(encoding="utf-8"))
    msgs = [m for m in data.get("messages", []) if m.get("type") == "message"]
    lines = [
        "# Корпус: посты Telegram-канала OSQ",
        "",
        f"Источник: {TELEGRAM_JSON.name}, всего сообщений: {len(msgs)}.",
        "Файл генерируется скриптом scripts/extract_corpus.py — не редактировать руками.",
        "",
    ]
    kept = 0
    for m in msgs:
        text = flatten_tg_text(m.get("text", "")).strip()
        if len(text) < 120:  # служебные и короткие посты не нужны для стиля
            continue
        kept += 1
        date = (m.get("date") or "")[:10]
        lines.append(f"## Пост {kept} ({date})")
        lines.append("")
        lines.append(text)
        lines.append("")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / "telegram-posts.md"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"[ok] {out} — постов: {kept}")


class EmailTextParser(HTMLParser):
    """Достаёт видимый текст письма по микрожанрам."""

    SKIP_TAGS = {"style", "script", "title", "head"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.items = []  # (жанр, текст)
        self._stack = []
        self._buf = []
        self._genre = None
        self._skip_depth = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP_TAGS:
            self._skip_depth += 1
            return
        cls = dict(attrs).get("class", "") or ""
        if "preheader" in cls:
            self._start("preheader")
        elif tag == "h1":
            self._start("h1")
        elif tag in ("h2", "h3"):
            self._start(tag)
        elif tag == "p":
            self._start("p")
        elif tag == "a":
            self._start("a")
        elif tag == "span" and self._genre is None:
            self._start("badge")

    def handle_endtag(self, tag):
        if tag in self.SKIP_TAGS:
            self._skip_depth = max(0, self._skip_depth - 1)
            return
        if self._genre and tag in ("h1", "h2", "h3", "p", "a", "span", "div"):
            self._flush()

    def handle_data(self, data):
        if self._skip_depth:
            return
        if self._genre:
            self._buf.append(data)

    def _start(self, genre):
        self._flush()
        self._genre = genre
        self._buf = []

    def _flush(self):
        if self._genre:
            text = re.sub(r"\s+", " ", "".join(self._buf)).strip()
            if text and len(text) > 1:
                self.items.append((self._genre, text))
        self._genre = None
        self._buf = []


def extract_emails():
    campaigns = sorted(
        d for d in ROOT.iterdir() if d.is_dir() and CAMPAIGN_RE.match(d.name)
    )
    lines = [
        "# Корпус: тексты прошлых email-рассылок OSQ",
        "",
        "По микрожанрам: preheader, h1 (hero), h2/h3 (заголовки блоков), p (абзацы), a (ссылки/CTA).",
        "Файл генерируется скриптом scripts/extract_corpus.py — не редактировать руками.",
        "",
    ]
    total = 0
    for camp in campaigns:
        index = camp / "index.html"
        if not index.exists():
            continue
        html = index.read_text(encoding="utf-8", errors="ignore")
        if "{{" in html:
            print(f"[skip] {camp.name}: письмо ещё не дособрано (есть плейсхолдеры)")
            continue
        title_m = re.search(r"<title>(.*?)</title>", html, re.S)
        parser = EmailTextParser()
        try:
            parser.feed(html)
        except Exception as e:  # битый HTML не должен ронять весь корпус
            print(f"[warn] {camp.name}: {e}")
            continue
        total += 1
        lines.append(f"## {camp.name}")
        lines.append("")
        if title_m:
            lines.append(f"- **title**: {unescape(title_m.group(1)).strip()}")
        for genre, text in parser.items:
            if genre == "a" and len(text) < 4:
                continue
            lines.append(f"- **{genre}**: {text}")
        lines.append("")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / "emails-text.md"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"[ok] {out} — кампаний: {total}")


if __name__ == "__main__":
    try:
        extract_telegram()
        extract_emails()
    except Exception as e:
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)
