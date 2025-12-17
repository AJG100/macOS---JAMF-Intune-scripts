#!/bin/bash

DIALOG="/usr/local/bin/dialog"

if [ ! -x "$DIALOG" ]; then
  echo "SwiftDialog not installed"
  exit 0
fi

"$DIALOG" \
  --title "Security Update Required" \
  --message "A critical security update for your browser is required to address known vulnerabilities.\n\nThe update will install automatically and may briefly close your browser.\n\nPlease save your work." \
  --icon SF=exclamationmark.shield.fill \
  --button1text "Update Now" \
  --button2text "Later" \
  --timer 900 \
  --moveable \
  --ontop

RESULT=$?

# Button 0 = Update Now
# Button 2 or timer = Later
exit 0
