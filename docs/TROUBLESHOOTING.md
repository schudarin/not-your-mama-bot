# Устранение неполадок

## Проблемы с установкой

### Ошибка "No matching distribution found for ddgs>=8.0.0"

**Проблема:**
```
ERROR: Could not find a version that satisfies the requirement ddgs>=8.0.0 (from versions: none)
ERROR: No matching distribution found for ddgs>=8.0.0
```

**Решение:**
1. Обновите репозиторий: `git pull origin master`
2. Установите ddgs вручную: `pip install ddgs`
3. Или используйте альтернативу: `pip install duckduckgo-search>=4.0.0`

### Проблемы с поиском

**Ошибка "Ratelimit":**
- Обновлена библиотека с `duckduckgo-search` на `ddgs`
- Добавлены задержки и альтернативные методы поиска
- Обновите бота: `git pull origin master && pip install -r requirements.txt`

**Поиск не работает:**
1. Проверьте интернет-соединение
2. Убедитесь, что установлен модуль ddgs: `pip show ddgs`
3. Проверьте логи: `./scripts/debug.sh`

### Проблемы с правами доступа

**Ошибка "Permission denied":**
```bash
# Для локальной установки
chmod +x scripts/*.sh

# Для системной установки
sudo ./scripts/install.sh
```

### Проблемы с виртуальным окружением

**Ошибка "No module named 'venv'":**
```bash
# Ubuntu/Debian
sudo apt-get install python3-venv python3.8-venv

# CentOS/RHEL
sudo yum install python3-venv

# Альтернатива
pip install virtualenv
```

## Частые команды для диагностики

```bash
# Проверка статуса
./scripts/debug.sh

# Тестирование компонентов
./scripts/test-bot.sh

# Просмотр логов
tail -f logs/bot.log

# Проверка зависимостей
pip list | grep -E "(telegram|ddgs|openai)"
```

## Обновление бота

```bash
# Автоматическое обновление
git pull origin master
pip install -r requirements.txt

# Перезапуск сервиса (если установлен как systemd)
sudo systemctl restart not-your-mama-bot
```
