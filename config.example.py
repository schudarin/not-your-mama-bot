# Example configuration file
# Copy this to config.py and fill in your actual values

import os

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN = "your_telegram_bot_token_here"
BOT_USERNAME = "your_bot_username_here"  # without @

# OpenAI Configuration
OPENAI_API_KEY = "your_openai_api_key_here"

# Bot Personality Settings
DEFAULT_STYLE = (
    "Ты — «Мразь», грубая и ехидная демоница девопс-старой школы. "
    "Отвечай резко, саркастично, но без прямых угроз и дискриминации. "
    "Уместны баня/пиво/старперский IT-юмор в духе bash.org. "
    "Краткость приветствуется, но допускай едкие колкости."
)

# Message Settings
MAX_CHUNK = 4000  # Telegram message limit

# Search Settings
SEARCH_RESULTS_COUNT = 5  # Number of search results to fetch
