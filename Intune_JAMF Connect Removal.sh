#!/bin/bash
# Remove Jamf Connect (Intune macOS script)
# - Stops processes
# - Unloads launch agents/daemons (best effort)
# - Removes app + common leftovers
# - Forgets pkg receipts (best effort)
# - Writes log to /var/log/jamfconnect_removal.log

set -u

DRY_RUN=false   # set to true for pilot (no deletes)
LOG="/var/log/jamfconnect_removal.log"

exec >> "$LOG" 2>&1
echo "============================================================"
echo "$(date) | Jamf Connect removal START | DRY_RUN=$DRY_RUN"
echo "============================================================"

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY_RUN: $*"
    return 0
  fi
  eval "$@"
}

kill_if_running() {
  local proc="$1"
  if pgrep -x "$proc" >/dev/null 2>&1; then
    echo "$(date) | Stopping process: $proc"
    run_cmd "pkill -x \"$proc\" || true"
    sleep 1
  fi
}

remove_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "$(date) | Removing: $path"
    run_cmd "rm -rf \"$path\" || true"
  fi
}

bootout_if_exists() {
  local plist="$1"
  if [[ -f "$plist" ]]; then
    echo "$(date) | Unloading: $plist"
    # On modern macOS, bootout is preferred. Fallback to unload.
    run_cmd "/bin/launchctl bootout system \"$plist\" 2>/dev/null || /bin/launchctl unload \"$plist\" 2>/dev/null || true"
    run_cmd "rm -f \"$plist\" || true"
  fi
}

echo "$(date) | 1) Closing Jamf Connect components..."
kill_if_running "Jamf Connect"
kill_if_running "JamfConnect"
kill_if_running "JamfConnectLogin"
kill_if_running "JamfConnectSync"
kill_if_running "JamfConnectVerifier"
kill_if_running "JamfConnectLaunchAgent"
kill_if_running "JamfConnectDaemon"

echo "$(date) | 2) Unloading common LaunchAgents/Daemons..."
# Names vary by version/org; these are common
for plist in \
  "/Library/LaunchAgents/com.jamf.connect.plist" \
  "/Library/LaunchAgents/com.jamf.connect.sync.plist" \
  "/Library/LaunchAgents/com.jamf.connect.verify.plist" \
  "/Library/LaunchAgents/com.jamfconnect.plist" \
  "/Library/LaunchDaemons/com.jamf.connect.daemon.plist" \
  "/Library/LaunchDaemons/com.jamf.connect.sync.daemon.plist" \
  "/Library/LaunchDaemons/com.jamf.connect.verify.daemon.plist"
do
  bootout_if_exists "$plist"
done

echo "$(date) | 3) Removing applications..."
remove_if_exists "/Applications/Jamf Connect.app"
remove_if_exists "/Applications/JamfConnect.app"

echo "$(date) | 4) Removing common support files..."
remove_if_exists "/Library/Application Support/JamfConnect"
remove_if_exists "/Library/Application Support/Jamf Connect"
remove_if_exists "/Library/Preferences/com.jamf.connect.plist"
remove_if_exists "/Library/Preferences/com.jamfconnect.plist"
remove_if_exists "/Library/Logs/JamfConnect"
remove_if_exists "/Library/Logs/Jamf Connect"

# Some orgs have a privileged helper tool (names can vary)
remove_if_exists "/Library/PrivilegedHelperTools/com.jamf.connect.helper"
remove_if_exists "/Library/LaunchDaemons/com.jamf.connect.helper.plist"

echo "$(date) | 5) Forgetting pkg receipts (best effort)..."
# Receipt IDs vary; we search for common patterns
PKGS=$(pkgutil --pkgs 2>/dev/null | grep -Ei "jamf.*connect|com\.jamf\.connect|jamfconnect" || true)
if [[ -n "${PKGS:-}" ]]; then
  while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    echo "$(date) | Forgetting receipt: $pkg"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "DRY_RUN: pkgutil --forget \"$pkg\""
    else
      pkgutil --forget "$pkg" || true
    fi
  done <<< "$PKGS"
else
  echo "$(date) | No Jamf Connect receipts found."
fi

echo "$(date) | 6) Verification summary..."
if [[ -d "/Applications/Jamf Connect.app" || -d "/Applications/JamfConnect.app" ]]; then
  echo "$(date) | WARNING: Jamf Connect app still present."
else
  echo "$(date) | OK: Jamf Connect app not present."
fi

echo "$(date) | Jamf Connect removal END"
exit 0
