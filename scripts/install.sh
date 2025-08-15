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
        sudo apt-get install -y python3 python3-pip python3-venv python3.8-venv git curl
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip python3-venv git curl
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3 python3-pip python3-venv git curl
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

# Проверка python3-venv
check_venv() {
    if ! python3 -c "import venv" &> /dev/null; then
        print_error "python3-venv не найден. Устанавливаем..."
        install_system_deps
    fi
    print_success "python3-venv найден"
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
    echo ""
    echo "1) Локальная разработка (текущая папка)"
    echo "   ✅ Рекомендуется для:"
    echo "      • Тестирования и разработки"
    echo "      • Первой установки"
    echo "      • Пользователей без опыта с systemd"
    echo "      • Быстрого запуска"
    echo ""
    echo "2) Системная установка (systemd сервис)"
    echo "   ✅ Рекомендуется для:"
    echo "      • Продакшена на сервере"
    echo "      • Автоматического запуска при перезагрузке"
    echo "      • Продвинутых пользователей"
    echo "      • Долгосрочного использования"
    echo ""
    echo "3) Docker контейнер"
    echo "   ✅ Рекомендуется для:"
    echo "      • Изолированной среды"
    echo "      • Простого развертывания"
    echo "      • Пользователей с опытом Docker"
    echo "      • Масштабирования"
    echo ""
    
    while true; do
        read -p "Выберите вариант (1-3): " INSTALL_TYPE
        case $INSTALL_TYPE in
            1) 
                INSTALL_TYPE="local"
                print_info "Выбрана локальная установка - отлично для начала!"
                break 
                ;;
            2) 
                INSTALL_TYPE="systemd"
                print_info "Выбрана системная установка - бот будет работать как служба!"
                break 
                ;;
            3) 
                INSTALL_TYPE="docker"
                print_info "Выбрана Docker установка - изолированная среда!"
                break 
                ;;
            *) print_error "Выберите 1, 2 или 3" ;;
        esac
    done
    
    # Информация о настройке администратора
    echo ""
    print_info "Настройка администратора"
    echo "=========================="
    echo "После установки бота:"
    echo "1. Запустите бота командой: python bot.py"
    echo "2. Отправьте боту /start в личных сообщениях"
    echo "3. Ваш ID будет автоматически записан как супер-администратор"
    echo "4. Теперь вы можете управлять ботом через команды /admin, /style, /update"
    echo ""
}

# Локальная установка
install_local() {
    print_info "Установка для локальной разработки..."
    
    # Проверяем и устанавливаем python3-venv если нужно
    if ! python3 -c "import venv" &> /dev/null; then
        print_info "Устанавливаем python3-venv..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y python3-venv python3.8-venv
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3-venv
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y python3-venv
        fi
        
        # Если все еще не работает, пробуем virtualenv
        if ! python3 -c "import venv" &> /dev/null; then
            print_info "Устанавливаем virtualenv как альтернативу..."
            pip3 install --user virtualenv
        fi
    fi
    
    # Создаем виртуальное окружение
    if [ ! -d "venv" ]; then
        print_info "Создание виртуального окружения..."
        
        # Пробуем стандартный способ
        if python3 -m venv venv; then
            print_success "Виртуальное окружение создано"
        else
            print_error "Ошибка создания виртуального окружения"
            print_info "Пробуем альтернативный способ..."
            
            # Пробуем с virtualenv если доступен
            if command -v virtualenv &> /dev/null; then
                if virtualenv venv; then
                    print_success "Виртуальное окружение создано через virtualenv"
                else
                    print_error "Не удалось создать виртуальное окружение"
                    print_info "Установите python3-venv вручную:"
                    echo "  sudo apt-get install python3-venv python3.8-venv"
                    echo "  или: pip install virtualenv"
                    exit 1
                fi
            else
                print_error "Не удалось создать виртуальное окружение"
                print_info "Установите python3-venv вручную:"
                echo "  sudo apt-get install python3-venv python3.8-venv"
                echo "  или: pip install virtualenv"
                exit 1
            fi
        fi
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
    
    # Проверяем и устанавливаем python3-venv если нужно
    if ! python3 -c "import venv" &> /dev/null; then
        print_info "Устанавливаем python3-venv..."
        if command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y python3-venv python3.8-venv
        elif command -v yum &> /dev/null; then
            yum install -y python3-venv
        elif command -v dnf &> /dev/null; then
            dnf install -y python3-venv
        fi
    fi
    
    # Создаем виртуальное окружение
    cd /opt/not-your-mama-bot
    if python3 -m venv venv; then
        print_success "Виртуальное окружение создано"
    else
        print_error "Ошибка создания виртуального окружения"
        print_info "Попробуйте установить python3-venv вручную:"
        echo "  apt-get install python3-venv python3.8-venv"
        exit 1
    fi
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
    check_venv
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
    echo "1. Запустите бота: python bot.py"
    echo "2. Отправьте /start в личных сообщениях (станет супер-администратором)"
    echo "3. Настройте стиль бота командой /style"
    echo "4. Добавьте других администраторов командой /admin add <ID>"
    echo ""
    print_info "Для тестирования: ./scripts/test-bot.sh"
    print_info "Для отладки: ./scripts/debug.sh"
}

# Запуск
main
