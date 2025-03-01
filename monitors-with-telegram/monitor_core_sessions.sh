#!/bin/bash

#### Tmux Main Sessions Monitor & Auto-Restart

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Script Identifier
SCRIPT_NAME="[MONITOR-MAIN]"

# Function to check and restart Tmux sessions
check_and_restart() {
    session_name=$1
    command=$2

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        send_telegram_message "$SCRIPT_NAME" "⚠️ <b>Session Restarted</b>: <code>$session_name</code> was not running and has been restarted."

        tmux new -d -s "$session_name" "$command"

        send_telegram_message "$SCRIPT_NAME" "✅ <b>Session Restarted Successfully</b>: <code>$session_name</code> is now running."
    fi
}

# Core Tmux Sessions to Monitor
declare -A SESSIONS=(
    ["API"]="cd ~/slingshot/API_Service && gunicorn -w 2 -b :8005 app:app && exec bash"
    ["crawler"]="cd ~/slingspider && scrapyd && exec bash"
    ["proxy"]="cd ~/slingshot && proxy-manager && exec bash"
)

# Continuous Monitoring Loop
while true; do
    # Monitor Core Sessions
    for session in "${!SESSIONS[@]}"; do
        check_and_restart "$session" "${SESSIONS[$session]}"
    done

    sleep 10  # Check every 10 seconds
done
