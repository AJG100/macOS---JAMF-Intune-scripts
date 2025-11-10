#!/bin/sh

# Description: Script to install the Nexthink Collector form the pre-cached dmg installer file, Root CA & Customer Key.

# Mount the DMG

hdiutil mount /private/tmp/Nexthink_Collector_Installer/Nexthink_Collector_6.30.1.7_10.13-11.0.dmg -noverify -nobrowse -noautoopen

# Change the directory to the path of the csi application:

cd /Volumes/Nexthink_Collector_6.30.1.7\ OSX\ 10.13\ -\ 11.0/csi.app/Contents/MacOS/

# Define the parameters for csi.app for installing the Collector from the command line interface

sudo ./csi -address iqvia-engine.eu.nexthink.cloud -port 999 -tcp_port 443 -key /private/tmp/Nexthink_Collector_Installer/customer_key.txt -engage enable -data_over_tcp enable -ra_execution_policy signed_trusted_or_nexthink -use_assignment enable

# Disable/Enable Coordinator Service

  launchctl unload /Library/LaunchDaemons/com.nexthink.collector.nxtcoordinator.plist
  launchctl load /Library/LaunchDaemons/com.nexthink.collector.nxtcoordinator.plist

# Install NexthinkExperience.mobileconfig

# profiles install -path /private/tmp/Nexthink Collector 6.30/Nexthink_Collector_installer/NexthinkExperience.mobileconfig -forced

# Unmount the DMG

hdiutil detach /Volumes/Nexthink_Collector_6.30.1.7\ OSX\ 10.13\ -\ 11.0/ -force

# Delete the package contents

/bin/rm -rf /private/tmp/Nexthink_Collector_installer/
