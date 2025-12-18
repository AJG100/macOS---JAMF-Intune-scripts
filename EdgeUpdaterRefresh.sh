#!/bin/bash
set -e

EDGE_UPDATER_DIR="/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable"
log(){ echo "$(date '+%F %T') $*"; }

log "Starting EdgeUpdater cache remediation"

if [ ! -d "$EDGE_UPDATER_DIR" ]; then
  log "Directory not found, exiting"
  exit 0
fi

# Stop updater to avoid recreation
log "Stopping EdgeUpdater"
launchctl bootout system /Library/LaunchDaemons/com.microsoft.EdgeUpdater*.plist 2>/dev/null || true
pkill -f EdgeUpdater || true
sleep 5

# Identify latest directory by semantic version
LATEST_VERSION=$(ls -1 "$EDGE_UPDATER_DIR" | sort -V | tail -n 1)
log "Latest EdgeUpdater version on disk: $LATEST_VERSION"

for VERSION_PATH in "$EDGE_UPDATER_DIR"/*; do
  VERSION="$(basename "$VERSION_PATH")"
  if [ "$VERSION" != "$LATEST_VERSION" ]; then
    log "Removing stale EdgeUpdater version: $VERSION"
    rm -rf "$VERSION_PATH"
  else
    log "Keeping current version: $VERSION"
  fi
done

# Restart updater
log "Re-enabling EdgeUpdater"
launchctl bootstrap system /Library/LaunchDaemons/com.microsoft.EdgeUpdater*.plist 2>/dev/null || true

log "Cleanup complete"
exit 0
