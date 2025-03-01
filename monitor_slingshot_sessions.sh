#!/bin/bash

#### Restart Slingshot Failed Sessions

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Server Identifier
SERVER_TYPE="OLD-SERVER"
# Script Identifier
SCRIPT_NAME="$SERVER_TYPE - [MONITOR-SLINGSHOT] ->"

echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - TMUX Slingshot Sessions Monitor Started - Monitoring for patterns..."
send_telegram_message "$SCRIPT_NAME" "🟢 <b>TMUX Slingshot Sessions Monitor Started</b> - Monitoring for patterns."

while true; do
    if ! tmux ls &>/dev/null; then
        echo "No tmux sessions found."
        send_telegram_message "$SCRIPT_NAME" "⚠️ <b>Warning</b>: No tmux sessions found."
    else
        PATTERNS=(
            "BAD DECRYPTION!"
            "THIS IS THE OLD SERVER :)"
            "Interrupted! Exiting gracefully!"
            "Visibility timeout changed successfully to 0 SECONDS"
            "Changed status of .* to IN_QUEUE."
        )

        for session in $(tmux ls -F "#{session_name}"); do
            if [[ $session == slingshot* ]]; then
                session_output=$(tmux capture-pane -pt "$session" -S -10)
                matching_line=$(echo "$session_output" | grep -E -m 1 "$(IFS="|"; echo "${PATTERNS[*]}")")

                if [[ -n "$matching_line" ]]; then
                    echo "Pattern detected in session: $session"
                    echo "Matching Line: $matching_line"
                    # Send Telegram notification
                    send_telegram_message "$SCRIPT_NAME" "🚨 <b>Alert</b>: Pattern detected in session <code>$session</code> -> <i>$matching_line</i>"

                    # Clear the console
                    tmux send-keys -t "$session clear" C-m

                    # Execute the command
                    echo "Executing: python3 main.py $session --env prod"
                    tmux send-keys -t "$session python3 main.py $session --env prod" C-m

                    # Clear history to remove matching line
                    tmux clear-history -t "$session"

                    echo "Execution Completed: Session $session processed successfully."
                    send_telegram_message "$SCRIPT_NAME" "✅ <b>Execution Completed</b>: Session <code>$session</code> processed successfully."
                fi
            fi
        done
    fi

    echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Next check in 30 minutes..."
    send_telegram_message "$SCRIPT_NAME" "⏳ <b>Next Check in 30 Minutes</b>..."
    # Wait for 30 minutes before running again
    sleep 1800
done
