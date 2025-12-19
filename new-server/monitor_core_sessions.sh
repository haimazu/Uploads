#!/bin/bash

#### Tmux Core Sessions Monitor & Auto-Restart

# Safer bash defaults (but allow some commands to fail in checks)
set -uo pipefail

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Server Identifier
SERVER_TYPE="NEW-SERVER"
# Script Identifier
SCRIPT_NAME="$SERVER_TYPE - [MONITOR-CORE] -> "

echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - TMUX CORE Monitor Started"
send_telegram_message "$SCRIPT_NAME" "🟢 <b>TMUX CORE Monitor Started</b>"

# Check if any core sessions exist
check_core_sessions_exist() {
    local core_sessions=("API" "crawler" "proxy")
    for session in "${core_sessions[@]}"; do
        if tmux has-session -t "$session" 2>/dev/null; then
            return 0  # At least one exists
        fi
    done
    return 1  # None exist
}

# Full startup sequence when no core sessions exist
full_startup_sequence() {
    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - No core sessions found. Running full startup sequence..."
    send_telegram_message "$SCRIPT_NAME" "🔄 <b>No core sessions found</b>. Running full startup sequence..."
    
    # Run start_tmux_sessions.sh
    bash "$HOME/start_tmux_sessions.sh"
    
    # Wait 5 seconds
    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Waiting 5 seconds..."
    sleep 5
    
    # Run create_tmux_sessions.sh with 20 sessions
    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Creating 20 slingshot sessions..."
    bash "$HOME/mikos/create_tmux_sessions.sh" 20
    
    # Wait 10 seconds
    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Waiting 10 seconds..."
    sleep 10
    
    # Run restart_tmuxes.sh until it only shows "Starting tmux session monitor..."
    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Running restart_tmuxes.sh until clean..."
    local max_attempts=50
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        local output=$(bash "$HOME/restart_tmuxes.sh" 2>&1)
        
        # Check if output contains pattern match indicators (means sessions still need restarting)
        # Clean output only has: "DD-MM-YYYY HH:MM:SS,mmm - Starting tmux session monitor..."
        # If patterns found, it will have additional lines like:
        # "Pattern found in session: ..."
        # "Matching line: ..."
        # "Executing command in session: ..."
        # "Command executed successfully in session: ..."
        if echo "$output" | grep -qE "(Pattern found in session|Matching line:|Executing command in session|Command executed successfully in session)"; then
            attempt=$((attempt + 1))
            echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Attempt $attempt/$max_attempts: Sessions still need restarting, retrying..."
            sleep 10
            continue
        fi
        
        # If we get here, no patterns were found - all sessions are clean
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - All sessions clean! Startup sequence complete."
        send_telegram_message "$SCRIPT_NAME" "✅ <b>Full startup sequence complete!</b> All sessions are clean."
        return 0
    done
    
    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Warning: Max attempts reached, still monitoring sessions"
    send_telegram_message "$SCRIPT_NAME" "⚠️ <b>Startup sequence completed</b> but max attempts reached, still monitoring sessions"
}

# Restart (or start) a session if missing OR if its expected process is not running OR if crash pattern found.
check_and_restart() {
    local session_name="$1"
    local command="$2"
    local process_pattern="$3"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new -d -s "$session_name" "$command"
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Session Started: $session_name"
        send_telegram_message "$SCRIPT_NAME" "✅ <b>Session Started</b>: <code>$session_name</code>"
        return 0
    fi

    # Check for crash patterns in session output (same patterns as restart_tmuxes.sh)
    local crash_patterns=(
        "THIS IS THE NEW SERVER :)"
        "ProxyConnectionError"
        "Failed to connect to proxy URL"
    )
    local session_output=$(tmux capture-pane -pt "$session_name" -S -10 2>/dev/null)
    local matching_line=$(echo "$session_output" | grep -E -m 1 "$(IFS="|"; echo "${crash_patterns[*]}")")
    
    if [[ -n "$matching_line" ]]; then
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Crash pattern found in session: $session_name (pattern: $matching_line)"
        tmux kill-session -t "$session_name" 2>/dev/null || true
        tmux new -d -s "$session_name" "$command"
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Session Restarted (crash pattern detected): $session_name"
        send_telegram_message "$SCRIPT_NAME" "♻️ <b>Session Restarted</b> (crash pattern): <code>$session_name</code>"
        return 0
    fi

    # Session exists; verify the underlying service is actually running.
    if ! pgrep -f -- "$process_pattern" >/dev/null 2>&1; then
        tmux kill-session -t "$session_name" 2>/dev/null || true
        tmux new -d -s "$session_name" "$command"
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Session Restarted (process down): $session_name"
        send_telegram_message "$SCRIPT_NAME" "♻️ <b>Session Restarted</b> (process down): <code>$session_name</code>"
    fi
}

# Core Tmux Sessions to Monitor
declare -A SESSIONS=(
    # Use ';' instead of '&&' so the session stays up even if the service exits/crashes.
    ["API"]="cd ~/slingshot/API_Service; gunicorn -w 2 -b :8005 app:app; exec bash"
    ["crawler"]="cd ~/slingspider; scrapyd; exec bash"
    ["proxy"]="cd ~/slingshot; proxy-manager; exec bash"
)

# Expected process patterns per session (used for liveness checks)
# These patterns match what pgrep -f will find in the process command line
declare -A PROCESSES=(
    ["API"]="gunicorn.*-b :8005.*app:app"
    ["crawler"]="scrapyd"
    ["proxy"]="proxy-manager"
)

# Continuous Monitoring Loop
while true; do
    # Check if core sessions exist
    if ! check_core_sessions_exist; then
        # No core sessions exist - run full startup sequence
        full_startup_sequence
    else
        # Core sessions exist - monitor and restart individually
        for session in "${!SESSIONS[@]}"; do
            check_and_restart "$session" "${SESSIONS[$session]}" "${PROCESSES[$session]}"
        done
    fi

    # Check every 30 minutes
    sleep 1800
done
