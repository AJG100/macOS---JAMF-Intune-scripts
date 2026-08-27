#!/bin/bash
# ============================================================
# Microsoft Edge Update Trigger
# macOS / Microsoft Intune
#
# Purpose:
#   Trigger Microsoft AutoUpdate and restart Microsoft Edge
#   so pending Edge updates can be applied.
#
# Version compliance is verified externally through Qualys.
# ============================================================
LOG_FILE="/Library/Logs/MicrosoftEdgeUpdate.log"
EDGE_APP="/Applications/Microsoft Edge.app"
MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}
# ------------------------------------------------------------
# Initialize logging
# ------------------------------------------------------------
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"
log "============================================================"
log "Microsoft Edge update process started"
# ------------------------------------------------------------
# Check Edge installation
# ------------------------------------------------------------
if [ ! -d "$EDGE_APP" ]; then
    log "Microsoft Edge is not installed."
    log "Nothing to do."
    log "============================================================"
    exit 0
fi
log "Microsoft Edge installation detected."
# ------------------------------------------------------------
# Get currently logged-in user
# ------------------------------------------------------------
CONSOLE_USER=$(stat -f "%Su" /dev/console)
if [ -z "$CONSOLE_USER" ] || \
   [ "$CONSOLE_USER" = "root" ] || \
   [ "$CONSOLE_USER" = "loginwindow" ]; then
    log "No interactive user detected."
else
    log "Logged-in user: $CONSOLE_USER"
fi
# ------------------------------------------------------------
# Get current Edge version for logging
# ------------------------------------------------------------
EDGE_VERSION=$(
    /usr/bin/defaults read \
    "$EDGE_APP/Contents/Info.plist" \
    CFBundleShortVersionString 2>/dev/null
)
log "Current Edge version: ${EDGE_VERSION:-Unknown}"
# ------------------------------------------------------------
# Check Microsoft AutoUpdate
# ------------------------------------------------------------
if [ ! -x "$MAU_PATH" ]; then
    log "ERROR: Microsoft AutoUpdate binary not found."
    log "Expected path:"
    log "$MAU_PATH"
    exit 1
fi
log "Microsoft AutoUpdate detected."
# ------------------------------------------------------------
# Trigger Microsoft AutoUpdate
# ------------------------------------------------------------
log "Triggering Microsoft AutoUpdate."
"$MAU_PATH" --install >> "$LOG_FILE" 2>&1
MAU_RESULT=$?
log "Microsoft AutoUpdate returned exit code: $MAU_RESULT"
# ------------------------------------------------------------
# Quit Microsoft Edge
# ------------------------------------------------------------
if pgrep -x "Microsoft Edge" >/dev/null 2>&1; then
    log "Microsoft Edge is running."
    log "Requesting graceful shutdown."
    if [ -n "$CONSOLE_USER" ] && \
       [ "$CONSOLE_USER" != "root" ] && \
       [ "$CONSOLE_USER" != "loginwindow" ]; then
        /usr/bin/su - "$CONSOLE_USER" -c \
        "/usr/bin/osascript -e 'tell application \"Microsoft Edge\" to quit'" \
        >/dev/null 2>&1
    fi
else
    log "Microsoft Edge is not currently running."
fi
# ------------------------------------------------------------
# Wait for Edge to close
# ------------------------------------------------------------
log "Waiting for Edge to terminate."
WAIT=0
while pgrep -f \
    "/Applications/Microsoft Edge.app/Contents/MacOS/" \
    >/dev/null 2>&1; do
    sleep 2
    WAIT=$((WAIT + 2))
    if [ "$WAIT" -ge 30 ]; then
        log "Edge did not terminate within 30 seconds."
        break
    fi
done
# ------------------------------------------------------------
# Force termination if necessary
# ------------------------------------------------------------
if pgrep -f \
    "/Applications/Microsoft Edge.app/Contents/MacOS/" \
    >/dev/null 2>&1; then
    log "Sending SIGTERM to remaining Edge processes."
    /usr/bin/pkill -TERM -f \
    "/Applications/Microsoft Edge.app/Contents/MacOS/" \
    >/dev/null 2>&1
    sleep 5
fi
if pgrep -f \
    "/Applications/Microsoft Edge.app/Contents/MacOS/" \
    >/dev/null 2>&1; then
    log "Edge still running."
    log "Using SIGKILL as final measure."
    /usr/bin/pkill -KILL -f \
    "/Applications/Microsoft Edge.app/Contents/MacOS/" \
    >/dev/null 2>&1
    sleep 3
fi
# ------------------------------------------------------------
# Verify Edge is closed
# ------------------------------------------------------------
if pgrep -f \
    "/Applications/Microsoft Edge.app/Contents/MacOS/" \
    >/dev/null 2>&1; then
    log "WARNING: Edge processes are still running."
else
    log "Microsoft Edge successfully terminated."
fi
# ------------------------------------------------------------
# Allow AutoUpdate time to finish while preventing Edge from
# being relaunched during that window
# ------------------------------------------------------------
log "Monitoring for 60 seconds while Microsoft AutoUpdate finishes."
MONITOR_ELAPSED=0
MONITOR_INTERVAL=2
MONITOR_DURATION=60
while [ "$MONITOR_ELAPSED" -lt "$MONITOR_DURATION" ]; do
    if pgrep -f "/Applications/Microsoft Edge.app/Contents/MacOS/" >/dev/null 2>&1; then
        log "Edge was relaunched during the update window. Terminating it again."
        /usr/bin/pkill -TERM -f "/Applications/Microsoft Edge.app/Contents/MacOS/" >/dev/null 2>&1
        sleep 1
        if pgrep -f "/Applications/Microsoft Edge.app/Contents/MacOS/" >/dev/null 2>&1; then
            /usr/bin/pkill -KILL -f "/Applications/Microsoft Edge.app/Contents/MacOS/" >/dev/null 2>&1
        fi
    fi
    sleep "$MONITOR_INTERVAL"
    MONITOR_ELAPSED=$((MONITOR_ELAPSED + MONITOR_INTERVAL))
done
log "Update window closed."
# ------------------------------------------------------------
# Final version check
# ------------------------------------------------------------
NEW_EDGE_VERSION=$(
    /usr/bin/defaults read \
    "$EDGE_APP/Contents/Info.plist" \
    CFBundleShortVersionString 2>/dev/null
)
log "Edge version after update process: ${NEW_EDGE_VERSION:-Unknown}"
log "Update process completed."
log "Qualys should be used to verify the resulting Edge version."
log "============================================================"
exit 0