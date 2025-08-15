#!/bin/bash

# Скрипт обновления для read-only файловой системы
set -e

echo "🔄 Not Your Mama Bot - Обновление (Read-Only режим)"
echo "=================================================="

# Определяем где находится systemd установка
SYSTEMD_DIR="/opt/not-your-mama-bot"
CURRENT_DIR=$(pwd)

# Если мы не в systemd директории, но она существует - переходим туда
if [ "$CURRENT_DIR" != "$SYSTEMD_DIR" ] && [ -f "$SYSTEMD_DIR/bot.py" ]; then
    echo "📍 Переходим в systemd директорию: $SYSTEMD_DIR"
    cd "$SYSTEMD_DIR"
fi

# Проверяем, что мы в правильной директории
if [ ! -f "bot.py" ]; then
    echo "❌ Файл bot.py не найден. Убедитесь, что вы находитесь в корневой папке проекта."
    exit 1
fi

# Проверяем права на запись
if [ ! -w . ]; then
    echo "⚠️  Файловая система доступна только для чтения"
    echo "📋 Доступные действия:"
    echo "• Проверка текущей версии"
    echo "• Перезапуск службы (если доступно)"
    echo "• Информация о системе"
    
    # Показываем информацию о текущей версии
    if [ -d ".git" ]; then
        echo ""
        echo "📊 Информация о версии:"
        git log --oneline -5
        echo ""
        echo "📍 Текущий коммит: $(git rev-parse --short HEAD)"
    fi
    
    # Проверяем, запущена ли служба systemd
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet not-your-mama-bot; then
            echo "✅ Служба not-your-mama-bot активна"
            echo "🔄 Попытка перезапуска службы..."
            if sudo systemctl restart not-your-mama-bot; then
                echo "✅ Служба успешно перезапущена"
            else
                echo "❌ Не удалось перезапустить службу"
            fi
        else
            echo "❌ Служба not-your-mama-bot не активна"
        fi
    fi
    
    echo ""
    echo "💡 Для полного обновления:"
    echo "• Подключитесь по SSH к серверу"
    echo "• Выполните: cd /opt/not-your-mama-bot && git pull"
    echo "• Перезапустите службу: sudo systemctl restart not-your-mama-bot"
    
    exit 0
fi

# Если есть права на запись, выполняем обычное обновление
echo "✅ Файловая система доступна для записи"
echo "🔄 Выполняем обычное обновление..."

# Запускаем основной скрипт обновления
if [ -f "scripts/update.sh" ]; then
    bash scripts/update.sh
else
    echo "❌ Основной скрипт обновления не найден"
    exit 1
fi
