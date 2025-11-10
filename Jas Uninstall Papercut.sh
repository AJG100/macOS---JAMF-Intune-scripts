#!/bin/bash

#Unload the PCclient

launchctl unload /Library/LaunchAgents/com.papercut.client.plist

#Remove Papercut Client
rm -rf /Applications/PCClient.app/
rm -rf /Applications/PaperCut\ Print\ Deploy\ Client
rm -rf /Library/LaunchAgents/com.papercut.client.plist

sudo shutdown -r now

exit 0
