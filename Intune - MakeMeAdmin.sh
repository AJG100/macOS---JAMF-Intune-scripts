#!/bin/bash
set -euo pipefail
U="$(stat -f %Su /dev/console)"
[ "$U" = "root" ] && exit 0
if id "$U" &>/dev/null; then
  dseditgroup -o checkmember -m "$U" admin | grep -q "yes" || dseditgroup -o edit -a "$U" -t user admin
  echo "✓ '$U' elevated to admin"
fi
