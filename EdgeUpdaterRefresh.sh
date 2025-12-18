#!/bin/bash

EDGE_UPDATER_DIR="/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable"

log(){ echo "$(date '+%F %T') $*"; }

if [ ! -d "$EDGE_UPDATER_DIR" ]; then
  log "EdgeUpdater directory not found. Nothing to clean."
  exit 0
fi

log "Scanning EdgeUpdater versions..."

# Get latest version directory (sorted properly)
LATEST_VERSION=$(ls -1 "$EDGE_UPDATER_DIR" | sort -V | tail -n 1)

log "Latest EdgeUpdater version: $LATEST_VERSION"

for VERSION in "$EDGE_UPDATER_DIR"/*; do
  BASENAME=$(basename "$VERSION")
  if [ "$BASENAME" != "$LATEST_VERSION" ]; then
    log "Removing old EdgeUpdater version: $BASENAME"
    rm -rf "$VERSION"
  fi
done

log "EdgeUpdater cleanup complete."
exit 0
