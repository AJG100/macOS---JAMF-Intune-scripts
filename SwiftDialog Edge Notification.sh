#!/bin/bash

DIALOG="/usr/local/bin/dialog"
JAMF="/usr/local/bin/jamf"
TRIGGER="install_edge"
LOG="/var/log/browser_update_prompt.log"

log(){ echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

"$DIALOG" \
  --title "Microsoft Edge Update Required" \
  --message "A critical Microsoft Edge security update is required.\n\nClick Update Now to install, or Later to defer." \
  --icon /Applications/Microsoft\ Edge.app \
  --button1text "Update Now" \
  --button2text "Later" \
  --timer 900 \
  --ontop

RESULT=$?
log "Dialog exit code: $RESULT"

if [ "$RESULT" -eq 0 ]; then
  log "Triggering Jamf policy: $Install_Edge"
  "$JAMF" policy -trigger "$Install_Edge" -verbose 2>&1 | tee -a "$LOG"
else
  log "User deferred or dialog closed. No trigger."
fi

exit 0
