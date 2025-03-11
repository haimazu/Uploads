#!/bin/bash

#### Restart Slingshot Failed Sessions

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Server Identifier
SERVER_TYPE="OLD-SERVER"
# Script Identifier
SCRIPT_NAME="$SERVER_TYPE - [MONITOR-SLINGSHOT] -> "

echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - TMUX Slingshot Sessions Monitor Started - Monitoring for patterns..."

while true; do
    if ! tmux list-sessions &>/dev/null; then
        echo "No tmux sessions found."
    else
        PATTERNS=(
            "BAD DECRYPTION!"
            "THIS IS THE OLD SERVER :)"
            "Interrupted! Exiting gracefully!"
            "Visibility timeout changed successfully to 0 SECONDS"
            "Changed status of .* to IN_QUEUE."
        )

        for session in $(tmux list-sessions -F "#{session_name}"); do
            if [[ $session == slingshot* ]]; then
                # Capture the last 10 lines from the session
                session_output=$(tmux capture-pane -pt "$session" -S -10)

                # Check for a match
                matching_line=$(echo "$session_output" | grep -E -m 1 "$(IFS="|"; echo "${PATTERNS[*]}")")

                if [[ -n "$matching_line" ]]; then
                    echo "Pattern found in session: $session"
                    
                    # Execute fix immediately
                    tmux send-keys -t "$session" "clear" C-m
                    tmux send-keys -t "$session" "python3 main.py $session --env prod" C-m
                    tmux clear-history -t "$session"

                    echo "Command executed successfully in session: $session"
                    
                    # Telegram Alert AFTER execution (prevents delays)
                    send_telegram_message "$SCRIPT_NAME" "✅ <b>Fixed</b>: Session <code>$session</code> restarted successfully."
                fi
            fi
        done
    fi

    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Finished processing tmux sessions. Next check in 30 minutes."
    send_telegram_message "$SCRIPT_NAME" "Finished processing tmux sessions.<br>⏳ <b>Next check in 30 minutes</b>..."
    sleep 1800
done
