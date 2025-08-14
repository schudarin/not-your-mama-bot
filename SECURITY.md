# Безопасность Not Your Mama Bot

## Команда обновления через Telegram

### Текущая реализация

Команда `/update` доступна всем пользователям в личных сообщениях. Это **небезопасно** для продакшена.

### Рекомендуемые меры безопасности

#### 1. Ограничение доступа по ID пользователей

Раскомментируйте и настройте проверку администраторов в `bot.py`:

```python
# Добавьте в начало файла bot.py
ADMIN_IDS = [
    123456789,  # Ваш Telegram ID
    987654321,  # ID других администраторов
]

# В функции cmd_update раскомментируйте:
if update.effective_user.id not in ADMIN_IDS:
    return await update.message.reply_text("❌ У вас нет прав для обновления бота")
```

#### 2. Получение вашего Telegram ID

1. Отправьте боту команду `/start`
2. Добавьте в `bot.py` временный код для логирования ID:

```python
async def cmd_start(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    username = update.effective_user.username
    log.info(f"User {username} (ID: {user_id}) used /start")
    # ... остальной код
```

#### 3. Дополнительные меры безопасности

- **Webhook вместо polling**: Используйте webhook для продакшена
- **HTTPS**: Обязательно используйте SSL/TLS
- **Firewall**: Ограничьте доступ к серверу
- **Мониторинг**: Настройте логирование всех действий

#### 4. Альтернативные способы обновления

**Рекомендуется использовать только:**

- `./update.sh` - ручное обновление на сервере
- Автоматические обновления через cron
- CI/CD pipeline (GitHub Actions, GitLab CI)

**Не рекомендуется:**

- Команда `/update` в Telegram (если не настроена проверка администраторов)

## Безопасность systemd сервиса

### Текущие меры безопасности

- Запуск от непривилегированного пользователя `botuser`
- Ограниченные права доступа к файловой системе
- Изолированное окружение

### Дополнительные рекомендации

- Регулярно обновляйте зависимости
- Мониторьте логи на подозрительную активность
- Используйте SELinux или AppArmor
- Ограничьте сетевой доступ бота

## Мониторинг и логирование

### Логи systemd

```bash
# Просмотр логов в реальном времени
sudo journalctl -u not-your-mama-bot -f

# Логи за последний час
sudo journalctl -u not-your-mama-bot --since "1 hour ago"
```

### Логи обновлений

```bash
# Логи автоматических обновлений
tail -f /opt/not-your-mama-bot/logs/update.log
```

## Обновление зависимостей

Регулярно проверяйте уязвимости:

```bash
# Обновление pip
pip install --upgrade pip

# Проверка уязвимостей (требует safety)
pip install safety
safety check

# Обновление зависимостей
pip install --upgrade -r requirements.txt
```

## Резервное копирование

### Автоматическое резервное копирование

```bash
# Создайте скрипт backup.sh
#!/bin/bash
BACKUP_DIR="/backup/not-your-mama-bot"
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "$BACKUP_DIR/backup_$DATE.tar.gz" /opt/not-your-mama-bot
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +7 -delete
```

### Добавьте в cron для ежедневного резервного копирования

```bash
0 2 * * * /path/to/backup.sh
```
