#!/bin/bash

# Load environment variables for Telegram API
if [[ -z "$TELEGRAM_API_KEY" || -z "$TELEGRAM_CHAT_ID" ]]; then
    echo "❌ TELEGRAM_API_KEY or TELEGRAM_CHAT_ID not set!"
    exit 1
fi

# Function to send a Telegram message using curl
send_telegram_message() {
    local script_name="$1"
    local message="$2"
    local url="https://api.telegram.org/bot$TELEGRAM_API_KEY/sendMessage"
    
    curl -s -X POST "$url" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=<b>$script_name</b> $message" \
        -d "parse_mode=HTML" \
        -d "disable_notification=true" > /dev/null
}
