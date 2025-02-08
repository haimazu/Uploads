#!/bin/bash

#### Pro-Level tmux Monitor & Command Executor 🚀

LOG_FILE="/var/log/tmux_monitor.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting tmux session monitor..."

# Check if there are any tmux sessions running
if ! tmux list-sessions &>/dev/null; then
    log_message "No tmux sessions found."
    exit 0
fi

# Define the patterns to monitor
PATTERNS=(
    "BAD DECRYPTION!"
    "THIS IS THE NEW SERVER :)"
    "Interrupted! Exiting gracefully!"
    "Visibility timeout changed successfully to 0 SECONDS"
    "Changed status of .* to IN_QUEUE."
    "sling@sling:~/slingshot\\$"
)

# Iterate through tmux sessions
for session in $(tmux list-sessions -F "#{session_name}"); do
    # Capture the last 100 lines from the session to avoid excessive output
    session_output=$(tmux capture-pane -pt "$session" -S -100)

    # Check if any pattern matches
    for pattern in "${PATTERNS[@]}"; do
        if echo "$session_output" | grep -E -q "$pattern"; then
            log_message "Pattern '$pattern' found in session: $session"

            # Clear the console
            tmux send-keys -t "$session" "clear" C-m

            # Execute the command
            log_message "Executing command in session: $session"
            tmux send-keys -t "$session" "python3 main.py $session --env prod" C-m
            log_message "Command executed successfully in session: $session"

            # Exit loop after first match
            break
        fi
    done
done

log_message "Finished processing tmux sessions."
