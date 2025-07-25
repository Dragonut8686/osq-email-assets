#!/bin/bash

echo "========================================="
echo "   OSQ Email Assets - Auto Deploy"
echo "========================================="

# Получаем текущую дату и время
timestamp=$(date "+%d.%m.%Y %H:%M:%S")

echo "Текущее время: $timestamp"
echo ""

# Проверяем, инициализирован ли git
if [ ! -d ".git" ]; then
    echo "Инициализация Git репозитория..."
    git init
    git remote add origin https://github.com/Dragonut8686/osq-email-assets.git
    echo ""
fi

# Добавляем все файлы (включая структуру папок)
echo "Добавление файлов..."
git add .

# Проверяем есть ли изменения
if git diff --staged --quiet; then
    echo "Нет изменений для коммита."
    exit 0
fi

# Делаем коммит с автоматическим сообщением
echo "Создание коммита..."
git commit -m "Assets update $timestamp"

# Отправляем на GitHub
echo "Отправка на GitHub..."
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "   ✅ Успешно загружено на GitHub!"
    echo "========================================"
    echo ""
    echo "Ваши ссылки для текущего проекта 2025-07-25-osq-email:"
    echo "📁 Шрифты: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/fonts/"
    echo "🖼️ Изображения: https://cdn.jsdelivr.net/gh/Dragonut8686/osq-email-assets@main/2025-07-25-osq-email/images/"
    echo ""
    echo "Для других проектов просто замените дату в URL"
    echo ""
else
    echo ""
    echo "❌ Ошибка при загрузке!"
    echo "Проверьте подключение к интернету и права доступа."
    echo ""
fi 