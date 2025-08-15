# -*- coding: utf-8 -*-
import os
import re
import logging
import json
from typing import Optional

# Загружаем переменные окружения из .env файла
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # Если python-dotenv не установлен, пытаемся загрузить .env вручную
    env_file = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value

from telegram import Update
from telegram.ext import (
    ApplicationBuilder, MessageHandler, CommandHandler,
    ContextTypes, filters
)
from duckduckgo_search import DDGS
from openai import AsyncOpenAI
import requests

# ─── ЛОГИ ───────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)
log = logging.getLogger("mrazz-bot")

# ─── КОНФИГ ─────────────────────────────────────────────────────────
TG_TOKEN     = os.getenv("TELEGRAM_BOT_TOKEN")
OPENAI_KEY   = os.getenv("OPENAI_API_KEY")
BOT_USERNAME = os.getenv("BOT_USERNAME", "").lstrip("@")

openai = AsyncOpenAI(api_key=OPENAI_KEY)

# Персона бота по умолчанию (нейтральная)
DEFAULT_STYLE = (
    "Ты — полезный и дружелюбный ИИ-ассистент. "
    "Отвечай вежливо, информативно и по делу. "
    "Можешь использовать юмор, но оставайся уважительным. "
    "Краткость приветствуется, но давай полные ответы."
)

# Система администраторов
ADMIN_IDS = set()  # Множество ID администраторов
SUPER_ADMIN_ID = None  # ID супер-администратора (первый пользователь)

# Файл для сохранения администраторов
ADMINS_FILE = "/opt/not-your-mama-bot/logs/admins.json"

def load_admins():
    """Загружает список администраторов из файла"""
    global ADMIN_IDS, SUPER_ADMIN_ID
    try:
        if os.path.exists(ADMINS_FILE):
            with open(ADMINS_FILE, 'r') as f:
                data = json.load(f)
                ADMIN_IDS = set(data.get('admin_ids', []))
                SUPER_ADMIN_ID = data.get('super_admin_id')
                log.info(f"Загружено {len(ADMIN_IDS)} администраторов")
    except Exception as e:
        log.warning(f"Ошибка загрузки администраторов: {e}")

def save_admins():
    """Сохраняет список администраторов в файл"""
    try:
        data = {
            'admin_ids': list(ADMIN_IDS),
            'super_admin_id': SUPER_ADMIN_ID
        }
        with open(ADMINS_FILE, 'w') as f:
            json.dump(data, f)
        log.info(f"Сохранено {len(ADMIN_IDS)} администраторов")
    except Exception as e:
        log.warning(f"Ошибка сохранения администраторов: {e}")

# Загружаем администраторов при запуске
load_admins()

STYLES = {}  # chat_id -> system prompt (живёт в памяти; после рестарта пусто)

MAX_CHUNK = 4000  # предел для сообщений телеги (~4096)

# ─── УТИЛИТЫ ────────────────────────────────────────────────────────
def chunk_text(s: str, n: int = MAX_CHUNK):
    return (s[i:i+n] for i in range(0, len(s), n))

def web_search(query: str, num: int = 5) -> Optional[str]:
    """Полностью переписанная функция поиска через DuckDuckGo"""
    try:
        with DDGS() as ddgs:
            # Используем обычный поиск вместо news для более широких результатов
            results = list(ddgs.text(query, max_results=num))
            
            if not results:
                log.warning(f"No search results for query: {query}")
                return None
                
            log.info(f"Found {len(results)} results for query: {query}")
            
            lines = []
            for i, r in enumerate(results[:num], 1):
                title = r.get("title", "Без заголовка")
                link = r.get("link", "")
                snippet = r.get("body", "")
                
                # Ограничиваем длину сниппета
                if len(snippet) > 200:
                    snippet = snippet[:200] + "..."
                
                lines.append(f"{i}. **{title}**\n   {snippet}\n   {link}\n")
            
            return "\n".join(lines)
            
    except Exception as e:
        log.error(f"Search error for query '{query}': {e}")
        return None

async def send_reply(msg, text: str):
    for ch in chunk_text(text):
        await msg.reply_text(ch, reply_to_message_id=msg.message_id, disable_web_page_preview=False)

