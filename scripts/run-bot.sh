#!/bin/bash

# Скрипт для запуска Not Your Mama Bot
# Автоматически активирует виртуальное окружение и запускает бота

echo "🤖 Запуск Not Your Mama Bot..."
echo ""

# Проверяем существование виртуального окружения
if [ ! -d "venv" ]; then
    echo "❌ Виртуальное окружение не найдено"
    echo "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

if [ ! -f "venv/bin/activate" ]; then
    echo "❌ Файл активации виртуального окружения не найден"
    echo "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

# Проверяем существование .env файла
if [ ! -f ".env" ]; then
    echo "❌ Файл .env не найден"
    echo "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

# Активируем виртуальное окружение и запускаем бота
echo "✅ Активация виртуального окружения..."
source venv/bin/activate

echo "✅ Запуск бота..."
echo "Для остановки нажмите Ctrl+C"
echo ""

python bot.py
