#!/bin/bash

#### Cleans Up Temporary Folders

# Load Telegram Function
source "$HOME/mikos/telegram.sh"

# Server Identifier
SERVER_TYPE="NEW-SERVER"
# Script Identifier
SCRIPT_NAME="$SERVER_TYPE - [CLEANUP] -> "

echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Temporary Files Cleanup Started"
send_telegram_message "$SCRIPT_NAME" "🧹 <b>Temporary Files Cleanup Started</b> - Removing old `/tmp` folders."

while true; do
    # Find and delete all /tmp/nuclei* folders older than 2 hours
    nuclei_count=$(find /tmp/ -maxdepth 1 -type d -name 'nuclei*' -mmin +120 | wc -l)
    if [[ "$nuclei_count" -gt 0 ]]; then
        find /tmp/ -maxdepth 1 -type d -name 'nuclei*' -mmin +120 -exec rm -rf {} + 2>/dev/null
        deleted_nuclei=$nuclei_count
    else
        deleted_nuclei=0
    fi

    # Find and delete the /tmp/wpscan folder older than 2 hours
    wpscan_count=$(find /tmp/ -maxdepth 1 -type d -name 'wpscan' -mmin +120 | wc -l)
    if [[ "$wpscan_count" -gt 0 ]]; then
        find /tmp/ -maxdepth 1 -type d -name 'wpscan' -mmin +120 -exec rm -rf {} + 2>/dev/null
        deleted_wpscan=$wpscan_count
    else
        deleted_wpscan=0
    fi

    
    if [[ "$deleted_nuclei" -gt 0 || "$deleted_wpscan" -gt 0 ]]; then
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Cleanup Completed:\nDeleted $deleted_nuclei nuclei* folders.\nDeleted $deleted_wpscan wpscan folder."
        send_telegram_message "$SCRIPT_NAME" "✅ <b>Cleanup Completed</b>:  
        🗑️ Deleted <code>$deleted_nuclei</code> <b>nuclei*</b> folders.  
        🗑️ Deleted <code>$deleted_wpscan</code> <b>wpscan</b> folder."
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S,%3N') - Cleanup Skipped: No old temporary folders found."
        send_telegram_message "$SCRIPT_NAME" "ℹ️ <b>Cleanup Skipped</b>: No old temporary folders found."
    fi

    echo "Next cleanup in 12 hours..."
    send_telegram_message "$SCRIPT_NAME" "⏳ <b>Next cleanup in 12 hours</b>..."
    # Wait for 12 hours before running again
    sleep 43200
done