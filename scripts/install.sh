#!/bin/bash

# Интерактивный скрипт установки Not Your Mama Bot для Ubuntu/Linux
set -e

# Обработчик сигналов для показа инструкций при прерывании
trap 'echo ""; print_warning "Установка прервана пользователем"; show_error_instructions; exit 1' INT TERM

echo "🤖 Not Your Mama Bot - Установщик для Ubuntu/Linux"
echo "================================================="
echo ""

# Инструкции по устранению неполадок
# ===================================
# Если установка прерывается с ошибкой:
# 1. Прочитайте сообщение об ошибке
# 2. Выполните предложенные команды
# 3. Запустите установщик заново: ./scripts/install.sh
# 4. Если проблема повторяется - обратитесь к документации

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

# Проверяем операционную систему
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Обнаружена macOS"
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "Обнаружен Linux"
        OS_TYPE="linux"
        
        if [ ! -f /etc/debian_version ] && [ ! -f /etc/redhat-release ]; then
            print_warning "Рекомендуется Ubuntu/Debian. Установка может не работать на других дистрибутивах."
        fi
    else
        print_error "Неподдерживаемая операционная система: $OSTYPE"
        print_info "Поддерживаются: macOS, Ubuntu/Linux"
        exit 1
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

# Проверка прав sudo
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        print_error "sudo не найден. Проверьте права доступа."
        return 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        print_warning "sudo требует пароль. Убедитесь, что у вас есть права администратора."
        return 1
    fi
    
    return 0
}

# Настройка автообновления
setup_auto_update() {
    echo ""
    print_info "Настройка автообновления"
    echo "=========================="
    echo "Автообновление позволяет боту автоматически получать новые версии из Git"
    echo ""
    echo "Варианты обновления:"
    echo "1) Автоматическое обновление (рекомендуется)"
    echo "   • Обновление каждые 6 часов через cron"
    echo "   • Уведомления в Telegram при обновлениях"
    echo "   • Автоматический перезапуск сервиса"
    echo ""
    echo "2) Ручное обновление"
    echo "   • Обновление командой /update в Telegram"
    echo "   • Полный контроль над процессом"
    echo "   • Требует действий администратора"
    echo ""
    echo "3) Отложить настройку"
    echo "   • Настроить позже вручную"
    echo "   • Использовать скрипт scripts/setup-auto-update.sh"
    echo ""
    
    while true; do
        read -p "Выберите вариант (1-3): " AUTO_UPDATE_CHOICE
        case $AUTO_UPDATE_CHOICE in
            1)
                print_info "Настройка автоматического обновления..."
                if [ -f "scripts/setup-auto-update.sh" ]; then
                    chmod +x scripts/setup-auto-update.sh
                    ./scripts/setup-auto-update.sh
                    print_success "Автообновление настроено!"
                    echo ""
                    print_info "Автообновление будет работать:"
                    echo "  • Каждые 6 часов (в 00:00, 06:00, 12:00, 18:00)"
                    echo "  • Уведомления в Telegram при обновлениях"
                    echo "  • Автоматический перезапуск сервиса"
                    echo ""
                    print_info "Управление автообновлением:"
                    echo "  • Просмотр логов: ./scripts/debug.sh"
                    echo "  • Отключение: crontab -e (удалить строки с not-your-mama-bot)"
                    echo "  • Ручное обновление: /update в Telegram"
                else
                    print_error "Скрипт автообновления не найден"
                    print_info "Настройте автообновление вручную:"
                    echo "  • Создайте cron задачу для scripts/update.sh"
                    echo "  • Или используйте команду /update в Telegram"
                fi
                break
                ;;
            2)
                print_info "Выбрано ручное обновление"
                echo ""
                print_info "Для обновления бота используйте:"
                echo "  • Команду /update в Telegram (только для администраторов)"
                echo "  • Или скрипт: ./scripts/update.sh"
                echo ""
                print_info "Рекомендуется настроить автообновление позже:"
                echo "  • ./scripts/setup-auto-update.sh"
                break
                ;;
            3)
                print_info "Настройка автообновления отложена"
                echo ""
                print_info "Для настройки автообновления позже:"
                echo "  • ./scripts/setup-auto-update.sh"
                echo "  • Или настройте cron вручную"
                break
                ;;
            *)
                print_error "Выберите 1, 2 или 3"
                ;;
        esac
    done
}

