#!/bin/bash
# ---------------------------------------------------
# Remove Microsoft Company Portal + related data
# Compatible with macOS 12–15
# ---------------------------------------------------

APP_PATH="/Applications/Company Portal.app"
SUPPORT_PATH="/Library/Application Support/Microsoft/Intune"

echo "Starting Company Portal uninstall..."

# Quit the app if running
pkill -f "Company Portal" 2>/dev/null || true

# Remove application bundle
if [ -d "$APP_PATH" ]; then
   echo "Removing $APP_PATH..."
   rm -rf "$APP_PATH"
else
   echo "Company Portal not found in /Applications"
fi

# Remove supporting files
if [ -d "$SUPPORT_PATH" ]; then
   echo "Removing Intune support files..."
   rm -rf "$SUPPORT_PATH"
fi

# Remove user-level caches and preferences
for USER_HOME in /Users/*; do
   if [ -d "$USER_HOME/Library/Application Support/com.microsoft.CompanyPortal" ]; then
       echo "Removing Company Portal data from $USER_HOME..."
       rm -rf "$USER_HOME/Library/Application Support/com.microsoft.CompanyPortal"
   fi
   rm -f "$USER_HOME/Library/Preferences/com.microsoft.CompanyPortal.plist"
done

# Remove logs and receipts
rm -rf /Library/Logs/Microsoft/Intune*
pkgutil --forget com.microsoft.CompanyPortal || true

echo "Microsoft Company Portal has been removed."
exit 0