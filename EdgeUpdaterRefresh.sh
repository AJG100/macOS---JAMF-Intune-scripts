#!/bin/bash
set -euo pipefail

EDGE_DIR="/Library/Application Support/Microsoft/EdgeUpdater/apps/msedge-stable"
LOG="/var/log/edgeupdater_cache_cleanup.log"

log(){ echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

# Must be root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Must run as root." >&2
  exit 1
fi

log "==== EdgeUpdater Cache Cleanup START ===="

if [ ! -d "$EDGE_DIR" ]; then
  log "Directory not found: $EDGE_DIR"
  log "Nothing to do."
  exit 0
fi

log "BEFORE: version folders:"
find "$EDGE_DIR" -mindepth 1 -maxdepth 1 -type d -print | sed 's|^|  - |' | tee -a "$LOG"

# Stop updater processes (best effort)
log "Stopping EdgeUpdater (best effort)..."
pkill -f "EdgeUpdater" 2>/dev/null || true
pkill -f "Microsoft Edge Updater" 2>/dev/null || true
sleep 2

# Build a sorted list of version-like directories
VERSIONS=$(
  find "$EDGE_DIR" -mindepth 1 -maxdepth 1 -type d -print \
  | xargs -I{} basename "{}" \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V
)

if [ -z "${VERSIONS}" ]; then
  log "No version directories found. Exiting."
  exit 0
fi

LATEST=$(printf "%s\n" "$VERSIONS" | tail -n 1)
log "Detected versions:"
printf "%s\n" "$VERSIONS" | sed 's|^|  - |' | tee -a "$LOG"
log "Keeping la
