#!/bin/bash
# Uninstall CrowdStrike Falcon Sensor (macOS)
# Works with/without uninstall protection. Pass maintenance token in $4 when enabled.

set -euo pipefail

FALCON_APP="/Applications/Falcon.app"
FALCONCTL="$FALCON_APP/Contents/Resources/falconctl"
MAINT_TOKEN="${4:-}"   # Jamf parameter 4 (optional)
LOG_PREFIX="[Falcon-Uninstall]"

log(){ echo "$LOG_PREFIX $*"; }

# 0) Presence check
if [ ! -x "$FALCONCTL" ]; then
 log "Falconctl not found. Nothing to uninstall."
 # Optional cleanup of known leftovers:
 rm -rf "/Library/CS" "/Library/Logs/CrowdStrike" "$FALCON_APP" 2>/dev/null || true
 [ -x /usr/local/bin/jamf ] && /usr/local/bin/jamf recon >/dev/null 2>&1 || true
 exit 0
fi

# 1) Try uninstall without token first
log "Attempting Falcon uninstall (no token)…"
/usr/bin/sudo "$FALCONCTL" uninstall >/tmp/falcon_uninstall.log 2>&1 || UNINSTALL_RC=$? || true
UNINSTALL_RC="${UNINSTALL_RC:-0}"

if [ "$UNINSTALL_RC" -ne 0 ]; then
 # If uninstall protection is enabled, a maintenance token is required
 if grep -qi "maintenance token" /tmp/falcon_uninstall.log || grep -qi "not authorized" /tmp/falcon_uninstall.log; then
   if [ -n "$MAINT_TOKEN" ]; then
     log "Uninstall protection detected. Retrying with maintenance token…"
     /usr/bin/sudo "$FALCONCTL" uninstall --maintenance-token "$MAINT_TOKEN" >>/tmp/falcon_uninstall.log 2>&1 || UNINSTALL_RC=$? || true
     UNINSTALL_RC="${UNINSTALL_RC:-0}"
   else
     log "Uninstall protection is enabled and no maintenance token was provided."
     log "Re-run policy with Parameter 4 set to the Falcon maintenance token."
     exit 2
   fi
 fi
fi

if [ "$UNINSTALL_RC" -ne 0 ]; then
 log "Falcon uninstall failed (rc=$UNINSTALL_RC). See /tmp/falcon_uninstall.log"
 exit "$UNINSTALL_RC"
fi

log "Falcon uninstall reported success."

# 2) Best-effort cleanup of leftovers (safe if already removed)
rm -rf "$FALCON_APP" 2>/dev/null || true
rm -rf "/Library/CS" 2>/dev/null || true
rm -rf "/Library/Logs/CrowdStrike" 2>/dev/null || true
# Old receipts (harmless if absent)
pkgutil --forget com.crowdstrike.falcon.Agent >/dev/null 2>&1 || true
pkgutil --forget com.crowdstrike.falcon.sensor >/dev/null 2>&1 || true

# 3) Verify removal
if [ -x "$FALCONCTL" ] || pgrep -f "[Ff]alcon" >/dev/null 2>&1; then
 log "Warning: Falcon components still detected. A reboot may be required."
else
 log "Falcon components no longer detected."
fi

# 4) Update Jamf inventory
if [ -x /usr/local/bin/jamf ]; then
 /usr/local/bin/jamf recon >/dev/null 2>&1 || true
fi

log "Done."
exit 0