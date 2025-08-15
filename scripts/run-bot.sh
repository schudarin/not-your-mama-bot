#!/bin/bash

# Скрипт для запуска Not Your Mama Bot
# Автоматически определяет тип установки и запускает бота

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

echo "🤖 Запуск Not Your Mama Bot..."
echo ""

# Определяем где находится бот
BOT_DIR=""
VENV_PATH=""
ENV_PATH=""

# Проверяем systemd установку
if [ -f "/opt/not-your-mama-bot/bot.py" ]; then
    BOT_DIR="/opt/not-your-mama-bot"
    VENV_PATH="/opt/not-your-mama-bot/venv"
    ENV_PATH="/opt/not-your-mama-bot/.env"
    INSTALL_TYPE="systemd"
    print_info "Обнаружена systemd установка в /opt/not-your-mama-bot"
    
    # Проверяем права доступа
    if [ "$EUID" -ne 0 ]; then
        print_warning "Для systemd установки нужны права sudo"
        print_info "Используйте: sudo ./scripts/run-bot.sh"
        exit 1
    fi
elif [ -f "bot.py" ]; then
    BOT_DIR="$(pwd)"
    VENV_PATH="$(pwd)/venv"
    ENV_PATH="$(pwd)/.env"
    INSTALL_TYPE="local"
    print_info "Обнаружена локальная установка в $(pwd)"
else
    print_error "Бот не найден!"
    print_info "Возможные причины:"
    echo "  1. Вы не в правильной директории"
    echo "  2. Бот не установлен"
    echo "  3. Установка повреждена"
    echo ""
    print_info "Что делать:"
    echo "  1. Перейдите в папку с ботом"
    echo "  2. Или запустите установщик: ./scripts/install.sh"
    exit 1
fi

print_info "Тип установки: $INSTALL_TYPE"
print_info "Директория бота: $BOT_DIR"
echo ""

# Переходим в директорию бота
cd "$BOT_DIR"

# Проверяем виртуальное окружение
if [ ! -d "$VENV_PATH" ]; then
    print_error "Виртуальное окружение не найдено в $VENV_PATH"
    print_info "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

if [ ! -f "$VENV_PATH/bin/activate" ]; then
    print_error "Файл активации виртуального окружения не найден"
    print_info "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

# Проверяем .env файл
if [ ! -f "$ENV_PATH" ]; then
    print_error "Файл .env не найден в $ENV_PATH"
    print_info "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

# Проверяем bot.py
if [ ! -f "bot.py" ]; then
    print_error "Файл bot.py не найден в $BOT_DIR"
    print_info "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

# Активируем виртуальное окружение
print_info "Активация виртуального окружения..."
if ! source "$VENV_PATH/bin/activate"; then
    print_error "Ошибка активации виртуального окружения"
    exit 1
fi
print_success "Виртуальное окружение активировано"

# Проверяем ключевые модули
print_info "Проверка модулей..."
if ! python -c "import telegram" &> /dev/null; then
    print_error "Модуль python-telegram-bot не найден"
    print_info "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

if ! python -c "import ddgs" &> /dev/null; then
    print_error "Модуль ddgs не найден"
    print_info "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

if ! python -c "import openai" &> /dev/null; then
    print_error "Модуль openai не найден"
    print_info "Запустите установщик: ./scripts/install.sh"
    exit 1
fi

print_success "Все модули найдены"

# Запускаем бота
echo ""
print_success "Запуск бота..."
print_info "Для остановки нажмите Ctrl+C"
print_info "Логи будут показаны ниже:"
echo ""

python bot.py
