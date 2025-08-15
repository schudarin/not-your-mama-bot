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
    """Простой и надежный поиск через DuckDuckGo"""
    try:
        with DDGS() as ddgs:
            # Используем только news search - он работает стабильно
            results = list(ddgs.news(query, max_results=num))
            
            if not results:
                return None
                
            lines = []
            for r in results[:num]:
                title = r.get("title", "Без заголовка")
                link = r.get("href", "")
                snippet = (r.get("body") or "")[:150]  # Ограничиваем длину
                if len(snippet) == 150:
                    snippet += "..."
                lines.append(f"• [{title}]({link}) — {snippet}")
            return "\n".join(lines)
            
    except Exception as e:
        log.warning(f"Search error: {e}")
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
    """Команда для обновления бота (только для администраторов)"""
    user_id = update.effective_user.id
    
    # Проверяем права администратора
    if user_id not in ADMIN_IDS:
        return await update.message.reply_text("❌ У вас нет прав для обновления бота")
    
    # Проверяем, что это личное сообщение
    if update.effective_chat.type != "private":
        return await update.message.reply_text("❌ Обновление доступно только в личных сообщениях")
    
    await update.message.reply_text("🔄 Начинаю обновление бота...")
    
    try:
        import subprocess
        import asyncio
        
        import os
        
        # Определяем тип установки
        current_dir = os.getcwd()
        opt_exists = os.path.exists("/opt/not-your-mama-bot/bot.py")
        
        log.info(f"Отладка обновления: current_dir={current_dir}, opt_exists={opt_exists}")
        
        # Всегда используем systemd установку если она существует
        if opt_exists:
            # Systemd установка
            update_script = "/opt/not-your-mama-bot/scripts/update.sh"
            working_dir = "/opt/not-your-mama-bot"
            log.info(f"Используем systemd установку: {update_script}")
        else:
            # Локальная установка
            update_script = "./scripts/update.sh"
            working_dir = current_dir
            log.info(f"Используем локальную установку: {update_script}")
        
        # Проверяем что скрипт существует
        if not os.path.exists(update_script):
            error_msg = f"❌ Скрипт обновления не найден: {update_script}"
            log.error(error_msg)
            await update.message.reply_text(error_msg)
            return
        
        # Запускаем скрипт обновления
        process = await asyncio.create_subprocess_exec(
            update_script,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=working_dir
        )
        
        stdout, stderr = await process.communicate()
        
        # Логируем результат для отладки
        stdout_text = stdout.decode('utf-8', errors='ignore')
        stderr_text = stderr.decode('utf-8', errors='ignore')
        
        log.info(f"Update script return code: {process.returncode}")
        log.info(f"Update script stdout: {stdout_text}")
        if stderr_text:
            log.error(f"Update script stderr: {stderr_text}")
        
        if process.returncode == 0:
            # Обрезаем длинный вывод
            if len(stdout_text) > 3000:
                stdout_text = stdout_text[:3000] + "\n... (вывод обрезан)"
            await update.message.reply_text(f"✅ Обновление завершено успешно!\n\n{stdout_text}")
        else:
            error_msg = f"❌ Ошибка при обновлении (код: {process.returncode}):\n"
            if stderr_text:
                error_msg += stderr_text
            else:
                error_msg += stdout_text
            await update.message.reply_text(error_msg)
            
    except Exception as e:
        await update.message.reply_text(f"❌ Ошибка при запуске обновления: {str(e)}")

# ─── ОСНОВНОЙ ХЭНДЛЕР ───────────────────────────────────────────────
async def chat(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    msg        = update.message
    if not msg or not msg.text:
        return
    text       = msg.text.strip()
    text_lower = text.lower()

    # 1) ТРИГГЕР ПОИСКА (ставим раньше обычного ответа)
    # ловим «интернет/сеть/поиск/гугл/гугли/гуглить/найди…»
    if re.search(r"(интернет|сеть|поиск|гугл(и|я|ить)?|погугл(и|я|ить)?|найд)", text_lower):
        query = text  # можно усложнить парсер, но для начала берём весь текст
        
        # Простой поиск через DuckDuckGo
        results_md = web_search(query)
        
        if not results_md:
            return await send_reply(msg, "Поиск в интернете временно недоступен.")

        # Саммари найденного через OpenAI
        try:
            summary_resp = await openai.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system",
                     "content": "Тебе дали список результатов поиска (заголовок, ссылка, сниппет). Кратко резюмируй по-русски с 2–5 пунктами и выводом."},
                    {"role": "user",
                     "content": f"Сделай краткое резюме для следующего поиска:\n\n{results_md}"}
                ],
                temperature=0.5,
            )
            summary = summary_resp.choices[0].message.content
        except Exception as e:
            log.warning("OpenAI summary error: %s", e)
            return await send_reply(msg, "Поиск в интернете временно недоступен.")

        return await send_reply(msg, f"🔍 Кратко по запросу «{query}»:\n\n{summary}")

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
