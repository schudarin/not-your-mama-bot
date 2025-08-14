# Not Your Mama Bot

A sarcastic, rude Telegram bot with a "devops old-school" personality that responds to mentions, performs web searches, and generates AI-powered responses.

## Features

- **Sarcastic Personality**: Responds with rude, sarcastic comments in the style of an old-school devops engineer
- **Web Search**: Performs internet searches using DuckDuckGo when triggered by keywords like "гугли", "найди", "поиск"
- **Customizable Style**: Change the bot's personality per chat using `/style` command
- **Smart Triggers**: Responds to mentions, "мразь" keyword, or direct replies
- **AI-Powered**: Uses OpenAI GPT-4o-mini for intelligent responses and search summaries

## Commands

- `/start` - Get bot information and usage instructions
- `/style <text>` - Change bot's personality for the current chat
- `/ping` - Simple ping command for testing

## Setup

### Prerequisites

- Python 3.8+
- Telegram Bot Token (from [@BotFather](https://t.me/botfather))
- OpenAI API Key

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd not-your-mama-bot
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set environment variables:
```bash
export TELEGRAM_BOT_TOKEN="your_telegram_bot_token"
export OPENAI_API_KEY="your_openai_api_key"
export BOT_USERNAME="your_bot_username"
```

4. Run the bot:
```bash
python bot.py
```

## Environment Variables

- `TELEGRAM_BOT_TOKEN` - Your Telegram bot token from BotFather
- `OPENAI_API_KEY` - Your OpenAI API key
- `BOT_USERNAME` - Your bot's username (without @)

## Usage

### In Groups
- Mention the bot with `@username`
- Use the word "мразь" in your message
- Reply to the bot's messages

### Web Search
Trigger web search by using keywords like:
- "гугли [query]"
- "найди [query]"
- "поиск [query]"
- "в интернете [query]"

### Customizing Personality
Use `/style` command to change the bot's personality for the current chat:
```
/style Ты — вежливый и дружелюбный помощник
```

## Technical Details

- **Framework**: python-telegram-bot
- **Search Engine**: DuckDuckGo
- **AI Model**: OpenAI GPT-4o-mini
- **Message Limit**: 4000 characters per message (Telegram limit)

## License

This project is open source. Feel free to modify and distribute.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Disclaimer

This bot is designed to be sarcastic and rude for entertainment purposes. Use responsibly and ensure it complies with Telegram's terms of service and your local regulations.
