#!/bin/bash

# Скрипт для быстрого тестирования бота
set -e

echo "🧪 Not Your Mama Bot - Тестирование"
echo "==================================="
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

# Проверка переменных окружения
check_env() {
    print_info "Проверка переменных окружения..."
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        print_error "TELEGRAM_BOT_TOKEN не установлен"
        return 1
    fi
    
    if [ -z "$OPENAI_API_KEY" ]; then
        print_error "OPENAI_API_KEY не установлен"
        return 1
    fi
    
    if [ -z "$BOT_USERNAME" ]; then
        print_error "BOT_USERNAME не установлен"
        return 1
    fi
    
    print_success "Все переменные окружения установлены"
    return 0
}

# Проверка зависимостей
check_dependencies() {
    print_info "Проверка зависимостей..."
    
    # Проверяем Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 не найден"
        return 1
    fi
    
    # Проверяем pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 не найден"
        return 1
    fi
    
    # Проверяем виртуальное окружение
    if [ ! -d "venv" ]; then
        print_warning "Виртуальное окружение не найдено. Создаем..."
        python3 -m venv venv
    fi
    
    # Активируем виртуальное окружение
    source venv/bin/activate
    
    # Проверяем зависимости
    if ! pip show python-telegram-bot &> /dev/null; then
        print_warning "python-telegram-bot не установлен. Устанавливаем..."
        pip install -r requirements.txt
    fi
    
    print_success "Зависимости проверены"
    return 0
}

# Тест подключения к Telegram
test_telegram() {
    print_info "Тестирование подключения к Telegram..."
    
    # Создаем временный скрипт для тестирования
    cat > test_telegram.py << 'EOF'
import asyncio
import os
from telegram import Bot
from telegram.error import TelegramError

async def test_telegram():
    try:
        bot = Bot(token=os.getenv('TELEGRAM_BOT_TOKEN'))
        me = await bot.get_me()
        print(f"✅ Подключение к Telegram успешно!")
        print(f"   Имя бота: {me.first_name}")
        print(f"   Username: @{me.username}")
        print(f"   ID: {me.id}")
        return True
    except TelegramError as e:
        print(f"❌ Ошибка подключения к Telegram: {e}")
        return False
    except Exception as e:
        print(f"❌ Неожиданная ошибка: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(test_telegram())
EOF
    
    # Запускаем тест
    if python test_telegram.py; then
        print_success "Telegram подключение работает"
        rm test_telegram.py
        return 0
    else
        print_error "Telegram подключение не работает"
        rm test_telegram.py
        return 1
    fi
}

# Тест OpenAI
test_openai() {
    print_info "Тестирование подключения к OpenAI..."
    
    # Создаем временный скрипт для тестирования
    cat > test_openai.py << 'EOF'
import os
import asyncio
from openai import AsyncOpenAI

async def test_openai():
    try:
        client = AsyncOpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": "Привет! Это тест."}],
            max_tokens=10
        )
        print(f"✅ Подключение к OpenAI успешно!")
        print(f"   Ответ: {response.choices[0].message.content}")
        return True
    except Exception as e:
        print(f"❌ Ошибка подключения к OpenAI: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(test_openai())
EOF
    
    # Запускаем тест
    if python test_openai.py; then
        print_success "OpenAI подключение работает"
        rm test_openai.py
        return 0
    else
        print_error "OpenAI подключение не работает"
        rm test_openai.py
        return 1
    fi
}

# Тест DuckDuckGo
test_duckduckgo() {
    print_info "Тестирование DuckDuckGo поиска..."
    
    # Создаем временный скрипт для тестирования
    cat > test_ddg.py << 'EOF'
from duckduckgo_search import ddg

def test_ddg():
    try:
        results = ddg("test", max_results=1)
        if results:
            print(f"✅ DuckDuckGo поиск работает!")
            print(f"   Найден результат: {results[0].get('title', 'Без заголовка')}")
            return True
        else:
            print("❌ DuckDuckGo поиск не вернул результатов")
            return False
    except Exception as e:
        print(f"❌ Ошибка DuckDuckGo поиска: {e}")
        return False

if __name__ == "__main__":
    test_ddg()
EOF
    
    # Запускаем тест
    if python test_ddg.py; then
        print_success "DuckDuckGo поиск работает"
        rm test_ddg.py
        return 0
    else
        print_error "DuckDuckGo поиск не работает"
        rm test_ddg.py
        return 1
    fi
}

# Запуск бота в тестовом режиме
test_bot() {
    print_info "Запуск бота в тестовом режиме..."
    echo ""
    print_warning "Бот запускается. Отправьте /start в личных сообщениях для тестирования."
    print_warning "Нажмите Ctrl+C для остановки."
    echo ""
    
    # Запускаем бота с дополнительным логированием
    python -u bot.py
}

# Основная функция
main() {
    echo "Выберите тест:"
    echo "1) Проверка окружения"
    echo "2) Тест Telegram"
    echo "3) Тест OpenAI"
    echo "4) Тест DuckDuckGo"
    echo "5) Запуск бота"
    echo "6) Все тесты"
    echo ""
    
    read -p "Выберите вариант (1-6): " choice
    
    case $choice in
        1)
            check_env
            ;;
        2)
            check_env && test_telegram
            ;;
        3)
            check_env && test_openai
            ;;
        4)
            check_dependencies && test_duckduckgo
            ;;
        5)
            check_env && check_dependencies && test_bot
            ;;
        6)
            check_env && check_dependencies && test_telegram && test_openai && test_duckduckgo
            echo ""
            print_info "Все тесты завершены. Запускаем бота..."
            test_bot
            ;;
        *)
            print_error "Неверный выбор"
            exit 1
            ;;
    esac
}

# Запуск
main
