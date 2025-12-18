#!/bin/bash

EDGE_DIR="/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable"
LOG="/var/log/edgeupdater_cache_cleanup.log"

log(){ echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

# Must be root
if [ "$(id -u)" -ne 0 ]; then
  log "ERROR: Must run as root."
  exit 0
fi

log "==== EdgeUpdater Cache Cleanup START ===="

if [ ! -d "$EDGE_DIR" ]; then
  log "Directory not found: $EDGE_DIR"
  log "Nothing to do."
  exit 0
fi

log "BEFORE (contents):"
ls -la "$EDGE_DIR" 2>&1 | tee -a "$LOG"

# Stop updater processes (best effort, don't fail script if not found)
log "Stopping EdgeUpdater processes (best effort)..."
pkill -f "EdgeUpdater" 2>/dev/null || true
pkill -f "Microsoft Edge Updater" 2>/dev/null || true
sleep 2

# Build list of version directories (only those that look like 1.2.3.4)
VERSIONS=$(find "$EDGE_DIR" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null \
  | sed 's|.*/||' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' 2>/dev/null \
  | sort -V)

if [ -z "$VERSIONS" ]; then
  log "No version directories found under $EDGE_DIR. Exiting."
  exit 0
fi

LATEST=$(printf "%s\n" "$VERSIONS" | tail -n 1)
log "Detected versions:"
printf "%s\n" "$VERSIONS" | sed 's|^|  - |' | tee -a "$LOG"
log "Keeping latest: $LATEST"

DELETED_ANY="no"

printf "%s\n" "$VERSIONS" | while IFS= read -r v; do
  [ -z "$v" ] && continue

  if [ "$v" = "$LATEST" ]; then
    log "KEEP: $v"
    continue
  fi

  TARGET="$EDGE_DIR/$v"
  log "REMOVE: $TARGET"

  # Show flags/ACL/xattrs (helps explain why rm fails)
  ls -leO@ "$TARGET" 2>&1 | tee -a "$LOG"

  # Try to clear immutable flags + xattrs (best effort)
  chflags -R nouchg,noschg "$TARGET" 2>&1 | tee -a "$LOG" || true
  xattr -cr "$TARGET" 2>&1 | tee -a "$LOG" || true

  # Remove with verbose output so we SEE what happens
  rm -rfv "$TARGET" 2>&1 | tee -a "$LOG"
  RC=$?

  if [ $RC -eq 0 ] && [ ! -e "$TARGET" ]; then
    log "OK: removed $v"
    DELETED_ANY="yes"
  else
    log "FAILED: rm exit code=$RC and/or target still exists: $TARGET"
  fi
done

log "AFTER (contents):"
ls -la "$EDGE_DIR" 2>&1 | tee -a "$LOG"

log "==== EdgeUpdater Cache Cleanup END ===="
exit 0
