#!/bin/bash

DIALOG="/usr/local/bin/dialog"

"$DIALOG" \
  --title "Microsoft Edge Update Required" \
  --message "A critical Microsoft Edge update is required.\n\nClick Update Now to install, or Later to defer." \
  --icon /Applications/Microsoft\ Edge.app \
  --button1text "Update Now" \
  --button1action "/usr/local/bin/jamf policy -trigger Install_Edge" \
  --button2text "Later" \
  --timer 900 \
  --ontop \
  --moveable

exit 0
