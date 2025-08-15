#!/bin/bash

# Интерактивный скрипт установки Not Your Mama Bot для Ubuntu/Linux
set -e

echo "🤖 Not Your Mama Bot - Установщик для Ubuntu/Linux"
echo "================================================="
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода цветного текста
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверяем, что это Ubuntu/Linux
check_os() {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "Этот скрипт предназначен только для Ubuntu/Linux"
        exit 1
    fi
    
    if [ ! -f /etc/debian_version ] && [ ! -f /etc/redhat-release ]; then
        print_warning "Рекомендуется Ubuntu/Debian. Установка может не работать на других дистрибутивах."
    fi
}

# Установка зависимостей системы
install_system_deps() {
    print_info "Проверка и установка системных зависимостей..."
    
    # Определяем пакетный менеджер
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv git curl
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip git curl
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3 python3-pip git curl
    else
        print_error "Не найден поддерживаемый пакетный менеджер (apt, yum, dnf)"
        exit 1
    fi
}

# Проверка Python
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 не найден. Устанавливаем..."
        install_system_deps
    fi
    
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    print_success "Python $PYTHON_VERSION найден"
}

# Проверка pip
check_pip() {
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 не найден. Устанавливаем..."
        install_system_deps
    fi
    print_success "pip3 найден"
}

# Интерактивный ввод данных
get_bot_config() {
    echo ""
    print_info "Настройка бота"
    echo "=============="
    
    # Telegram Bot Token
    echo ""
    print_info "📱 Получение Telegram Bot Token:"
    echo "1. Откройте Telegram и найдите @BotFather"
    echo "2. Отправьте команду /newbot"
    echo "3. Следуйте инструкциям для создания бота"
    echo "4. Скопируйте полученный токен (формат: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)"
    echo ""
    
    while true; do
        read -p "Введите токен Telegram бота: " TELEGRAM_BOT_TOKEN
        if [[ $TELEGRAM_BOT_TOKEN =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
            break
        else
            print_error "Неверный формат токена. Пример: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
        fi
    done
    
    # Bot Username
    echo ""
    print_info "🤖 Получение имени бота:"
    echo "1. В том же чате с @BotFather найдите вашего бота"
    echo "2. Скопируйте имя пользователя бота (можно с символом @)"
    echo "3. Пример: если бот @my_awesome_bot, введите: @my_awesome_bot или my_awesome_bot"
    echo ""
    
    while true; do
        read -p "Введите имя бота: " BOT_USERNAME
        # Убираем символ @ если он есть
        BOT_USERNAME=${BOT_USERNAME#@}
        
        if [[ $BOT_USERNAME =~ ^[a-zA-Z0-9_]+$ ]]; then
            break
        else
            print_error "Имя бота должно содержать только буквы, цифры и подчеркивания"
        fi
    done
    
    # OpenAI API Key
    echo ""
    print_info "🔑 Получение OpenAI API Key:"
    echo "1. Перейдите на https://platform.openai.com/api-keys"
    echo "2. Войдите в аккаунт или создайте новый"
    echo "3. Нажмите 'Create new secret key'"
    echo "4. Скопируйте полученный ключ (начинается с 'sk-' или 'sk-proj-')"
    echo "5. ⚠️  Сохраните ключ в безопасном месте - он больше не будет показан"
    echo ""
    
    while true; do
        read -p "Введите ключ OpenAI API: " OPENAI_API_KEY
        if [[ $OPENAI_API_KEY =~ ^sk-[A-Za-z0-9_-]+$ ]]; then
            break
        else
            print_error "Неверный формат ключа OpenAI. Должен начинаться с 'sk-' или 'sk-proj-'"
        fi
    done
    
    # Тип установки
    echo ""
    print_info "Выберите тип установки:"
    echo "1) Локальная разработка (текущая папка)"
    echo "2) Системная установка (systemd сервис)"
    echo "3) Docker контейнер"
    
    while true; do
        read -p "Выберите вариант (1-3): " INSTALL_TYPE
        case $INSTALL_TYPE in
            1) INSTALL_TYPE="local"; break ;;
            2) INSTALL_TYPE="systemd"; break ;;
            3) INSTALL_TYPE="docker"; break ;;
            *) print_error "Выберите 1, 2 или 3" ;;
        esac
    done
    
    # Настройка администратора
    echo ""
    print_info "Настройка администратора"
    echo "=========================="
    echo "Для настройки администратора:"
    echo "1. Запустите бота командой: python bot.py"
    echo "2. Отправьте боту /start в личных сообщениях"
    echo "3. Ваш ID будет автоматически записан как супер-администратор"
    echo "4. Остановите бота (Ctrl+C) и запустите установку снова"
    
    read -p "Продолжить установку? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Установка отменена"
        exit 0
    fi
}

