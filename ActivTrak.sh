#!/bin/bash

appPath="/Applications/ActivTrak.app"

if [ -d "$appPath" ]; then
    version=$(/usr/bin/defaults read "$appPath/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

    if [ -z "$version" ]; then
        version=$(/usr/bin/defaults read "$appPath/Contents/Info.plist" CFBundleVersion 2>/dev/null)
    fi

    echo "<result>$version</result>"
else
    echo "<result>Not Installed</result>"
fi
