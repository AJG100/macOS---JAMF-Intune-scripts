#!/bin/bash

set -e

EDGE_DMG_URL="https://go.microsoft.com/fwlink/?linkid=2069148"
TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/MicrosoftEdge.dmg"
MOUNT_POINT="$TMP_DIR/mount"

echo "Downloading Microsoft Edge DMG..."
curl -L "$EDGE_DMG_URL" -o "$DMG_PATH"

echo "Mounting DMG..."
hdiutil attach "$DMG_PATH" -nobrowse -quiet -mountpoint "$MOUNT_POINT"

echo "Installing Microsoft Edge..."
cp -R "$MOUNT_POINT/Microsoft Edge.app" /Applications/

echo "Fixing permissions..."
chown -R root:wheel "/Applications/Microsoft Edge.app"
chmod -R 755 "/Applications/Microsoft Edge.app"

echo "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" -quiet

echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Microsoft Edge installation complete."
exit 0
