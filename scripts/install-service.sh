#!/bin/bash

# Скрипт установки systemd сервиса для Not Your Mama Bot
set -e

echo "🔧 Установка systemd сервиса для Not Your Mama Bot"
echo "================================================="

# Проверяем права root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Проверяем наличие переменных окружения
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$OPENAI_API_KEY" ] || [ -z "$BOT_USERNAME" ]; then
    echo "❌ Необходимо установить переменные окружения:"
    echo "   export TELEGRAM_BOT_TOKEN='ваш_токен'"
    echo "   export OPENAI_API_KEY='ваш_ключ'"
    echo "   export BOT_USERNAME='имя_бота'"
    exit 1
fi

# Создаем пользователя для бота
if ! id "botuser" &>/dev/null; then
    echo "👤 Создание пользователя botuser..."
    useradd -r -s /bin/false -d /opt/not-your-mama-bot botuser
fi

# Создаем директорию для бота
echo "📁 Создание директории для бота..."
mkdir -p /opt/not-your-mama-bot
mkdir -p /opt/not-your-mama-bot/logs

# Копируем файлы бота
echo "📋 Копирование файлов бота..."
cp -r . /opt/not-your-mama-bot/
chown -R botuser:botuser /opt/not-your-mama-bot

# Создаем виртуальное окружение
echo "🐍 Создание виртуального окружения..."
cd /opt/not-your-mama-bot
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Устанавливаем systemd сервис
echo "⚙️  Установка systemd сервиса..."
cp not-your-mama-bot.service /etc/systemd/system/

# Создаем файл с переменными окружения
cat > /opt/not-your-mama-bot/.env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
BOT_USERNAME=$BOT_USERNAME
EOF

chown botuser:botuser /opt/not-your-mama-bot/.env
chmod 600 /opt/not-your-mama-bot/.env

# Перезагружаем systemd и включаем сервис
echo "🔄 Перезагрузка systemd..."
systemctl daemon-reload

echo "🚀 Включение и запуск сервиса..."
systemctl enable not-your-mama-bot
systemctl start not-your-mama-bot

# Проверяем статус
echo "📊 Проверка статуса сервиса..."
systemctl status not-your-mama-bot --no-pager -l

echo ""
echo "✅ Установка завершена!"
echo ""
echo "📋 Полезные команды:"
echo "   sudo systemctl status not-your-mama-bot    # Статус сервиса"
echo "   sudo systemctl restart not-your-mama-bot   # Перезапуск"
echo "   sudo systemctl stop not-your-mama-bot      # Остановка"
echo "   sudo journalctl -u not-your-mama-bot -f    # Просмотр логов"
echo ""
echo "🔄 Для обновления бота используйте:"
echo "   cd /opt/not-your-mama-bot && ./update.sh"
