#!/bin/bash

# Скрипт отладки и логирования для Not Your Mama Bot
set -e

echo "🔍 Not Your Mama Bot - Отладка"
echo "=============================="
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Создание директории для логов
setup_logs() {
    print_info "Настройка системы логирования..."
    
    mkdir -p logs
    mkdir -p logs/debug
    mkdir -p logs/errors
    mkdir -p logs/updates
    
    # Создаем файлы логов
    touch logs/bot.log
    touch logs/errors.log
    touch logs/updates.log
    touch logs/debug.log
    
    print_success "Директории логов созданы"
}

# Просмотр логов в реальном времени
tail_logs() {
    print_info "Просмотр логов в реальном времени..."
    echo ""
    echo "Выберите тип логов:"
    echo "1) Все логи"
    echo "2) Только ошибки"
    echo "3) Только обновления"
    echo "4) Только отладка"
    echo ""
    
    read -p "Выберите вариант (1-4): " choice
    
    case $choice in
        1)
            tail -f logs/*.log
            ;;
        2)
            tail -f logs/errors.log
            ;;
        3)
            tail -f logs/updates.log
            ;;
        4)
            tail -f logs/debug.log
            ;;
        *)
            print_error "Неверный выбор"
            exit 1
            ;;
    esac
}

# Просмотр последних ошибок
show_errors() {
    print_info "Последние ошибки:"
    echo ""
    
    if [ -f "logs/errors.log" ]; then
        if [ -s "logs/errors.log" ]; then
            tail -20 logs/errors.log
        else
            print_success "Ошибок не найдено"
        fi
    else
        print_warning "Файл логов ошибок не найден"
    fi
}

# Проверка статуса сервиса
check_service() {
    print_info "Проверка статуса systemd сервиса..."
    
    if systemctl is-active --quiet not-your-mama-bot; then
        print_success "Сервис активен"
        systemctl status not-your-mama-bot --no-pager -l
    else
        print_error "Сервис неактивен"
        systemctl status not-your-mama-bot --no-pager -l
    fi
}

# Проверка переменных окружения
check_env() {
    print_info "Проверка переменных окружения..."
    
    if [ -f ".env" ]; then
        print_success "Файл .env найден"
        echo ""
        echo "Содержимое .env:"
        cat .env | sed 's/=.*/=***/'  # Скрываем значения
    else
        print_warning "Файл .env не найден"
    fi
    
    echo ""
    print_info "Переменные окружения:"
    echo "TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:+***}"
    echo "OPENAI_API_KEY: ${OPENAI_API_KEY:+***}"
    echo "BOT_USERNAME: ${BOT_USERNAME:-не установлен}"
}

# Проверка зависимостей
check_deps() {
    print_info "Проверка зависимостей..."
    
    if [ -d "venv" ]; then
        print_success "Виртуальное окружение найдено"
        source venv/bin/activate
        
        echo ""
        echo "Установленные пакеты:"
        pip list | grep -E "(telegram|openai|duckduckgo)"
    else
        print_warning "Виртуальное окружение не найдено"
    fi
}

# Очистка логов
clean_logs() {
    print_info "Очистка старых логов..."
    
    # Удаляем логи старше 7 дней
    find logs -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Очищаем пустые файлы логов
    find logs -name "*.log" -size 0 -delete 2>/dev/null || true
    
    print_success "Старые логи очищены"
}

# Экспорт логов
export_logs() {
    print_info "Экспорт логов..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ARCHIVE="logs_export_${TIMESTAMP}.tar.gz"
    
    tar -czf "$ARCHIVE" logs/ 2>/dev/null || true
    
    if [ -f "$ARCHIVE" ]; then
        print_success "Логи экспортированы в $ARCHIVE"
    else
        print_error "Ошибка при экспорте логов"
    fi
}

# Основная функция
main() {
    setup_logs
    
    echo "Выберите действие:"
    echo "1) Просмотр логов в реальном времени"
    echo "2) Показать последние ошибки"
    echo "3) Проверить статус сервиса"
    echo "4) Проверить переменные окружения"
    echo "5) Проверить зависимости"
    echo "6) Очистить старые логи"
    echo "7) Экспортировать логи"
    echo "8) Все проверки"
    echo ""
    
    read -p "Выберите вариант (1-8): " choice
    
    case $choice in
        1)
            tail_logs
            ;;
        2)
            show_errors
            ;;
        3)
            check_service
            ;;
        4)
            check_env
            ;;
        5)
            check_deps
            ;;
        6)
            clean_logs
            ;;
        7)
            export_logs
            ;;
        8)
            check_service
            echo ""
            check_env
            echo ""
            check_deps
            echo ""
            show_errors
            ;;
        *)
            print_error "Неверный выбор"
            exit 1
            ;;
    esac
}

# Запуск
main
