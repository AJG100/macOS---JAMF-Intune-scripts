#!/bin/bash

###
#
# Script to remove Jamf Framework
# Safely removes Jamf framework, verifies removal, and optionally cleans leftovers.
# Run with: sudo bash remove_jamf_framework.sh
#
###
#
# Author: Nithyananda Mahadeva
# Updated: 16/01/2026
#
###

# This script is intended to remove the Jamf management framework.

# Variables

scriptname="JamfRemoveFramework"
logandmetadir="/Library/Logs/Microsoft/IntuneScripts/JamfRemoveFramework"
LOG_FILE="$logandmetadir/JamfRemoveFramework.log"

if [[ ! -d "$logandmetadir" ]]; then
	## Creating Metadirectory
	echo "$(date) | Creating [$logandmetadir] to store logs"
	mkdir -p "$logandmetadir"
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

require_root() {
  if [[ $(id -u) -ne 0 ]]; then
    echo "Please run as root: sudo bash $0" >&2
    exit 1
  fi
}

# Identify the location of the jamf binary
jamf_bin=$(which jamf)

if [[ -z "$jamf_bin" ]]; then
    if [[ -e "/usr/sbin/jamf" ]]; then
        jamf_bin="/usr/sbin/jamf"
    elif [[ -e "/usr/local/bin/jamf" ]]; then
        jamf_bin="/usr/local/bin/jamf"
    fi
fi

# Check for Jamf binary
jamf_present() {
  [[ -x "$jamf_bin" ]] && "$jamf_bin" version >/dev/null 2>&1
}

# Gracefully unload launchd items if present
unload_launchd() {
  # These names can vary by version; try a few common ones
  local daemons=(
    "/Library/LaunchDaemons/com.jamfsoftware.jamf.daemon.plist"
    "/Library/LaunchDaemons/com.jamf.management.daemon.plist"
    "/Library/LaunchDaemons/com.jamfsoftware.task.1.plist"
    "/Library/LaunchDaemons/com.jamf.imaging.daemon.plist"
  )
  local agents=(
    "/Library/LaunchAgents/com.jamfsoftware.jamf.agent.plist"
    "/Library/LaunchAgents/com.jamf.management.agent.plist"
  )
  for pl in "${daemons[@]}" "${agents[@]}"; do
    if [[ -f "$pl" ]]; then
      log "Unloading launchd item: $pl"
      launchctl bootout system "$pl" >/dev/null 2>&1 || true
      launchctl bootout gui/$(id -u 2>/dev/null) "$pl" >/dev/null 2>&1 || true
      launchctl unload "$pl" >/dev/null 2>&1 || true
    fi
  done
}

# Remove the framework using Jamf's own remover
remove_framework() {
  if jamf_present; then
    log "Jamf binary found. Running: jamf removeFramework"
    "$jamf_bin" removeFramework 2>&1 | tee -a "$LOG_FILE" || true
  else
    log "Jamf binary NOT found at $jamf_bin. Proceeding to manual cleanup."
  fi
}

# Clean typical leftovers (safe if not present)
cleanup_leftovers() {
  log "Cleaning likely leftovers…"
  local paths=(
    "/usr/local/jamf"
    "/Library/Application Support/JAMF"
    "/Library/Preferences/com.jamfsoftware.jamf.plist"
    "/Library/Preferences/com.jamfsoftware.jamfagent.plist"
    "/Library/Preferences/com.jamfsoftware.jamfdaemon.plist"
    "/Library/Preferences/com.jamf.management.jamfAAD.plist"
    "/Library/LaunchAgents/com.jamfsoftware.jamf.agent.plist"
    "/Library/LaunchAgents/com.jamf.management.agent.plist"
    "/Library/LaunchDaemons/com.jamfsoftware.jamf.daemon.plist"
    "/Library/LaunchDaemons/com.jamf.management.daemon.plist"
    "/Library/LaunchDaemons/com.jamfsoftware.task.1.plist"
    "/Library/LaunchDaemons/com.jamf.imaging.daemon.plist"
    "/private/etc/jamf"
    "/var/root/Library/Preferences/com.jamfsoftware.*"
    "/Library/Receipts/Jamf*"
    "/Library/Receipts/jamf*"
  )
  for p in "${paths[@]}"; do
    if compgen -G "$p" >/dev/null; then
      log "Removing: $p"
      rm -rf $p
    fi
  done
}

# Verify removal
verify() {
  local ok=true
  if command -v jamf >/dev/null 2>&1; then
    log "jamf still appears in PATH: $(command -v jamf)"
    ok=false
  fi
  if [[ -d "/Library/Application Support/JAMF" ]] || [[ -d "/usr/local/jamf" ]]; then
    log "Jamf directories still present."
    ok=false
  fi
  if $ok; then
    log "✅ Jamf framework removal appears successful."
    return 0
  else
    log "⚠️  Some Jamf artifacts still remain. A reboot may finish cleanup."
    return 1
  fi
}

# Optional: show MDM profile presence (informational)
check_mdm_profile() {
  if command -v profiles >/dev/null 2>&1; then
    local mdm_uuid
    mdm_uuid=$(profiles status -type enrollment 2>/dev/null | awk -F': ' '/Enrolled via DEP:|Enrolled via DEP/ {print $2}')
    log "MDM enrollment (DEP) status (if available): ${mdm_uuid:-Unknown}"
    log "Installed profiles:"
    profiles list -type configuration 2>/dev/null | tee -a "$LOG_FILE" || true
  fi
}

main() {
  require_root
  log "=== Jamf Framework Removal Started ==="
  log "Log file: $LOG_FILE"
  check_mdm_profile
  unload_launchd
  remove_framework
  cleanup_leftovers
  verify
  log "=== Completed ==="
}

main "$@"