# Показать инструкции при ошибке
show_error_instructions() {
    echo ""
    print_info "Что делать дальше:"
    echo "  1. Прочитайте сообщение об ошибке выше"
    echo "  2. Выполните предложенные команды"
    echo "  3. Запустите установщик заново: ./scripts/install.sh"
    echo "  4. Конфигурация сохранена и будет использована автоматически"
    echo "  5. Если проблема повторяется - обратитесь к документации"
    echo ""
    print_info "Документация:"
    echo "  📖 docs/FIRST_INSTALL.md - Руководство по установке"
    echo "  🛠️  scripts/debug.sh - Скрипт для отладки"
    echo "  🧪 scripts/test-bot.sh - Тестирование компонентов"
}

# Очистка частично созданного виртуального окружения
cleanup_venv() {
    if [ -d "venv" ] && [ ! -f "venv/bin/activate" ]; then
        print_info "Удаление поврежденного виртуального окружения..."
        rm -rf venv
    fi
}

# Проверка python3-venv
check_venv() {
    if ! python3 -c "import venv" &> /dev/null; then
        print_error "python3-venv не найден. Пробуем установить..."
        
        if check_sudo; then
            install_system_deps
        else
            print_error "Не удалось установить python3-venv автоматически"
            print_info "Установите вручную:"
            echo "  sudo apt-get install python3-venv python3.8-venv"
            echo "  или: pip install --user virtualenv"
            return 1
        fi
    fi
    print_success "python3-venv найден"
}

# Проверка сохраненной конфигурации
check_saved_config() {
    if [ -f ".install_config" ]; then
        print_info "Найдена сохраненная конфигурация"
        echo ""
        echo "Варианты:"
        echo "1) Использовать сохраненную конфигурацию"
        echo "2) Ввести данные заново"
        echo ""
        
        while true; do
            read -p "Выберите вариант (1-2): " CONFIG_CHOICE
            case $CONFIG_CHOICE in
                1)
                    source .install_config
                    print_success "Используется сохраненная конфигурация"
                    return 0
                    ;;
                2)
                    rm -f .install_config
                    print_info "Будет запрошена новая конфигурация"
                    return 1
                    ;;
                *)
                    print_error "Выберите 1 или 2"
                    ;;
            esac
        done
    fi
    return 1
}

# Сохранение конфигурации
save_config() {
    cat > .install_config << EOF
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
OPENAI_API_KEY="$OPENAI_API_KEY"
BOT_USERNAME="$BOT_USERNAME"
INSTALL_TYPE="$INSTALL_TYPE"
EOF
}

# Интерактивный ввод данных
get_bot_config() {
    # Проверяем сохраненную конфигурацию
    if check_saved_config; then
        return 0
    fi
    
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
    
    # Сохраняем конфигурацию для возможного повторного использования
    save_config
}

