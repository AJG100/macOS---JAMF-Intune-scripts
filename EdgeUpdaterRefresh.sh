#!/bin/bash

TARGET="/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable/142.0.3595.94"
LOG="/var/log/edgeupdater_cache_cleanup.log"
log(){ echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

if [ "$(id -u)" -ne 0 ]; then
  log "Must run as root."
  exit 0
fi

if [ -d "$TARGET" ]; then
  log "Removing vulnerable cached version: $TARGET"
  pkill -f "EdgeUpdater" 2>/dev/null || true
  chflags -R nouchg,noschg "$TARGET" 2>/dev/null || true
  xattr -cr "$TARGET" 2>/dev/null || true
  rm -rf "$TARGET"
  [ -d "$TARGET" ] && log "FAILED: still exists" || log "OK: removed"
else
  log "Target not present. Nothing to do."
fi

exit 0
