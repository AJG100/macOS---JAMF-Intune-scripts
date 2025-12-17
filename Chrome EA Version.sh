#!/bin/bash

EDGE_APP="/Applications/Microsoft Edge.app"

if [ -d "$EDGE_APP" ]; then
  EDGE_VERSION=$(defaults read \
    "$EDGE_APP/Contents/Info.plist" \
    CFBundleShortVersionString 2>/dev/null)

  echo "<result>$EDGE_VERSION</result>"
else
  echo "<result>Not Installed</result>"
fi
