#!/bin/bash

# Not Your Mama Bot Deployment Script
set -e

echo "🤖 Not Your Mama Bot - Deployment Script"
echo "========================================"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip first."
    exit 1
fi

echo "✅ Python and pip found"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Check environment variables
echo "🔍 Checking environment variables..."
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "⚠️  TELEGRAM_BOT_TOKEN not set. Please set it:"
    echo "   export TELEGRAM_BOT_TOKEN='your_token_here'"
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  OPENAI_API_KEY not set. Please set it:"
    echo "   export OPENAI_API_KEY='your_key_here'"
fi

if [ -z "$BOT_USERNAME" ]; then
    echo "⚠️  BOT_USERNAME not set. Please set it:"
    echo "   export BOT_USERNAME='your_bot_username'"
fi

# Check if all required env vars are set
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$OPENAI_API_KEY" ] || [ -z "$BOT_USERNAME" ]; then
    echo ""
    echo "❌ Missing required environment variables."
    echo "Please set all required variables and run this script again."
    echo ""
    echo "You can also copy env.example to .env and edit it:"
    echo "   cp env.example .env"
    echo "   # Edit .env with your values"
    echo "   source .env"
    exit 1
fi

echo "✅ All environment variables are set"

# Run the bot
echo "🚀 Starting the bot..."
echo "Press Ctrl+C to stop"
python bot.py
