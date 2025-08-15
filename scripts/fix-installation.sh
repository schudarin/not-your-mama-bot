#!/bin/bash

# Скрипт для исправления существующей установки Not Your Mama Bot
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🔧 Исправление установки Not Your Mama Bot"
echo "=========================================="
echo ""

# Проверяем что мы в правильной директории
if [ ! -f "/opt/not-your-mama-bot/bot.py" ]; then
    print_error "Бот не найден в /opt/not-your-mama-bot/"
    print_info "Убедитесь что бот установлен через systemd"
    exit 1
fi

print_info "Переходим в директорию бота..."
cd /opt/not-your-mama-bot

# Останавливаем сервис
print_info "Останавливаем systemd сервис..."
systemctl stop not-your-mama-bot || true

# Проверяем виртуальное окружение
if [ ! -d "venv" ]; then
    print_error "Виртуальное окружение не найдено"
    print_info "Создаем новое виртуальное окружение..."
    
    if ! python3 -m venv venv; then
        print_error "Ошибка создания виртуального окружения"
        print_info "Попробуйте установить python3-venv:"
        echo "  apt-get install python3-venv python3.8-venv"
        exit 1
    fi
    print_success "Виртуальное окружение создано"
else
    print_info "Виртуальное окружение найдено"
fi

# Активируем виртуальное окружение
print_info "Активируем виртуальное окружение..."
if ! source venv/bin/activate; then
    print_error "Ошибка активации виртуального окружения"
    exit 1
fi
print_success "Виртуальное окружение активировано"

# Обновляем pip
print_info "Обновляем pip..."
if ! pip install --upgrade pip; then
    print_error "Ошибка обновления pip"
    exit 1
fi

# Устанавливаем зависимости
print_info "Устанавливаем зависимости..."
if ! pip install -r requirements.txt; then
    print_error "Ошибка установки зависимостей"
    exit 1
fi
print_success "Зависимости установлены"

# Проверяем установку ключевых модулей
print_info "Проверяем установку модулей..."
if pip show python-telegram-bot &> /dev/null; then
    print_success "python-telegram-bot установлен"
else
    print_error "python-telegram-bot не установлен"
    exit 1
fi

if pip show duckduckgo-search &> /dev/null; then
    print_success "duckduckgo-search установлен"
else
    print_error "duckduckgo-search не установлен"
    exit 1
fi

if pip show openai &> /dev/null; then
    print_success "openai установлен"
else
    print_error "openai не установлен"
    exit 1
fi

# Проверяем .env файл
if [ ! -f ".env" ]; then
    print_error ".env файл не найден"
    print_info "Создайте .env файл с необходимыми переменными:"
    echo "  TELEGRAM_BOT_TOKEN=ваш_токен"
    echo "  OPENAI_API_KEY=ваш_ключ"
    echo "  BOT_USERNAME=имя_бота"
    exit 1
else
    print_success ".env файл найден"
fi

# Устанавливаем права
print_info "Устанавливаем права доступа..."
chown -R botuser:botuser /opt/not-your-mama-bot
chmod 600 .env

# Запускаем сервис
print_info "Запускаем systemd сервис..."
systemctl start not-your-mama-bot

# Проверяем статус
sleep 2
if systemctl is-active --quiet not-your-mama-bot; then
    print_success "Сервис успешно запущен!"
    print_info "Статус сервиса:"
    systemctl status not-your-mama-bot --no-pager -l
else
    print_error "Сервис не запустился"
    print_info "Проверьте логи:"
    echo "  journalctl -u not-your-mama-bot -n 20 --no-pager"
    exit 1
fi

echo ""
print_success "🎉 Исправление завершено успешно!"
print_info "Бот должен работать. Проверьте в Telegram!"