# Локальная установка
install_local() {
    print_info "Установка для локальной разработки..."
    
    # Очищаем поврежденное виртуальное окружение
    cleanup_venv
    
    # Проверяем и устанавливаем python3-venv если нужно
    if ! python3 -c "import venv" &> /dev/null; then
        print_info "Устанавливаем python3-venv..."
        
        # Пробуем с sudo
        if check_sudo; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y python3-venv python3.8-venv
            elif command -v yum &> /dev/null; then
                sudo yum install -y python3-venv
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y python3-venv
            fi
        fi
        
        # Если sudo не работает или пакет не установился, пробуем virtualenv
        if ! python3 -c "import venv" &> /dev/null; then
            print_info "Устанавливаем virtualenv как альтернативу..."
            if pip3 install --user virtualenv; then
                print_success "virtualenv установлен"
                    else
            print_error "Не удалось установить virtualenv"
            print_info "Установите вручную:"
            echo "  pip install --user virtualenv"
            echo "  или получите права sudo для установки python3-venv"
            echo ""
            print_info "Что делать дальше:"
            echo "  1. Установите virtualenv: pip install --user virtualenv"
            echo "  2. Или получите права sudo и установите python3-venv"
            echo "  3. Запустите установщик заново: ./scripts/install.sh"
            exit 1
            fi
        fi
    fi
    
    # Создаем виртуальное окружение
    if [ ! -d "venv" ]; then
        print_info "Создание виртуального окружения..."
        
        # Пробуем стандартный способ
        if python3 -m venv venv; then
            print_success "Виртуальное окружение создано"
        else
            print_error "Ошибка создания виртуального окружения через python3 -m venv"
            print_info "Пробуем альтернативный способ..."
            
            # Пробуем с virtualenv если доступен
            if command -v virtualenv &> /dev/null; then
                print_info "Создаем виртуальное окружение через virtualenv..."
                if virtualenv venv; then
                    print_success "Виртуальное окружение создано через virtualenv"
                else
                                    print_error "Не удалось создать виртуальное окружение через virtualenv"
                print_info "Установите python3-venv вручную:"
                echo "  sudo apt-get install python3-venv python3.8-venv"
                echo ""
                print_info "Что делать дальше:"
                echo "  1. Установите python3-venv: sudo apt-get install python3-venv python3.8-venv"
                echo "  2. Запустите установщик заново: ./scripts/install.sh"
                echo "  3. Конфигурация сохранена и будет использована автоматически"
                exit 1
                fi
            else
                print_error "Не удалось создать виртуальное окружение"
                print_info "Установите python3-venv вручную:"
                echo "  sudo apt-get install python3-venv python3.8-venv"
                echo "  или: pip install virtualenv"
                echo ""
                print_info "Что делать дальше:"
                echo "  1. Установите python3-venv: sudo apt-get install python3-venv python3.8-venv"
                echo "  2. Или установите virtualenv: pip install virtualenv"
                echo "  3. Запустите установщик заново: ./scripts/install.sh"
                exit 1
            fi
        fi
    else
        print_info "Виртуальное окружение уже существует"
    fi
    
    # Проверяем и активируем виртуальное окружение
    if [ ! -d "venv" ]; then
        print_error "Виртуальное окружение не найдено"
        echo ""
        print_info "Что делать дальше:"
        echo "  1. Запустите установщик заново: ./scripts/install.sh"
        echo "  2. Установщик автоматически создаст виртуальное окружение"
        exit 1
    fi
    
    if [ ! -f "venv/bin/activate" ]; then
        print_error "Файл активации виртуального окружения не найден"
        echo ""
        print_info "Что делать дальше:"
        echo "  1. Удалите поврежденное окружение: rm -rf venv"
        echo "  2. Запустите установщик заново: ./scripts/install.sh"
        exit 1
    fi
    
    print_info "Активация виртуального окружения..."
    if ! source venv/bin/activate; then
        print_error "Ошибка активации виртуального окружения"
        exit 1
    fi
    print_success "Виртуальное окружение активировано"
    
    # Устанавливаем зависимости
    print_info "Установка Python зависимостей..."
    print_info "Обновление pip..."
    if ! pip install --upgrade pip; then
        print_error "Ошибка обновления pip"
        exit 1
    fi
    
    print_info "Установка зависимостей из requirements.txt..."
    if ! pip install -r requirements.txt; then
        print_warning "Ошибка установки зависимостей из requirements.txt"
        print_info "Устанавливаем зависимости по отдельности..."
        
        # Устанавливаем основные зависимости
        pip install python-telegram-bot>=20.0
        pip install openai>=1.0.0
        pip install requests>=2.25.0
        pip install python-dotenv>=1.0.0
        pip install aiohttp>=3.8.0
        
        # Проверяем версию Python для ddgs
        PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        print_info "Версия Python: $PYTHON_VERSION"
        
        # Устанавливаем ddgs с учетом версии Python
        if ! pip install ddgs>=9.0.0; then
            print_warning "Не удалось установить ddgs>=9.0.0, пробуем более старую версию..."
            if ! pip install ddgs>=8.0.0; then
                print_warning "Не удалось установить ddgs>=8.0.0, пробуем через pip3..."
                if ! pip3 install ddgs>=8.0.0; then
                    print_warning "Не удалось установить ddgs, пробуем duckduckgo-search как fallback..."
                    if pip install duckduckgo-search>=4.0.0; then
                        print_success "duckduckgo-search установлен как fallback"
                        # Обновляем requirements.txt для совместимости
                        sed -i 's/ddgs>=9.0.0/duckduckgo-search>=4.0.0/' requirements.txt
                    else
                        print_error "Не удалось установить ни ddgs, ни duckduckgo-search"
                        print_info "Попробуйте установить вручную: pip install ddgs"
                        exit 1
                    fi
                else
                    print_success "ddgs>=8.0.0 установлен через pip3"
                fi
            else
                print_success "ddgs>=8.0.0 установлен через pip"
            fi
        else
            print_success "ddgs>=9.0.0 установлен через pip"
        fi
    fi
    print_success "Зависимости установлены успешно"
    
    # Проверяем установку ключевых модулей
    print_info "Проверка установки модулей..."
    if pip show python-telegram-bot &> /dev/null; then
        print_success "python-telegram-bot установлен"
    else
        print_error "python-telegram-bot не установлен"
    fi
    
    if pip show ddgs &> /dev/null; then
        print_success "ddgs установлен"
    else
        print_warning "ddgs не установлен, устанавливаем..."; if pip install ddgs>=9.0.0; then print_success "ddgs установлен"; else print_error "ddgs не удалось установить"; fi
    fi
    
    if pip show openai &> /dev/null; then
        print_success "openai установлен"
    else
        print_error "openai не установлен"
    fi
    
    # Создаем .env файл
    print_info "Создание .env файла..."
    cat > .env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
BOT_USERNAME=$BOT_USERNAME
EOF
    
    # Проверяем что файл создался
    if [ ! -f ".env" ]; then
        print_error "Ошибка создания .env файла"
        exit 1
    fi
    print_success ".env файл создан"
    
    print_success "Локальная установка завершена!"
    
    # Очищаем сохраненную конфигурацию после успешной установки
    rm -f .install_config
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
    
    # Настраиваем Git безопасность
    print_info "Настройка Git безопасности..."
    # Настраиваем глобально для всех пользователей
    git config --global --add safe.directory /opt/not-your-mama-bot || true
    print_success "Git безопасность настроена"
    
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
        
        # Если не удалось, пробуем virtualenv
        if ! python3 -c "import venv" &> /dev/null; then
            print_info "Устанавливаем virtualenv как альтернативу..."
            pip3 install virtualenv
        fi
    fi
    
    # Создаем виртуальное окружение
    cd /opt/not-your-mama-bot
    print_info "Создание виртуального окружения..."
    
    if python3 -m venv venv; then
        print_success "Виртуальное окружение создано"
    else
        print_error "Ошибка создания виртуального окружения"
        print_info "Пробуем через virtualenv..."
        
        if command -v virtualenv &> /dev/null; then
            if virtualenv venv; then
                print_success "Виртуальное окружение создано через virtualenv"
            else
                print_error "Не удалось создать виртуальное окружение"
                print_info "Попробуйте установить python3-venv вручную:"
                echo "  apt-get install python3-venv python3.8-venv"
                echo ""
                print_info "Что делать дальше:"
                echo "  1. Установите python3-venv: apt-get install python3-venv python3.8-venv"
                echo "  2. Запустите установщик заново: ./scripts/install.sh"
                echo "  3. Конфигурация сохранена и будет использована автоматически"
                exit 1
            fi
        else
            print_error "Не удалось создать виртуальное окружение"
            print_info "Попробуйте установить python3-venv вручную:"
            echo "  apt-get install python3-venv python3.8-venv"
            echo ""
            print_info "Что делать дальше:"
            echo "  1. Установите python3-venv: apt-get install python3-venv python3.8-venv"
            echo "  2. Запустите установщик заново: ./scripts/install.sh"
            echo "  3. Конфигурация сохранена и будет использована автоматически"
            exit 1
        fi
    fi
    
    # Проверяем и активируем виртуальное окружение
    if [ ! -f "venv/bin/activate" ]; then
        print_error "Файл активации виртуального окружения не найден"
        echo ""
        print_info "Что делать дальше:"
        echo "  1. Удалите поврежденное окружение: rm -rf venv"
        echo "  2. Запустите установщик заново: ./scripts/install.sh"
        echo "  3. Конфигурация сохранена и будет использована автоматически"
        exit 1
    fi
    
    print_info "Активация виртуального окружения..."
    if ! source venv/bin/activate; then
        print_error "Ошибка активации виртуального окружения"
        exit 1
    fi
    print_success "Виртуальное окружение активировано"
    
    # Устанавливаем зависимости
    print_info "Установка Python зависимостей..."
    print_info "Обновление pip..."
    if ! pip install --upgrade pip; then
        print_error "Ошибка обновления pip"
        exit 1
    fi
    
    print_info "Установка зависимостей из requirements.txt..."
    if ! pip install -r requirements.txt; then
        print_warning "Ошибка установки зависимостей из requirements.txt"
        print_info "Устанавливаем зависимости по отдельности..."
        
        # Устанавливаем основные зависимости
        pip install python-telegram-bot>=20.0
        pip install openai>=1.0.0
        pip install requests>=2.25.0
        pip install python-dotenv>=1.0.0
        pip install aiohttp>=3.8.0
        
        # Проверяем версию Python для ddgs
        PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        print_info "Версия Python: $PYTHON_VERSION"
        
        # Устанавливаем ddgs с учетом версии Python
        if ! pip install ddgs>=9.0.0; then
            print_warning "Не удалось установить ddgs>=9.0.0, пробуем более старую версию..."
            if ! pip install ddgs>=8.0.0; then
                print_warning "Не удалось установить ddgs>=8.0.0, пробуем через pip3..."
                if ! pip3 install ddgs>=8.0.0; then
                    print_warning "Не удалось установить ddgs, пробуем duckduckgo-search как fallback..."
                    if pip install duckduckgo-search>=4.0.0; then
                        print_success "duckduckgo-search установлен как fallback"
                        # Обновляем requirements.txt для совместимости
                        sed -i 's/ddgs>=9.0.0/duckduckgo-search>=4.0.0/' requirements.txt
                    else
                        print_error "Не удалось установить ни ddgs, ни duckduckgo-search"
                        print_info "Попробуйте установить вручную: pip install ddgs"
                        exit 1
                    fi
                else
                    print_success "ddgs>=8.0.0 установлен через pip3"
                fi
            else
                print_success "ddgs>=8.0.0 установлен через pip"
            fi
        else
            print_success "ddgs>=9.0.0 установлен через pip"
        fi
    fi
    print_success "Зависимости установлены успешно"
    
    # Проверяем установку ключевых модулей
    print_info "Проверка установки модулей..."
    if pip show python-telegram-bot &> /dev/null; then
        print_success "python-telegram-bot установлен"
    else
        print_error "python-telegram-bot не установлен"
    fi
    
    if pip show ddgs &> /dev/null; then
        print_success "ddgs установлен"
    else
        print_warning "ddgs не установлен, устанавливаем..."; if pip install ddgs>=9.0.0; then print_success "ddgs установлен"; else print_error "ddgs не удалось установить"; fi
    fi
    
    if pip show openai &> /dev/null; then
        print_success "openai установлен"
    else
        print_error "openai не установлен"
    fi
    
    # Создаем .env файл
    print_info "Создание .env файла..."
    cat > .env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
BOT_USERNAME=$BOT_USERNAME
EOF
    
    # Проверяем что файл создался
    if [ ! -f ".env" ]; then
        print_error "Ошибка создания .env файла"
        exit 1
    fi
    print_success ".env файл создан"
    
    chown botuser:botuser .env
    chmod 600 .env
    
    # Устанавливаем systemd сервис
    cp scripts/not-your-mama-bot.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable not-your-mama-bot
    systemctl start not-your-mama-bot
    
    print_success "Системная установка завершена!"
    
    # Очищаем сохраненную конфигурацию после успешной установки
    rm -f .install_config
}

