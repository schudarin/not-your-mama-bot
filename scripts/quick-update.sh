#!/bin/bash

# Быстрое обновление кода бота без переустановки
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

echo "🔄 Быстрое обновление Not Your Mama Bot"
echo "======================================="
echo ""

# Определяем где находится бот
if [ -f "/opt/not-your-mama-bot/bot.py" ]; then
    BOT_DIR="/opt/not-your-mama-bot"
    INSTALL_TYPE="systemd"
    print_info "Обнаружена systemd установка"
    
    if [ "$EUID" -ne 0 ]; then
        print_warning "Для systemd установки нужны права sudo"
        print_info "Используйте: sudo ./scripts/quick-update.sh"
        exit 1
    fi
elif [ -f "bot.py" ]; then
    BOT_DIR="$(pwd)"
    INSTALL_TYPE="local"
    print_info "Обнаружена локальная установка"
else
    print_error "Бот не найден!"
    exit 1
fi

print_info "Директория бота: $BOT_DIR"
print_info "Тип установки: $INSTALL_TYPE"
echo ""

# Останавливаем сервис если systemd
if [ "$INSTALL_TYPE" = "systemd" ]; then
    print_info "Останавливаем systemd сервис..."
    systemctl stop not-your-mama-bot || true
fi

# Переходим в директорию бота
cd "$BOT_DIR"

# Обновляем код из git
print_info "Обновление кода из git..."
if git pull origin master; then
    print_success "Код обновлен"
else
    print_error "Ошибка обновления кода"
    exit 1
fi

# Проверяем что bot.py обновился
if [ ! -f "bot.py" ]; then
    print_error "Файл bot.py не найден после обновления"
    exit 1
fi

# Запускаем сервис если systemd
if [ "$INSTALL_TYPE" = "systemd" ]; then
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
else
    print_info "Для локальной установки запустите бота вручную:"
    echo "  ./scripts/run-bot.sh"
fi

echo ""
print_success "🎉 Обновление завершено успешно!"
print_info "Бот должен работать с исправлениями!"
