#!/bin/bash

# Скрипт обновления Not Your Mama Bot
set -e

echo "🔄 Not Your Mama Bot - Скрипт обновления"
echo "======================================="

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

# Проверяем, что git инициализирован
if [ ! -d ".git" ]; then
    echo "❌ Git репозиторий не найден. Убедитесь, что проект клонирован из git."
    exit 1
fi

# Сохраняем текущую ветку
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Текущая ветка: $CURRENT_BRANCH"

# Проверяем, есть ли изменения в рабочей директории
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Обнаружены локальные изменения. Сохраняем их..."
    git stash push -m "Автоматическое сохранение перед обновлением $(date)"
    STASHED=true
fi

# Получаем последние изменения
echo "📥 Получение последних изменений из репозитория..."
git fetch origin

# Проверяем, есть ли новые коммиты
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH)

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo "✅ Бот уже обновлен до последней версии"
    if [ "$STASHED" = true ]; then
        echo "📦 Восстанавливаем сохраненные изменения..."
        git stash pop
    fi
    exit 0
fi

echo "🔄 Обнаружены новые изменения. Обновляем..."

# Переключаемся на последнюю версию
git reset --hard origin/$CURRENT_BRANCH

# Обновляем зависимости, если requirements.txt изменился
if git diff --name-only HEAD~1 HEAD | grep -q "requirements.txt"; then
    echo "📚 Обновление зависимостей..."
    if [ -d "venv" ]; then
        source venv/bin/activate
        pip install -r requirements.txt
    else
        pip install -r requirements.txt
    fi
fi

# Восстанавливаем сохраненные изменения, если они были
if [ "$STASHED" = true ]; then
    echo "📦 Восстанавливаем сохраненные изменения..."
    if ! git stash pop; then
        echo "⚠️  Конфликт при восстановлении изменений. Проверьте git stash list"
    fi
fi

# Проверяем, запущен ли бот через systemd
if systemctl is-active --quiet not-your-mama-bot; then
    echo "🔄 Перезапуск службы systemd..."
    sudo systemctl restart not-your-mama-bot
    echo "✅ Служба перезапущена"
elif systemctl is-active --quiet telegram-bot; then
    echo "🔄 Перезапуск службы telegram-bot..."
    sudo systemctl restart telegram-bot
    echo "✅ Служба перезапущена"
else
    echo "ℹ️  Служба systemd не найдена. Бот может быть запущен вручную."
    echo "   Для перезапуска используйте: ./deploy.sh"
fi

# Показываем информацию о последнем коммите
echo ""
echo "📋 Информация о последнем обновлении:"
echo "   Коммит: $(git rev-parse --short HEAD)"
echo "   Автор: $(git log -1 --pretty=format:'%an')"
echo "   Дата: $(git log -1 --pretty=format:'%cd')"
echo "   Сообщение: $(git log -1 --pretty=format:'%s')"

echo ""
echo "✅ Обновление завершено успешно!"