# Docker установка
install_docker() {
    print_info "Установка Docker контейнера..."
    
    # Проверяем Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен. Установите Docker и попробуйте снова"
        echo ""
        print_info "Что делать дальше:"
        echo "  1. Установите Docker: https://docs.docker.com/get-docker/"
        echo "  2. Запустите установщик заново: ./scripts/install.sh"
        echo "  3. Или выберите другой тип установки (локальная/системная)"
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
    
    # Очищаем сохраненную конфигурацию после успешной установки
    rm -f .install_config
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
    
    # Настройка автообновления (только для systemd и docker)
    if [ "$INSTALL_TYPE" = "systemd" ] || [ "$INSTALL_TYPE" = "docker" ]; then
        setup_auto_update
    else
        echo ""
        print_info "ℹ️  Автообновление не настроено для локальной установки"
        print_info "Для обновления используйте:"
        echo "  • git pull origin master"
        echo "  • Или команду /update в Telegram (если настроена)"
    fi
    
    echo ""
    print_success "🎉 Установка завершена!"
    echo ""
    
    # Показываем информацию в зависимости от типа установки
    case $INSTALL_TYPE in
        "local")
            print_info "🚀 Запуск бота:"
            echo "  ./scripts/run-bot.sh"
            ;;
        "systemd")
            print_info "🚀 Бот запущен как служба:"
            echo "  sudo systemctl status not-your-mama-bot"
            ;;
        "docker")
            print_info "🚀 Бот запущен в контейнере:"
            echo "  docker-compose logs -f"
            ;;
    esac
    
    echo ""
    print_info "👑 Настройка администратора:"
    echo "  1. Отправьте /start боту в личных сообщениях"
    echo "  2. Ваш ID будет автоматически записан как супер-администратор"
    echo "  3. Теперь вы можете управлять ботом через команды /admin, /style, /update"
    echo ""
    print_info "🛠️  Дополнительно:"
    echo "  ./scripts/debug.sh - отладка"
    echo "  ./scripts/test-bot.sh - тестирование"
    
    # Очищаем сохраненную конфигурацию после успешной установки
    rm -f .install_config
}

# Запуск
main
