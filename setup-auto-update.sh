#!/bin/bash

# Скрипт настройки автоматических обновлений для Not Your Mama Bot
set -e

echo "🤖 Настройка автоматических обновлений Not Your Mama Bot"
echo "======================================================="

# Проверяем права root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# Проверяем, что бот установлен
if [ ! -d "/opt/not-your-mama-bot" ]; then
    echo "❌ Бот не установлен. Сначала запустите install-service.sh"
    exit 1
fi

echo "📋 Доступные варианты автоматического обновления:"
echo "1) Каждый час"
echo "2) Каждые 6 часов"
echo "3) Каждый день в 3:00"
echo "4) Каждую неделю в воскресенье в 2:00"
echo "5) Отключить автоматические обновления"
echo ""

read -p "Выберите вариант (1-5): " choice

case $choice in
    1)
        CRON_SCHEDULE="0 * * * *"
        DESCRIPTION="каждый час"
        ;;
    2)
        CRON_SCHEDULE="0 */6 * * *"
        DESCRIPTION="каждые 6 часов"
        ;;
    3)
        CRON_SCHEDULE="0 3 * * *"
        DESCRIPTION="каждый день в 3:00"
        ;;
    4)
        CRON_SCHEDULE="0 2 * * 0"
        DESCRIPTION="каждую неделю в воскресенье в 2:00"
        ;;
    5)
        echo "🗑️  Удаление автоматических обновлений..."
        crontab -u botuser -l 2>/dev/null | grep -v "update.sh" | crontab -u botuser -
        echo "✅ Автоматические обновления отключены"
        exit 0
        ;;
    *)
        echo "❌ Неверный выбор"
        exit 1
        ;;
esac

echo "🔄 Настройка обновления $DESCRIPTION..."

# Создаем скрипт для cron
cat > /opt/not-your-mama-bot/cron-update.sh << 'EOF'
#!/bin/bash
cd /opt/not-your-mama-bot
./update.sh >> /opt/not-your-mama-bot/logs/update.log 2>&1
EOF

chmod +x /opt/not-your-mama-bot/cron-update.sh
chown botuser:botuser /opt/not-your-mama-bot/cron-update.sh

# Добавляем задачу в crontab для пользователя botuser
(crontab -u botuser -l 2>/dev/null | grep -v "cron-update.sh"; echo "$CRON_SCHEDULE /opt/not-your-mama-bot/cron-update.sh") | crontab -u botuser -

echo "✅ Автоматическое обновление настроено на $DESCRIPTION"
echo ""
echo "📋 Информация:"
echo "   Логи обновлений: /opt/not-your-mama-bot/logs/update.log"
echo "   Просмотр логов: tail -f /opt/not-your-mama-bot/logs/update.log"
echo "   Текущие задачи cron: crontab -u botuser -l"
echo ""
echo "🔄 Для отключения автоматических обновлений запустите этот скрипт снова и выберите вариант 5"
