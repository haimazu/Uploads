#!/bin/bash

#### Start Tmux Sessions On Startup

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Server Identifier
SERVER_TYPE="OLD-SERVER"
# Script Identifier
SCRIPT_NAME="$SERVER_TYPE - [STARTUP] -> "

echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Initializing Tmux sessions..."
send_telegram_message "$SCRIPT_NAME" "🟢 <b>Initializing Tmux sessions...</b>"

# Check if any tmux server is running and kill it
if tmux ls >/dev/null 2>&1; then
    tmux kill-server
    echo "Killed Tmux server."
fi

# Ensure ports 8005, 6800, and 24001 are free
PORTS=(8005 6800 24001)
for PORT in "${PORTS[@]}"; do
    if lsof -ti :$PORT >/dev/null 2>&1; then
        lsof -ti :$PORT | xargs kill -9 2>/dev/null
    fi
done

# Start Core Tmux Sessions (API, Crawler, Proxy)
declare -A SESSIONS=(
    ["API"]="cd ~/slingshot/API_Service && gunicorn -w 2 -b :8005 app:app && exec bash"
    ["crawler"]="cd ~/slingspider && scrapyd && exec bash"
    ["proxy"]="cd ~/slingshot && proxy-manager && exec bash"
)

for session in "${!SESSIONS[@]}"; do
    tmux new -d -s "$session" "${SESSIONS[$session]}"
    echo "Started Tmux session: $session"
done

# Start Slingshot Tmux Sessions using create_tmux_sessions.sh
NUM_SLINGSHOT_SESSIONS=10
bash "$HOME/mikos/create_tmux_sessions.sh" "$NUM_SLINGSHOT_SESSIONS"

send_telegram_message "$SCRIPT_NAME" "🚀 <b>All Tmux sessions started successfully!</b> 🎯"