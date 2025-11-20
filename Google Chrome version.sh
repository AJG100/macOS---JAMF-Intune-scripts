#!/bin/bash
# EA: Google Chrome - Version

APP="/Applications/Google Chrome.app"
INFO_PLIST="$APP/Contents/Info.plist"

if [ -d "$APP" ] && [ -f "$INFO_PLIST" ]; then
  # Human-friendly version (e.g., 140.0.7444.135)
  VER=$(/usr/bin/defaults read "$INFO_PLIST" CFBundleShortVersionString 2>/dev/null)
  # Build number (e.g., 7444.135) — optional
  BUILD=$(/usr/bin/defaults read "$INFO_PLIST" CFBundleVersion 2>/dev/null)

  if [ -n "$VER" ] && [ -n "$BUILD" ]; then
    echo "<result>${VER} (${BUILD})</result>"
  elif [ -n "$VER" ]; then
    echo "<result>${VER}</result>"
  else
    # Fallback to Spotlight metadata if Info read failed
    MDVER=$(/usr/bin/mdls -name kMDItemVersion -raw "$APP" 2>/dev/null)
    [ -n "$MDVER" ] && echo "<result>${MDVER}</result>" || echo "<result>Unknown</result>"
  fi
else
  echo "<result>Not Installed</result>"
fi

exit 0
