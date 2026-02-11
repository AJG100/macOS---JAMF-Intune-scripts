#!/bin/bash

PATHS=(
"/usr/local/bin/jamf"
"/usr/local/jamf"
"/Library/Application Support/JAMF"
"/Library/Application Support/JAMF/Jamf.app"
"/Library/LaunchDaemons/com.jamf.*"
"/Library/LaunchAgents/com.jamf.*"
"/Library/Preferences/com.jamfsoftware.*"
"/Library/Caches/com.jamfsoftware.*"
"/Library/Logs/JAMF"
"/Applications/Self Service.app"
"/private/var/db/receipts/com.jamfsoftware.*"
)

for path in "${PATHS[@]}"; do
  if ls $path >/dev/null 2>&1; then
    exit 1
  fi
done

exit 0
