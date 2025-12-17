#!/bin/bash
set -e

EDGE_PKG_URL="https://go.microsoft.com/fwlink/?linkid=2093504"
TMP_PKG="/tmp/MicrosoftEdge.pkg"

echo "Downloading Microsoft Edge (macOS PKG)..."
curl -L "$EDGE_PKG_URL" -o "$TMP_PKG"

# Quick sanity check: ensure we downloaded a macOS installer package
if ! file "$TMP_PKG" | grep -qi "xar archive"; then
  echo "ERROR: Downloaded file does not look like a macOS .pkg. (Maybe a redirect changed?)"
  file "$TMP_PKG"
  exit 1
fi

echo "Installing..."
/usr/sbin/installer -pkg "$TMP_PKG" -target /

RESULT=$?

echo "Cleaning up..."
rm -f "$TMP_PKG"

echo "Done (exit code: $RESULT)"
exit $RESULT
