#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Деплой ассетов на GitHub + сброс кеша jsDelivr. Без интерактива (для агентов).
Ручной deploy.bat остаётся для запуска двойным кликом.

Использование (из корня проекта):
  python scripts/deploy.py                     # все изменения
  python scripts/deploy.py -m "своё сообщение"
  python scripts/deploy.py --no-purge          # не сбрасывать кеш jsDelivr

Что делает:
  1. git add -A; git commit; git push origin main
  2. Для всех изменённых в коммите png/jpg/gif/woff2/html файлов дёргает
     https://purge.jsdelivr.net/... — иначе jsDelivr до 12 часов отдаёт старую
     версию файла с тем же именем.
"""

import argparse
import datetime as dt
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PURGE_PREFIX = "https://purge.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/"
PURGE_EXT = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".woff", ".woff2", ".html"}


def git(*args, check=True):
    res = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    if check and res.returncode != 0:
        sys.exit(f"[error] git {' '.join(args)}:\n{res.stderr[:1500]}")
    return res.stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-m", "--message", default=None)
    ap.add_argument("--no-purge", action="store_true")
    args = ap.parse_args()

    git("add", "-A")
    staged = git("diff", "--staged", "--name-only")
    if not staged:
        print("[info] Нет изменений для коммита")
        return
    files = staged.splitlines()
    print(f"[..] Файлов к коммиту: {len(files)}")

    msg = args.message or f"Assets update {dt.datetime.now():%d.%m.%Y %H:%M}"
    git("commit", "-m", msg)

    # Пуш с авто-подтягиванием чужих коммитов (деплой бывает с двух машин)
    push = subprocess.run(["git", "push", "-u", "origin", "main"],
                          cwd=ROOT, capture_output=True, text=True)
    if push.returncode != 0 and "fetch first" in (push.stderr or ""):
        print("[..] На GitHub есть новые коммиты — подтягиваю (pull --rebase)")
        git("pull", "--rebase", "origin", "main")
        git("push", "-u", "origin", "main")
    elif push.returncode != 0:
        sys.exit(f"[error] git push:\n{push.stderr[:1500]}")
    print("[ok] Запушено на GitHub")

    if not args.no_purge:
        purged = 0
        for f in files:
            if Path(f).suffix.lower() in PURGE_EXT and not f.startswith("."):
                url = PURGE_PREFIX + urllib.parse.quote(f)
                try:
                    with urllib.request.urlopen(url, timeout=20) as resp:
                        resp.read()
                    purged += 1
                except Exception as e:
                    print(f"[warn] purge не удался для {f}: {e}")
        print(f"[ok] Кеш jsDelivr сброшен для {purged} файлов")

    print()
    print("CDN-база: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/")


if __name__ == "__main__":
    main()
