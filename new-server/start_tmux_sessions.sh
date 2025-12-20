#!/bin/bash

#### Start Tmux Sessions On Startup

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Server Identifier
SERVER_TYPE="NEW-SERVER"
# Script Identifier
SCRIPT_NAME="$SERVER_TYPE - [STARTUP] -> "

echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Initializing Tmux sessions..."
send_telegram_message "$SCRIPT_NAME" "🟢 <b>Initializing Tmux sessions...</b>"

# Check if any tmux server is running and kill it
if tmux list-sessions >/dev/null 2>&1; then
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
# Use ';' instead of '&&' so the session stays up even if the service exits/crashes
declare -A SESSIONS=(
    ["API"]="cd ~/slingshot/API_Service; gunicorn -w 2 -b :8005 app:app; exec bash"
    ["crawler"]="cd ~/slingspider; scrapyd; exec bash"
    ["proxy"]="cd ~/slingshot; proxy-manager; exec bash"
    ["cleaner"]="~/mikos/cleanup_tmp_folders.sh"
    ["monitor"]="~/mikos/monitor_slingshot_sessions.sh"
)

for session in "${!SESSIONS[@]}"; do
    tmux new -d -s "$session" "${SESSIONS[$session]}"
    echo "Started Tmux session: $session"
done

# Start Slingshot Tmux Sessions using create_tmux_sessions.sh
NUM_SLINGSHOT_SESSIONS=10
bash "$HOME/mikos/create_tmux_sessions.sh" "$NUM_SLINGSHOT_SESSIONS"

# Wait a moment for sessions to initialize
sleep 10

# Verify all expected core sessions exist and retry if missing
EXPECTED_CORE_SESSIONS=("API" "crawler" "proxy" "cleaner" "monitor")
MAX_RETRIES=3
RETRY_DELAY=5

for attempt in $(seq 1 $MAX_RETRIES); do
    MISSING_SESSIONS=()
    
    for session in "${EXPECTED_CORE_SESSIONS[@]}"; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            MISSING_SESSIONS+=("$session")
        fi
    done
    
    # If all sessions exist, we're done
    if [[ ${#MISSING_SESSIONS[@]} -eq 0 ]]; then
        break
    fi
    
    # If this is not the last attempt, retry creating missing sessions
    if [[ $attempt -lt $MAX_RETRIES ]]; then
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Attempt $attempt/$MAX_RETRIES: Retrying creation of missing sessions: ${MISSING_SESSIONS[*]}"
        for session in "${MISSING_SESSIONS[@]}"; do
            if [[ -n "${SESSIONS[$session]:-}" ]]; then
                tmux new -d -s "$session" "${SESSIONS[$session]}"
                echo "Retried creating session: $session"
            fi
        done
        sleep $RETRY_DELAY
    fi
done

# Send appropriate message based on final verification
if [[ ${#MISSING_SESSIONS[@]} -eq 0 ]]; then
    send_telegram_message "$SCRIPT_NAME" "🚀 <b>All Tmux sessions started successfully!</b> 🎯"
else
    send_telegram_message "$SCRIPT_NAME" "⚠️ <b>Warning:</b> Failed to start after $MAX_RETRIES attempts: <code>${MISSING_SESSIONS[*]}</code>"
fi
