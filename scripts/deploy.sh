#!/bin/bash

# Скрипт развертывания Not Your Mama Bot
set -e

echo "🤖 Not Your Mama Bot - Скрипт развертывания"
echo "=========================================="

# Проверяем, установлен ли Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 не установлен. Пожалуйста, установите Python 3.8+ сначала."
    exit 1
fi

# Проверяем, установлен ли pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 не установлен. Пожалуйста, установите pip сначала."
    exit 1
fi

echo "✅ Python и pip найдены"

# Создаем виртуальное окружение, если оно не существует
if [ ! -d "venv" ]; then
    echo "📦 Создание виртуального окружения..."
    python3 -m venv venv
fi

# Активируем виртуальное окружение
echo "🔧 Активация виртуального окружения..."
source venv/bin/activate

# Устанавливаем зависимости
echo "📚 Установка зависимостей..."
pip install -r requirements.txt

# Проверяем переменные окружения
echo "🔍 Проверка переменных окружения..."
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "⚠️  TELEGRAM_BOT_TOKEN не установлен. Установите его:"
    echo "   export TELEGRAM_BOT_TOKEN='ваш_токен_здесь'"
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY не установлен. Установите его:"
    echo "   export OPENAI_API_KEY='ваш_ключ_здесь'"
fi

if [ -z "$BOT_USERNAME" ]; then
    echo "⚠️  BOT_USERNAME не установлен. Установите его:"
    echo "   export BOT_USERNAME='имя_вашего_бота'"
fi

# Проверяем, установлены ли все необходимые переменные окружения
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$OPENAI_API_KEY" ] || [ -z "$BOT_USERNAME" ]; then
    echo ""
    echo "❌ Отсутствуют необходимые переменные окружения."
    echo "Пожалуйста, установите все необходимые переменные и запустите скрипт снова."
    echo ""
    echo "Вы также можете скопировать env.example в .env и отредактировать его:"
    echo "   cp env.example .env"
    echo "   # Отредактируйте .env с вашими значениями"
    echo "   source .env"
    exit 1
fi

echo "✅ Все переменные окружения установлены"

# Запускаем бота
echo "🚀 Запуск бота..."
echo "Нажмите Ctrl+C для остановки"
python bot.py
