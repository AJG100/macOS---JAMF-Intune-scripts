#!/bin/bash
# Outlook repair script for Jamf → Intune migrations
# - For macOS 12+
# - Run as root (Intune / Jamf script)
# - Operates on the current console user
#
# Actions:
#   * Backs up Outlook data to Desktop
#   * Clears Outlook/Office identity + cache dirs
#   * Resets Microsoft AutoUpdate (MAU)
#   * Removes common Office identity keychain items
#   * Logs to /var/log/outlook_migration_fix.log

set -euo pipefail

LOG="/var/log/outlook_migration_fix.log"

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "$LOG"
}

# ----- 1. Detect logged-in user -----
CONSOLE_USER=$(/usr/bin/stat -f %Su /dev/console 2>/dev/null || echo "")
if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" ]]; then
  log "No non-root console user detected. Exiting."
  exit 0
fi

USER_HOME=$(dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
if [[ -z "${USER_HOME:-}" || ! -d "$USER_HOME" ]]; then
  USER_HOME="/Users/$CONSOLE_USER"
fi

log "Operating on user: $CONSOLE_USER (home: $USER_HOME)"

# ----- 2. Quit Outlook if running -----
log "Attempting to quit Outlook if running..."
osascript -e 'tell application "Microsoft Outlook" to quit' >/dev/null 2>&1 || true
pkill -f "Microsoft Outlook" >/dev/null 2>&1 || true

# ----- 3. Define key paths -----
GC_ROOT="$USER_HOME/Library/Group Containers/UBF8T346G9.Office"
OUTLOOK_GC="$GC_ROOT/Outlook"
OUTLOOK_CONTAINER="$USER_HOME/Library/Containers/com.microsoft.Outlook"
MAU_DIR="$USER_HOME/Library/Application Support/Microsoft/MAU2.0"

BACKUP_ROOT="$USER_HOME/Desktop/Outlook_Migration_Backup_$(date '+%Y%m%d_%H%M%S')"
mkdir -p "$BACKUP_ROOT"

log "Backup folder: $BACKUP_ROOT"

backup_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local name
    name=$(basename "$path")
    log "Backing up $path → $BACKUP_ROOT/$name"
    mv "$path" "$BACKUP_ROOT/$name"
  fi
}

# ----- 4. Backup existing Outlook / Office data -----
backup_path "$OUTLOOK_GC"
backup_path "$OUTLOOK_CONTAINER"

# Also back up entire Office group container (for safety)
if [[ -d "$GC_ROOT" ]]; then
  backup_path "$GC_ROOT"
fi

# Backup MAU data if present
backup_path "$MAU_DIR"

# ----- 5. Remove Outlook / Office identity caches -----
log "Removing Outlook / Office identity caches..."

# After backup, recreate base Office group container
rm -rf "$GC_ROOT" 2>/dev/null || true
mkdir -p "$GC_ROOT"

rm -rf "$OUTLOOK_CONTAINER" 2>/dev/null || true

# Common identity plist
IDENTITY_PLIST="$GC_ROOT/com.microsoft.Office365V2.plist"
rm -f "$IDENTITY_PLIST" 2>/dev/null || true

# ----- 6. Reset Microsoft AutoUpdate -----
log "Resetting Microsoft AutoUpdate (MAU)..."
rm -rf "$MAU_DIR" 2>/dev/null || true

# ----- 7. Clean up Office identity items in keychain -----
log "Removing common Office identity keychain items..."

KEYCHAIN_LABELS=(
  "Microsoft Office Identities Cache 3"
  "Microsoft Office Identities Cache 2"
  "Microsoft Office Identities Settings 3"
  "Microsoft Office Identities Settings 2"
)

for label in "${KEYCHAIN_LABELS[@]}"; do
  security delete-generic-password -l "$label" "$USER_HOME/Library/Keychains/login.keychain-db" 2>/dev/null || true
done

# Also try system default if needed (older macOS)
for label in "${KEYCHAIN_LABELS[@]}"; do
  security delete-generic-password -l "$label" 2>/dev/null || true
done

# ----- 8. (Optional) Log config profiles mentioning Microsoft / Outlook -----
log "Listing configuration profiles related to Microsoft/Outlook (for reference):"
profiles -P 2>/dev/null | egrep -i "microsoft|outlook|office|jamf" || true

log "Outlook reset completed for user $CONSOLE_USER."
log "User will need to reopen Outlook and sign in again; data will re-sync from server."

exit 0
