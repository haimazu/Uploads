#!/bin/bash

#### Restart Slingshot Failed Sessions

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Script Identifier
SCRIPT_NAME="[MONITOR-SLINGSHOT]"

send_telegram_message "🟢 <b>TMUX Monitor Started</b> - Monitoring for patterns."

while true; do
    if ! tmux list-sessions &>/dev/null; then
        send_telegram_message "⚠️ <b>Warning</b>: No tmux sessions found."
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
                session_output=$(tmux capture-pane -pt "$session" -S -10)
                matching_line=$(echo "$session_output" | grep -E -m 1 "$(IFS="|"; echo "${PATTERNS[*]}")")

                if [[ -n "$matching_line" ]]; then
                    # Send Telegram notification
                    send_telegram_message "🚨 <b>Alert</b>: Pattern detected in session <code>$session</code> -> <i>$matching_line</i>"

                    # Clear the console
                    tmux send-keys -t "$session" "clear" C-m

                    # Execute the command
                    send_telegram_message "⚡ <b>Executing</b>: <code>python3 main.py $session --env prod</code>"
                    tmux send-keys -t "$session" "python3 main.py $session --env prod" C-m

                    # Clear history to remove matching line
                    tmux clear-history -t "$session"

                    send_telegram_message "✅ <b>Execution Completed</b>: Session <code>$session</code> processed successfully."
                fi
            fi
        done
    fi

    send_telegram_message "⏳ <b>Next Check in 30 Minutes</b>..."
    sleep 1800
done