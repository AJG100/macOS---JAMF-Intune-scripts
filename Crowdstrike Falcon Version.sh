#!/bin/bash

FALCON_APP="/Applications/Falcon.app"

if [ -d "$FALCON_APP" ]; then
  VERSION=$(defaults read \
    "$FALCON_APP/Contents/Info.plist" \
    CFBundleShortVersionString 2>/dev/null)

  if [ -n "$VERSION" ]; then
    echo "<result>$VERSION</result>"
  else
    echo "<result>Unknown Version</result>"
  fi
else
  echo "<result>Not Installed</result>"
fi
