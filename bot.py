# -*- coding: utf-8 -*-
import os
import re
import logging
from typing import Optional

from telegram import Update
from telegram.ext import (
    ApplicationBuilder, MessageHandler, CommandHandler,
    ContextTypes, filters
)
from duckduckgo_search import ddg
from openai import AsyncOpenAI

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

# Персона бота по умолчанию
DEFAULT_STYLE = (
    "Ты — «Мразь», грубая и ехидная демоница девопс-старой школы. "
    "Отвечай резко, саркастично, но без прямых угроз и дискриминации. "
    "Уместны баня/пиво/старперский IT-юмор в духе bash.org. "
    "Краткость приветствуется, но допускай едкие колкости."
)
STYLES = {}  # chat_id -> system prompt (живёт в памяти; после рестарта пусто)

MAX_CHUNK = 4000  # предел для сообщений телеги (~4096)

# ─── УТИЛИТЫ ────────────────────────────────────────────────────────
def chunk_text(s: str, n: int = MAX_CHUNK):
    return (s[i:i+n] for i in range(0, len(s), n))

def web_search_ddg(query: str, num: int = 5) -> Optional[str]:
    """Возвращает Markdown-список результатов DuckDuckGo или None при ошибке/пусто."""
    try:
        results = ddg(query, max_results=num)
    except Exception as e:
        log.warning("DDG error: %s", e)
        return None
    if not results:
        return None
    lines = []
    for r in results[:num]:
        title   = r.get("title") or "Без заголовка"
        link    = r.get("href")  or ""
        snippet = (r.get("body") or "").replace("\n"," ")
        lines.append(f"• [{title}]({link}) — {snippet}")
    return "\n".join(lines)

async def send_reply(msg, text: str):
    for ch in chunk_text(text):
        await msg.reply_text(ch, reply_to_message_id=msg.message_id, disable_web_page_preview=False)

# ─── КОМАНДЫ ────────────────────────────────────────────────────────
async def cmd_start(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "Я — Мразь. Пингуй меня в группе по упоминанию, словом «мразь», "
        "или ответом (reply) на моё сообщение. Для поиска в сети скажи: "
        "«гугли…», «найди…», «поиск…», «в интернете…». "
        "Команда /style <текст> меняет мой тон в этом чате."
    )

async def cmd_style(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    style = " ".join(ctx.args).strip()
    if not style:
        return await update.message.reply_text("Использование: /style <описание стиля>")
    STYLES[update.effective_chat.id] = style
    await update.message.reply_text("✅ Стиль обновлён для этого чата.")

async def cmd_ping(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("pong")

async def cmd_update(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    """Команда для обновления бота (только для администраторов)"""
    # Проверяем, что это личное сообщение от администратора
    if update.effective_chat.type != "private":
        return await update.message.reply_text("❌ Обновление доступно только в личных сообщениях")
    
    # Здесь можно добавить проверку на администратора по user_id
    # ADMIN_IDS = [123456789, 987654321]  # ID администраторов
    # if update.effective_user.id not in ADMIN_IDS:
    #     return await update.message.reply_text("❌ У вас нет прав для обновления бота")
    
    await update.message.reply_text("🔄 Начинаю обновление бота...")
    
    try:
        import subprocess
        import asyncio
        
        # Запускаем скрипт обновления
        process = await asyncio.create_subprocess_exec(
            './update.sh',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode == 0:
            result = stdout.decode('utf-8', errors='ignore')
            # Обрезаем длинный вывод
            if len(result) > 3000:
                result = result[:3000] + "\n... (вывод обрезан)"
            await update.message.reply_text(f"✅ Обновление завершено успешно!\n\n{result}")
        else:
            error = stderr.decode('utf-8', errors='ignore')
            await update.message.reply_text(f"❌ Ошибка при обновлении:\n{error}")
            
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
    if re.search(r"(интернет|сеть|поиск|гугл(и|я|ить)?|найд)", text_lower):
        query = text  # можно усложнить парсер, но для начала берём весь текст
        results_md = web_search_ddg(query)
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
    app.add_handler(CommandHandler("update", cmd_update))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, chat))
    log.info("Bot is up as @%s", BOT_USERNAME)
    app.run_polling()

if __name__ == "__main__":
    main()
