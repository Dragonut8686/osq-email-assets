#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Этап 6 пайплайна: загрузка готового письма в аккаунт Unisender (классический).

Требуется UNISENDER_API_KEY в .env (берётся в ЛК: Настройки -> Интеграция и API).

Использование:
  # Загрузить как ШАБЛОН (проще всего, появится в "Шаблоны"):
  python scripts/unisender_push.py template <папка-кампании|index.html> --subject "Тема письма"

  # Загрузить как ПИСЬМО-черновик (появится в "Письма", готово к кампании):
  python scripts/unisender_push.py message <папка> --subject "Тема" --list-id 123 \
      --sender-name "OSQ Group" --sender-email news@osqgroup.ru

  # Список списков рассылки (узнать list_id):
  python scripts/unisender_push.py lists

  # Тестовая отправка созданного письма:
  python scripts/unisender_push.py test --message-id 12345 --email you@mail.ru

Замечания:
  - sender_email должен быть заранее подтверждён в аккаунте Unisender.
  - Перед загрузкой скрипт автоматически прогоняет check_email.py (без --online).
  - Плейсхолдеры {{BROWSER_URL}} и {{UNSUBSCRIBE_URL}} в HTML заменяются
    на макросы Unisender {{ReadUrl}} и {{UnsubscribeUrl}} автоматически.
"""

import argparse
import json
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
API = "https://api.unisender.com/ru/api/"


def load_env():
    env = {}
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, _, v = line.partition("=")
                env[k.strip()] = v.strip()
    return env


def api_call(method, **params):
    env = load_env()
    key = env.get("UNISENDER_API_KEY")
    if not key:
        sys.exit(
            "[error] UNISENDER_API_KEY пуст. Возьмите ключ в ЛК Unisender:\n"
            "  клик по email внизу слева -> Настройки -> Интеграция и API -> Показать полностью,\n"
            "  и впишите в .env строкой UNISENDER_API_KEY=..."
        )
    params["api_key"] = key
    params["format"] = "json"
    data = urllib.parse.urlencode(params).encode("utf-8")
    req = urllib.request.Request(API + method, data=data, method="POST")
    with urllib.request.urlopen(req, timeout=60) as resp:
        payload = json.loads(resp.read().decode("utf-8"))
    if "error" in payload:
        sys.exit(f"[error] Unisender {method}: {payload.get('error')} (code: {payload.get('code')})")
    return payload.get("result")


def read_html(path):
    p = Path(path)
    if p.is_dir():
        p = p / "index.html"
    if not p.exists():
        sys.exit(f"[error] Не найден HTML: {p}")

    html = p.read_text(encoding="utf-8")
    # Макросы Unisender вместо плейсхолдеров шаблона
    html = html.replace("{{BROWSER_URL}}", "{{ReadUrl}}")
    html = html.replace("{{UNSUBSCRIBE_URL}}", "{{UnsubscribeUrl}}")

    # Пре-флайт проверка уже подготовленной версии (через временный файл,
    # чтобы макросы Unisender не считались остатками шаблона)
    tmp = p.parent / ".unisender_tmp.html"
    tmp.write_text(html, encoding="utf-8")
    try:
        chk = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "check_email.py"), str(tmp)],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        print(chk.stdout)
        if chk.returncode != 0:
            sys.exit("[error] check_email.py нашёл ошибки — исправьте перед загрузкой (см. выше)")
    finally:
        tmp.unlink(missing_ok=True)
    return html, p


def main():
    ap = argparse.ArgumentParser(description="Загрузка письма в Unisender")
    ap.add_argument("mode", choices=["template", "message", "lists", "test"])
    ap.add_argument("path", nargs="?", help="Папка кампании или index.html")
    ap.add_argument("--subject", help="Тема письма")
    ap.add_argument("--title", help="Название шаблона (для mode=template)")
    ap.add_argument("--list-id", help="ID списка рассылки (для mode=message)")
    ap.add_argument("--sender-name", default="OSQ Group")
    ap.add_argument("--sender-email", help="Подтверждённый адрес отправителя")
    ap.add_argument("--message-id", help="ID письма (для mode=test)")
    ap.add_argument("--email", help="Адрес(а) для тестовой отправки, через запятую")
    args = ap.parse_args()

    if args.mode == "lists":
        lists = api_call("getLists")
        for l in lists:
            print(f"  list_id={l['id']}  {l['title']}")
        return

    if args.mode == "test":
        if not (args.message_id and args.email):
            sys.exit("[error] Нужны --message-id и --email")
        api_call("sendTestEmail", id=args.message_id, email=args.email)
        print(f"[ok] Тест отправлен на {args.email}")
        return

    if not args.path or not args.subject:
        sys.exit("[error] Нужны путь к письму и --subject")
    html, p = read_html(args.path)

    if args.mode == "template":
        title = args.title or p.parent.name
        result = api_call(
            "createEmailTemplate",
            title=title, subject=args.subject, body=html, lang="ru",
        )
        print(f"[ok] Шаблон создан: template_id={result.get('template_id')} (раздел «Шаблоны» в ЛК)")

    elif args.mode == "message":
        if not args.list_id:
            lists = api_call("getLists")
            if len(lists) == 1:
                args.list_id = str(lists[0]["id"])
                print(f"[info] Использую единственный список: {lists[0]['title']} ({args.list_id})")
            else:
                print("Доступные списки:")
                for l in lists:
                    print(f"  list_id={l['id']}  {l['title']}")
                sys.exit("[error] Укажите --list-id из списка выше")
        if not args.sender_email:
            sys.exit("[error] Укажите --sender-email (подтверждённый в Unisender адрес)")
        result = api_call(
            "createEmailMessage",
            sender_name=args.sender_name, sender_email=args.sender_email,
            subject=args.subject, body=html, list_id=args.list_id,
            generate_text=1, lang="ru",
        )
        print(f"[ok] Письмо создано: message_id={result.get('message_id')} (раздел «Письма» в ЛК)")
        print("    Тест: python scripts/unisender_push.py test --message-id "
              f"{result.get('message_id')} --email адрес@почта.ру")


if __name__ == "__main__":
    main()
