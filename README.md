# Not Your Mama Bot

🤖 Саркастичный Telegram бот с ИИ-функциями и веб-поиском

## Быстрый старт

```bash
# Установка
./scripts/install.sh

# Удаление
sudo ./scripts/uninstall.sh
```

## Основные возможности

- 🧠 **ИИ-ответы** через OpenAI GPT-4o-mini
- 🔍 **Веб-поиск** через DuckDuckGo
- 🎭 **Настраиваемая личность** для каждого чата
- 👥 **Система администраторов** с правами доступа
- 🔄 **Автоматические обновления** через Telegram или cron
- 🐧 **Оптимизирован для Ubuntu/Linux**

## Команды

- `/start` - Информация и настройка супер-администратора
- `/style` - Показать/изменить стиль бота
- `/admin` - Управление администраторами
- `/update` - Обновление бота (только для админов)
- `/ping` - Проверка работы бота

## Документация

📚 [Полная документация](docs/README.md)  
🔧 [Руководство по установке](docs/README.md#установка)  
🛡️ [Безопасность](docs/SECURITY.md)  
📖 [Технический анализ](docs/ANALYSIS.md)  
🤝 [Участие в разработке](docs/CONTRIBUTING.md)

## Структура проекта

```
not-your-mama-bot/
├── bot.py                 # Основной код бота
├── requirements.txt       # Python зависимости
├── Dockerfile            # Docker конфигурация
├── docker-compose.yml    # Docker Compose
├── scripts/              # Скрипты установки и управления
├── docs/                 # Документация
├── examples/             # Примеры конфигурации
└── logs/                 # Логи (создается автоматически)
```

## Требования

- Ubuntu/Linux
- Python 3.8+
- Telegram Bot Token
- OpenAI API Key

## Лицензия

MIT License - см. [LICENSE](LICENSE)
