#!/bin/bash

#### Tmux Core Sessions Monitor & Auto-Restart

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Server Identifier
SERVER_TYPE="OLD-SERVER"
# Script Identifier
SCRIPT_NAME="$SERVER_TYPE - [MONITOR-CORE] ->"

echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - TMUX CORE Monitor Started"
send_telegram_message "$SCRIPT_NAME" "🟢 <b>TMUX CORE Monitor Started</b>"

# Function to check and restart Tmux sessions
check_and_restart() {
    session_name=$1
    command=$2

    tmux has-session -t "$session_name" 2>/dev/null;
    status=$?

    # status = 0 => session exists
    if [[ $status -ne 0 ]] then # check if status == 1
        tmux new -d -s "$session_name" "$command"

        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Session Restarted: $session_name and now running."
        send_telegram_message "$SCRIPT_NAME" "✅ <b>Session Restarted: </b>: <code>$session_name</code> and now running."
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