# ─── КОМАНДЫ ────────────────────────────────────────────────────────
async def cmd_start(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    username = update.effective_user.username or "Без имени"
    
    # Автоматически назначаем первого пользователя супер-администратором
    global SUPER_ADMIN_ID
    if SUPER_ADMIN_ID is None:
        SUPER_ADMIN_ID = user_id
        ADMIN_IDS.add(user_id)
        save_admins()  # Сохраняем в файл
        log.info(f"Назначен супер-администратор: {username} (ID: {user_id})")
    
    # Логируем всех пользователей для отладки
    log.info(f"Пользователь {username} (ID: {user_id}) использовал /start")
    
    # Разные сообщения для администраторов и обычных пользователей
    if user_id in ADMIN_IDS:
        admin_commands = """
🔧 Команды администратора:
/admin - Управление администраторами
/style - Настройка стиля бота
/update - Обновление бота (только в личных сообщениях)
"""
    else:
        admin_commands = ""
    
    await update.message.reply_text(
        f"Привет! Я — {BOT_USERNAME}. 🤖\n\n"
        "📋 Основные команды:\n"
        "• Упоминай меня в группах или используй слово «мразь»\n"
        "• Отвечай на мои сообщения\n"
        "• Для поиска: «гугли», «найди», «поиск», «в интернете»\n"
        "• /style - изменить мой стиль в этом чате\n"
        "• /ping - проверить работу бота\n\n"
        f"💬 Личные сообщения: {admin_commands}"
    )

async def cmd_style(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    current_style = STYLES.get(chat_id, DEFAULT_STYLE)
    
    style = " ".join(ctx.args).strip()
    if not style:
        # Показываем текущий стиль и предлагаем обновить
        await update.message.reply_text(
            f"🎭 Текущий стиль бота в этом чате:\n\n"
            f"«{current_style}»\n\n"
            f"💡 Для изменения отправьте:\n"
            f"/style <новое описание стиля>\n\n"
            f"📝 Примеры:\n"
            f"• /style Ты — вежливый помощник\n"
            f"• /style Ты — саркастичный бот\n"
            f"• /style Ты — грубый девопс-инженер"
        )
        return
    
    # Обновляем стиль
    STYLES[chat_id] = style
    await update.message.reply_text(
        f"✅ Стиль обновлён для этого чата!\n\n"
        f"🎭 Новый стиль:\n"
        f"«{style}»"
    )

async def cmd_ping(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("pong")

async def cmd_admin(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    """Команда для управления администраторами"""
    user_id = update.effective_user.id
    
    # Проверяем права администратора
    if user_id not in ADMIN_IDS:
        return await update.message.reply_text("❌ У вас нет прав администратора")
    
    # Проверяем, что это личное сообщение
    if update.effective_chat.type != "private":
        return await update.message.reply_text("❌ Управление администраторами доступно только в личных сообщениях")
    
    args = ctx.args
    if not args:
        # Показываем список администраторов
        admin_list = []
        for admin_id in ADMIN_IDS:
            if admin_id == SUPER_ADMIN_ID:
                admin_list.append(f"👑 {admin_id} (супер-админ)")
            else:
                admin_list.append(f"🔧 {admin_id}")
        
        await update.message.reply_text(
            f"👥 Список администраторов:\n\n"
            f"{chr(10).join(admin_list)}\n\n"
            f"💡 Команды управления:\n"
            f"• /admin add <ID> - добавить администратора\n"
            f"• /admin remove <ID> - удалить администратора\n"
            f"• /admin list - показать список (текущая команда)"
        )
        return
    
    action = args[0].lower()
    
    if action == "list":
        # Показываем список администраторов
        admin_list = []
        for admin_id in ADMIN_IDS:
            if admin_id == SUPER_ADMIN_ID:
                admin_list.append(f"👑 {admin_id} (супер-админ)")
            else:
                admin_list.append(f"🔧 {admin_id}")
        
        await update.message.reply_text(
            f"👥 Список администраторов:\n\n"
            f"{chr(10).join(admin_list)}"
        )
    
    elif action == "add":
        if len(args) < 2:
            await update.message.reply_text("❌ Укажите ID пользователя: /admin add <ID>")
            return
        
        try:
            new_admin_id = int(args[1])
            if new_admin_id in ADMIN_IDS:
                await update.message.reply_text("✅ Этот пользователь уже администратор")
                return
            
            ADMIN_IDS.add(new_admin_id)
            save_admins()  # Сохраняем изменения
            await update.message.reply_text(f"✅ Администратор {new_admin_id} добавлен")
            
        except ValueError:
            await update.message.reply_text("❌ Неверный формат ID. ID должен быть числом")
    
    elif action == "remove":
        if len(args) < 2:
            await update.message.reply_text("❌ Укажите ID пользователя: /admin remove <ID>")
            return
        
        try:
            remove_admin_id = int(args[1])
            
            # Нельзя удалить супер-администратора
            if remove_admin_id == SUPER_ADMIN_ID:
                await update.message.reply_text("❌ Нельзя удалить супер-администратора")
                return
            
            if remove_admin_id not in ADMIN_IDS:
                await update.message.reply_text("❌ Этот пользователь не является администратором")
                return
            
            ADMIN_IDS.remove(remove_admin_id)
            save_admins()  # Сохраняем изменения
            await update.message.reply_text(f"✅ Администратор {remove_admin_id} удален")
            
        except ValueError:
            await update.message.reply_text("❌ Неверный формат ID. ID должен быть числом")
    
    else:
        await update.message.reply_text(
            "❌ Неизвестная команда. Используйте:\n"
            "• /admin add <ID> - добавить администратора\n"
            "• /admin remove <ID> - удалить администратора\n"
            "• /admin list - показать список"
        )

async def cmd_update(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    """Команда для управления ботом (только для администраторов)"""
    user_id = update.effective_user.id
    
    # Проверяем права администратора
    if user_id not in ADMIN_IDS:
        return await update.message.reply_text("❌ У вас нет прав для управления ботом")
    
    # Проверяем, что это личное сообщение
    if update.effective_chat.type != "private":
        return await update.message.reply_text("❌ Управление доступно только в личных сообщениях")
    
    # Проверяем аргументы команды
    args = ctx.args
    if not args:
        # Показываем доступные команды
        await update.message.reply_text(
            "🔧 Управление ботом:\n\n"
            "📋 Доступные команды:\n"
            "• /update status - статус бота и версия\n"
            "• /update restart - перезапуск службы\n"
            "• /update info - информация о системе\n"
            "• /update pull - попытка обновления (если возможно)\n\n"
            "💡 В read-only среде используйте:\n"
            "• /update status - для проверки версии\n"
            "• /update restart - для перезапуска"
        )
        return
    
    action = args[0].lower()
    
    if action == "status":
        await update.message.reply_text("🔄 Проверяю статус бота...")
        await cmd_update_status(update, ctx)
    
    elif action == "restart":
        await update.message.reply_text("🔄 Перезапускаю службу...")
        await cmd_update_restart(update, ctx)
    
    elif action == "info":
        await update.message.reply_text("📊 Собираю информацию о системе...")
        await cmd_update_info(update, ctx)
    
    elif action == "pull":
        await update.message.reply_text("🔄 Пытаюсь обновить бота...")
        await cmd_update_pull(update, ctx)
    
    else:
        await update.message.reply_text(
            "❌ Неизвестная команда. Используйте:\n"
            "• /update status - статус бота\n"
            "• /update restart - перезапуск службы\n"
            "• /update info - информация о системе\n"
            "• /update pull - попытка обновления"
        )

async def cmd_update_status(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    """Проверка статуса бота и версии"""
    try:
        import subprocess
        import asyncio
        import os
        
        # Определяем директорию бота
        current_dir = os.getcwd()
        opt_exists = os.path.exists("/opt/not-your-mama-bot/bot.py")
        
        if opt_exists:
            working_dir = "/opt/not-your-mama-bot"
        else:
            working_dir = current_dir
        
        # Проверяем версию git
        process = await asyncio.create_subprocess_exec(
            "git", "rev-parse", "--short", "HEAD",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=working_dir
        )
        
        stdout, stderr = await process.communicate()
        git_version = stdout.decode('utf-8').strip() if process.returncode == 0 else "Неизвестно"
        
        # Проверяем статус службы systemd
        service_status = "Недоступно"
        if opt_exists:
            process = await asyncio.create_subprocess_exec(
                "systemctl", "is-active", "not-your-mama-bot",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await process.communicate()
            if process.returncode == 0:
                service_status = "Активна" if stdout.decode().strip() == "active" else "Неактивна"
        
        # Проверяем права на запись
        write_access = "Доступна" if os.access(working_dir, os.W_OK) else "Только чтение"
        
        status_msg = (
            f"📊 Статус бота:\n\n"
            f"🆔 Версия: {git_version}\n"
            f"📁 Директория: {working_dir}\n"
            f"✍️ Права записи: {write_access}\n"
            f"🔧 Служба systemd: {service_status}\n"
            f"🤖 Бот: Работает ✅"
        )
        
        await update.message.reply_text(status_msg)
        
    except Exception as e:
        log.error(f"Status check error: {e}")
        await update.message.reply_text(f"❌ Ошибка при проверке статуса: {str(e)}")

async def cmd_update_restart(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    """Перезапуск службы systemd"""
    try:
        import subprocess
        import asyncio
        import os
        
        # Проверяем, есть ли systemd установка
        if not os.path.exists("/opt/not-your-mama-bot/bot.py"):
            await update.message.reply_text("❌ Systemd установка не найдена. Перезапуск недоступен.")
            return
        
        # Перезапускаем службу
        process = await asyncio.create_subprocess_exec(
            "sudo", "systemctl", "restart", "not-your-mama-bot",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode == 0:
            await update.message.reply_text("✅ Служба успешно перезапущена!")
        else:
            error_msg = stderr.decode('utf-8', errors='ignore')
            await update.message.reply_text(f"❌ Ошибка при перезапуске:\n{error_msg}")
        
    except Exception as e:
        log.error(f"Restart error: {e}")
        await update.message.reply_text(f"❌ Ошибка при перезапуске: {str(e)}")

async def cmd_update_info(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    """Информация о системе"""
    try:
        import subprocess
        import asyncio
        import os
        import platform
        
        # Системная информация
        system_info = (
            f"💻 Система: {platform.system()} {platform.release()}\n"
            f"🐍 Python: {platform.python_version()}\n"
            f"📁 Рабочая директория: {os.getcwd()}\n"
        )
        
        # Проверяем доступность systemd
        process = await asyncio.create_subprocess_exec(
            "systemctl", "--version",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await process.communicate()
        systemd_available = "Доступен" if process.returncode == 0 else "Недоступен"
        
        # Проверяем права на запись
        write_access = "Доступна" if os.access(".", os.W_OK) else "Только чтение"
        
        # Проверяем наличие git
        process = await asyncio.create_subprocess_exec(
            "git", "--version",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await process.communicate()
        git_version = stdout.decode().strip() if process.returncode == 0 else "Недоступен"
        
        info_msg = (
            f"📊 Информация о системе:\n\n"
            f"{system_info}"
            f"🔧 Systemd: {systemd_available}\n"
            f"📝 Git: {git_version}\n"
            f"✍️ Права записи: {write_access}\n"
            f"🤖 Бот: @{BOT_USERNAME}"
        )
        
        await update.message.reply_text(info_msg)
        
    except Exception as e:
        log.error(f"Info error: {e}")
        await update.message.reply_text(f"❌ Ошибка при получении информации: {str(e)}")

async def cmd_update_pull(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    """Попытка обновления через git pull"""
    try:
        import subprocess
        import asyncio
        import os
        
        # Определяем директорию бота
        current_dir = os.getcwd()
        opt_exists = os.path.exists("/opt/not-your-mama-bot/bot.py")
        
        if opt_exists:
            working_dir = "/opt/not-your-mama-bot"
        else:
            working_dir = current_dir
        
        # Проверяем права на запись
        if not os.access(working_dir, os.W_OK):
            await update.message.reply_text(
                "❌ Файловая система доступна только для чтения.\n\n"
                "💡 Для обновления:\n"
                "• Подключитесь по SSH\n"
                "• Выполните: cd /opt/not-your-mama-bot && git pull\n"
                "• Перезапустите: sudo systemctl restart not-your-mama-bot"
            )
            return
        
        # Выполняем git pull
        process = await asyncio.create_subprocess_exec(
            "git", "pull", "origin", "master",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=working_dir
        )
        
        stdout, stderr = await process.communicate()
        stdout_text = stdout.decode('utf-8', errors='ignore')
        stderr_text = stderr.decode('utf-8', errors='ignore')
        
        if process.returncode == 0:
            # Проверяем, были ли обновления
            if "Already up to date" in stdout_text:
                await update.message.reply_text("✅ Бот уже обновлен до последней версии!")
            else:
                await update.message.reply_text(f"✅ Обновление завершено!\n\n{stdout_text}")
                
                # Перезапускаем службу если это systemd установка
                if opt_exists:
                    await update.message.reply_text("🔄 Перезапускаю службу...")
                    await cmd_update_restart(update, ctx)
        else:
            error_msg = f"❌ Ошибка при обновлении:\n{stderr_text or stdout_text}"
            await update.message.reply_text(error_msg)
        
    except Exception as e:
        log.error(f"Pull error: {e}")
        await update.message.reply_text(f"❌ Ошибка при обновлении: {str(e)}")

# ─── ОСНОВНОЙ ХЭНДЛЕР ───────────────────────────────────────────────
async def chat(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    msg        = update.message
    if not msg or not msg.text:
        return
    text       = msg.text.strip()
    text_lower = text.lower()

    # 1) ТРИГГЕР ПОИСКА (ставим раньше обычного ответа)
    # ловим «интернет/сеть/поиск/гугл/гугли/гуглить/найд»
    if re.search(r"(интернет|сеть|поиск|гугл(и|я|ить)?|погугл(и|я|ить)?|найд)", text_lower):
        # Извлекаем поисковый запрос, убирая триггерные слова
        query = re.sub(r"(интернет|сеть|поиск|гугл(и|я|ить)?|погугл(и|я|ить)?|найд)", "", text, flags=re.IGNORECASE).strip()
        
        # Если после удаления триггерных слов ничего не осталось, используем весь текст
        if not query:
            query = text.strip()
        
        log.info(f"Search request: '{query}'")
        
        # Выполняем поиск
        results_md = web_search(query)
        
        if not results_md:
            return await send_reply(msg, "🔍 Поиск не дал результатов. Попробуйте другой запрос.")
        
        # Саммари найденного через OpenAI
        try:
            summary_resp = await openai.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system",
                     "content": "Ты помощник для анализа результатов поиска. Кратко резюмируй найденную информацию на русском языке в 2-3 предложения."},
                    {"role": "user",
                     "content": f"Проанализируй результаты поиска по запросу '{query}':\n\n{results_md}"}
                ],
                temperature=0.3,
                max_tokens=300
            )
            summary = summary_resp.choices[0].message.content
        except Exception as e:
            log.error(f"OpenAI summary error: {e}")
            # Если не удалось создать саммари, отправляем сырые результаты
            return await send_reply(msg, f"🔍 Результаты поиска по запросу «{query}»:\n\n{results_md}")

        return await send_reply(msg, f"🔍 По запросу «{query}»:\n\n{summary}\n\n📋 Подробные результаты:\n{results_md}")

    # 2) ТРИГГЕР ОБЫЧНОГО ОТВЕТА
    is_reply_to_bot = (
        msg.reply_to_message and msg.reply_to_message.from_user
        and msg.reply_to_message.from_user.username == BOT_USERNAME
    )
    if msg.chat.type != "private" and not (
        f"@{BOT_USERNAME}".lower() in text_lower
        or "мразь" in text_lower
        or is_reply_to_bot
    ):
        return

    # чистим служебное
    prompt = re.sub(fr"@{re.escape(BOT_USERNAME)}|мразь", "", text, flags=re.IGNORECASE).strip()
    system = STYLES.get(msg.chat.id, DEFAULT_STYLE)

    # 3) Вызов OpenAI
    try:
        resp = await openai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system},
                {"role": "user",   "content": prompt or "Отвечай в своём стиле."},
            ],
            temperature=0.7,
        )
        answer = resp.choices[0].message.content
    except Exception as e:
        log.warning("OpenAI chat error: %s", e)
        return await send_reply(msg, "Что-то пошло не так. Я починюсь.")

    # 4) Отправляем reply
    await send_reply(msg, answer)

# ─── ЗАПУСК ─────────────────────────────────────────────────────────
def main():
    app = ApplicationBuilder().token(TG_TOKEN).build()
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("style", cmd_style))
    app.add_handler(CommandHandler("ping",  cmd_ping))
    app.add_handler(CommandHandler("admin", cmd_admin))
    app.add_handler(CommandHandler("update", cmd_update))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, chat))
    log.info("Bot is up as @%s", BOT_USERNAME)
    app.run_polling()

if __name__ == "__main__":
    main()
