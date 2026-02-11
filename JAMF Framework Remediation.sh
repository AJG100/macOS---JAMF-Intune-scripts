#!/bin/bash

echo "Starting Jamf Framework full removal"

# Graceful removal if binary still exists
if command -v jamf >/dev/null 2>&1; then
  jamf removeFramework || true
fi

# Stop any remaining Jamf processes
pkill -f jamf || true

# Binaries
rm -rf /usr/local/bin/jamf
rm -rf /usr/local/jamf

# Application Support
rm -rf "/Library/Application Support/JAMF"

# Self Service
rm -rf "/Applications/Self Service.app"

# LaunchDaemons and LaunchAgents
rm -rf /Library/LaunchDaemons/com.jamf.*
rm -rf /Library/LaunchAgents/com.jamf.*

# Preferences
rm -rf /Library/Preferences/com.jamfsoftware.*

# Caches and Logs
rm -rf /Library/Caches/com.jamfsoftware.*
rm -rf /Library/Logs/JAMF

# Receipts
rm -rf /private/var/db/receipts/com.jamfsoftware.*

echo "Jamf Framework removal complete"
exit 0
