#!/bin/bash

ZSCALER_APP="/Applications/Zscaler.app"

if [ -d "$ZSCALER_APP" ]; then
  VERSION=$(defaults read \
    "$ZSCALER_APP/Contents/Info.plist" \
    CFBundleShortVersionString 2>/dev/null)

  if [ -n "$VERSION" ]; then
    echo "<result>$VERSION</result>"
  else
    echo "<result>Unknown Version</result>"
  fi
else
  echo "<result>Not Installed</result>"
fi
