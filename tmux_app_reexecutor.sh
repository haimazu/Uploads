#!/bin/bash

#### Tmux Monitor & Command Executor 🚀

echo "Starting tmux session monitor..."

# Check if there are any tmux sessions running
if ! tmux list-sessions &>/dev/null; then
    echo "No tmux sessions found."
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
    session_output=$(tmux capture-pane -pt "$session" -S -10)

    # Check if any pattern matches
    for pattern in "${PATTERNS[@]}"; do
        if echo "$session_output" | grep -E -q "$pattern"; then
            echo "Pattern '$pattern' found in session: $session"

            # Clear the console
            tmux send-keys -t "$session" "clear" C-m

            # Execute the command
            echo "Executing command in session: $session"
            tmux send-keys -t "$session" "python3 main.py $session --env prod" C-m
            echo "Command executed successfully in session: $session"

            # Stop checking further patterns for this session, but continue with others
            break
        fi
    done
done

echo "Finished processing tmux sessions."
exit 0
