#!/bin/bash

#### Cleans Up Temporary Folders

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Script Identifier
SCRIPT_NAME="[CLEANUP]"

send_telegram_message "$SCRIPT_NAME" "🧹 <b>Temporary Files Cleanup Started</b> - Removing old `/tmp` folders."

while true; do
    # Find and delete all /tmp/nuclei* folders older than 2 hours
    deleted_nuclei=$(find /tmp/ -maxdepth 1 -type d -name 'nuclei*' -mmin +120 -exec rm -rf {} + 2>/dev/null | wc -l)
    # Find and delete the /tmp/wpscan folder older than 2 hours
    deleted_wpscan=$(find /tmp/ -maxdepth 1 -type d -name 'wpscan' -mmin +120 -exec rm -rf {} + 2>/dev/null | wc -l)

    send_telegram_message "$SCRIPT_NAME" "✅ <b>Cleanup Completed</b>:  
    🗑️ Deleted <code>$deleted_nuclei</code> <b>nuclei*</b> folders.  
    🗑️ Deleted <code>$deleted_wpscan</code> <b>wpscan</b> folder.  
    ⏳ <i>Next cleanup in 12 hours...</i>"

    # Wait for 12 hours before running again
    sleep 43200
done