#!/bin/bash

DIALOG="/usr/local/bin/dialog"
INSTALL_EVENT="install_edge"

# Ensure SwiftDialog exists
if [ ! -x "$DIALOG" ]; then
  echo "SwiftDialog not installed"
  exit 0
fi

"$DIALOG" \
  --title "Microsoft Edge Update Required" \
  --message "A critical Microsoft Edge security update is required to address known vulnerabilities.\n\nClick Update Now to install immediately, or choose Later to defer." \
  --icon /Applications/Microsoft\ Edge.app \
  --button1text "Update Now" \
  --button2text "Later" \
  --timer 900 \
  --ontop \
  --moveable

RESULT=$?

echo "Dialog exit code: $RESULT"

if [ "$RESULT" -eq 0 ]; then
  echo "User chose Update Now – triggering Jamf policy"
  /usr/local/bin/jamf policy -event "$InstallEdge"
fi

exit 0
