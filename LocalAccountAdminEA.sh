#!/bin/bash

# Get the currently logged-in user
loggedInUser=$(stat -f "%Su" /dev/console)

# Ignore setup / no user state
if [[ "$loggedInUser" == "root" || -z "$loggedInUser" ]]; then
  echo "<result>No Logged-in User</result>"
  exit 0
fi

# Check admin group membership
if dseditgroup -o checkmember -m "$loggedInUser" admin | grep -q "yes"; then
  echo "<result>Admin</result>"
else
  echo "<result>Standard</result>"
fi
