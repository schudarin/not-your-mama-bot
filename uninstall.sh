#!/bin/bash

# Скрипт полного удаления Not Your Mama Bot
set -e

echo "🗑️  Not Your Mama Bot - Удаление"
echo "==============================="
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

# Проверяем права root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Этот скрипт должен быть запущен с правами root"
        echo "Запустите: sudo ./uninstall.sh"
        exit 1
    fi
}

# Остановка и удаление systemd сервиса
remove_systemd_service() {
    print_info "Остановка и удаление systemd сервиса..."
    
    if systemctl is-active --quiet not-your-mama-bot; then
        systemctl stop not-your-mama-bot
        print_success "Сервис остановлен"
    fi
    
    if systemctl is-enabled --quiet not-your-mama-bot; then
        systemctl disable not-your-mama-bot
        print_success "Сервис отключен"
    fi
    
    if [ -f /etc/systemd/system/not-your-mama-bot.service ]; then
        rm /etc/systemd/system/not-your-mama-bot.service
        systemctl daemon-reload
        print_success "Файл сервиса удален"
    fi
}

# Удаление пользователя botuser
remove_user() {
    print_info "Удаление пользователя botuser..."
    
    if id "botuser" &>/dev/null; then
        # Удаляем crontab пользователя
        crontab -u botuser -r 2>/dev/null || true
        print_success "Crontab пользователя удален"
        
        # Удаляем пользователя и его домашнюю директорию
        userdel -r botuser 2>/dev/null || true
        print_success "Пользователь botuser удален"
    else
        print_info "Пользователь botuser не найден"
    fi
}

# Удаление файлов бота
remove_files() {
    print_info "Удаление файлов бота..."
    
    if [ -d "/opt/not-your-mama-bot" ]; then
        rm -rf /opt/not-your-mama-bot
        print_success "Директория /opt/not-your-mama-bot удалена"
    else
        print_info "Директория /opt/not-your-mama-bot не найдена"
    fi
}

# Удаление логов
remove_logs() {
    print_info "Удаление логов..."
    
    # Удаляем логи systemd
    journalctl --vacuum-time=1s --unit=not-your-mama-bot 2>/dev/null || true
    
    # Удаляем файлы логов
    if [ -d "/var/log/not-your-mama-bot" ]; then
        rm -rf /var/log/not-your-mama-bot
        print_success "Логи удалены"
    fi
}

# Удаление Docker контейнера (если используется)
remove_docker() {
    print_info "Проверка Docker контейнеров..."
    
    if command -v docker &> /dev/null; then
        if docker ps -a --format "table {{.Names}}" | grep -q "not-your-mama-bot"; then
            docker stop not-your-mama-bot 2>/dev/null || true
            docker rm not-your-mama-bot 2>/dev/null || true
            print_success "Docker контейнер удален"
        fi
        
        if docker images --format "table {{.Repository}}" | grep -q "not-your-mama-bot"; then
            docker rmi not-your-mama-bot 2>/dev/null || true
            print_success "Docker образ удален"
        fi
    fi
}

# Подтверждение удаления
confirm_uninstall() {
    echo ""
    print_warning "⚠️  ВНИМАНИЕ: Это действие необратимо!"
    echo ""
    echo "Будет удалено:"
    echo "• Systemd сервис not-your-mama-bot"
    echo "• Пользователь botuser и его файлы"
    echo "• Директория /opt/not-your-mama-bot"
    echo "• Все логи и конфигурации"
    echo "• Docker контейнеры (если есть)"
    echo ""
    
    read -p "Вы уверены, что хотите удалить бота? (введите 'DELETE' для подтверждения): " -r
    echo
    
    if [[ ! $REPLY == "DELETE" ]]; then
        print_info "Удаление отменено"
        exit 0
    fi
}

# Основная функция
main() {
    check_root
    confirm_uninstall
    
    print_info "Начинаю удаление Not Your Mama Bot..."
    
    remove_systemd_service
    remove_docker
    remove_files
    remove_logs
    remove_user
    
    echo ""
    print_success "Not Your Mama Bot полностью удален с сервера!"
    echo ""
    print_info "Что было удалено:"
    echo "✅ Systemd сервис"
    echo "✅ Пользователь botuser"
    echo "✅ Все файлы бота"
    echo "✅ Логи и конфигурации"
    echo "✅ Docker контейнеры"
    echo ""
    print_info "Для повторной установки используйте: ./install.sh"
}

# Запуск
main
