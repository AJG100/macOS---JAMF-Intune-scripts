#!/bin/bash
set -euo pipefail

EDGE_DIR="/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable"
LOG="/var/log/edgeupdater_cache_cleanup.log"

log(){ echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

# 1) Must be root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Must run as root." >&2
  exit 1
fi

log "==== EdgeUpdater Cache Cleanup START ===="

# 2) Validate directory exists
if [ ! -d "$EDGE_DIR" ]; then
  log "EdgeUpdater directory not found: $EDGE_DIR"
  log "Nothing to do."
  exit 0
fi

# 3) Show BEFORE state (only directories at depth 1)
log "BEFORE: version folders in msedge-stable:"
find "$EDGE_DIR" -mindepth 1 -maxdepth 1 -type d -print | sed "s|^|  - |" | tee -a "$LOG"

# 4) Stop EdgeUpdater to avoid immediate recreation while cleaning
log "Stopping EdgeUpdater processes (best effort)..."
pkill -f "EdgeUpdater" 2>/dev/null || true
pkill -f "Microsoft Edge Updater" 2>/dev/null || true
sleep 2

# 5) Identify version directories (only those that look like versions)
#    Example: 142.0.3595.94
mapfile -t VERSIONS < <(find "$EDGE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 \
  | xargs -0 -n1 basename \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V)

if [ "${#VERSIONS[@]}" -eq 0 ]; then
  log "No version directories found (nothing to clean)."
  exit 0
fi

LATEST="${VERSIONS[-1]}"
log "Detected versions: ${VERSIONS[*]}"
log "Keeping latest version: $LATEST"

# 6) Delete all versions except latest
for v in "${VERSIONS[@]}"; do
  if [ "$v" = "$LATEST" ]; then
    log "KEEP: $v"
    continue
  fi

  TARGET="$EDGE_DIR/$v"
  log "REMOVE: $v ($TARGET)"

  # Remove immutable flags / xattrs if present (best effort)
  chflags -R nouchg,noschg "$TARGET" 2>/dev/null || true
  xattr -cr "$TARGET" 2>/dev/null || true

  # Delete
  rm -rf "$TARGET"

  # Verify deletion
  if [ -e "$TARGET" ]; then
    log "WARNING: Failed to remove $TARGET (still exists)"
  else
    log "OK: removed $v"
  fi
done

# 7) Show AFTER state
log "AFTER: version folders in msedge-stable:"
find "$EDGE_DIR" -mindepth 1 -maxdepth 1 -type d -print | sed "s|^|  - |" | tee -a "$LOG"

# 8) Optional: restart EdgeUpdater will happen naturally; we won't force it here
log "==== EdgeUpdater Cache Cleanup END ===="
exit 0
