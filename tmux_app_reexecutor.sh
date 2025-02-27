#!/bin/bash

#### Tmux Monitor & Command Executor

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
)

# Iterate through tmux sessions
for session in $(tmux list-sessions -F "#{session_name}"); do
    # Capture the last 10 lines from the session
    session_output=$(tmux capture-pane -pt "$session" -S -10)

    # Check for a match
    matching_line=$(echo "$session_output" | grep -E -m 1 "$(IFS="|"; echo "${PATTERNS[*]}")")

    if [[ -n "$matching_line" ]]; then
        echo "Pattern found in session: $session"
        echo "Matching line: $matching_line"

        # Clear the console
        tmux send-keys -t "$session" "clear" C-m

        # Execute the command
        echo "Executing command in session: $session"
        tmux send-keys -t "$session" "python3 main.py $session --env prod" C-m
        
        # Immediately clear the pane after execution to remove matching line
        sleep 1  # Give the command time to execute
        tmux clear-history -t "$session"
        
        echo "Command executed successfully in session: $session"
    fi
done

echo "Finished processing tmux sessions."
exit 0