# Локальная установка
install_local() {
    print_info "Установка для локальной разработки..."
    
    # Создаем виртуальное окружение
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_success "Виртуальное окружение создано"
    fi
    
    # Активируем виртуальное окружение
    source venv/bin/activate
    
    # Устанавливаем зависимости
    print_info "Установка Python зависимостей..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Создаем .env файл
    cat > .env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
BOT_USERNAME=$BOT_USERNAME
EOF
    
    print_success "Локальная установка завершена!"
    echo ""
    echo "Для запуска бота:"
    echo "  source venv/bin/activate"
    echo "  python bot.py"
}

# Системная установка
install_systemd() {
    print_info "Установка systemd сервиса..."
    
    # Проверяем права root
    if [ "$EUID" -ne 0 ]; then
        print_error "Для системной установки требуются права root"
        echo "Запустите: sudo ./install.sh"
        exit 1
    fi
    
    # Создаем пользователя
    if ! id "botuser" &>/dev/null; then
        useradd -r -s /bin/false -d /opt/not-your-mama-bot botuser
        print_success "Пользователь botuser создан"
    fi
    
    # Создаем директории
    mkdir -p /opt/not-your-mama-bot
    mkdir -p /opt/not-your-mama-bot/logs
    
    # Копируем файлы
    cp -r . /opt/not-your-mama-bot/
    chown -R botuser:botuser /opt/not-your-mama-bot
    
    # Создаем виртуальное окружение
    cd /opt/not-your-mama-bot
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Создаем .env файл
    cat > .env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
BOT_USERNAME=$BOT_USERNAME
EOF
    
    chown botuser:botuser .env
    chmod 600 .env
    
    # Устанавливаем systemd сервис
    cp scripts/not-your-mama-bot.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable not-your-mama-bot
    systemctl start not-your-mama-bot
    
    print_success "Системная установка завершена!"
    echo ""
    echo "Управление сервисом:"
    echo "  sudo systemctl status not-your-mama-bot"
    echo "  sudo systemctl restart not-your-mama-bot"
    echo "  sudo journalctl -u not-your-mama-bot -f"
}

# Docker установка
install_docker() {
    print_info "Установка Docker контейнера..."
    
    # Проверяем Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен. Установите Docker и попробуйте снова"
        exit 1
    fi
    
    # Создаем .env файл
    cat > .env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
BOT_USERNAME=$BOT_USERNAME
EOF
    
    # Собираем и запускаем контейнер
    docker-compose up -d --build
    
    print_success "Docker установка завершена!"
    echo ""
    echo "Управление контейнером:"
    echo "  docker-compose up -d    # Запуск"
    echo "  docker-compose down     # Остановка"
    echo "  docker-compose logs -f  # Логи"
}

# Основная функция
main() {
    check_os
    check_python
    check_pip
    get_bot_config
    
    case $INSTALL_TYPE in
        "local")
            install_local
            ;;
        "systemd")
            install_systemd
            ;;
        "docker")
            install_docker
            ;;
    esac
    
    echo ""
    print_success "Установка завершена успешно!"
    echo ""
    print_info "Следующие шаги:"
    echo "1. Запустите бота"
    echo "2. Отправьте /start в личных сообщениях"
    echo "3. Настройте администраторов командой /admin"
    echo "4. Настройте стиль бота командой /style"
}

# Запуск
main
