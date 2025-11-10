#!/bin/bash

#your domain name reversed
reverseDomainName="com.quintiles"

#unload if it exists for some reason
[ -e "/Library/LaunchDaemons/${reverseDomainName}.runJamfPolicy.plist" ] && launchctl unload "/Library/LaunchDaemons/${reverseDomainName}.runJamfPolicy.plist" 2>/dev/null

cat <<-EOF > "/Library/LaunchDaemons/${reverseDomainName}.runJamfPolicy.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${reverseDomainName}.runJamfPolicy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/runJamfPolicy.command</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

cat <<-EOF > /usr/local/bin/runJamfPolicy.command
#!/bin/bash

#time to wait between checks ensuring "jamf policy" has ended
sleepIntervalSeconds=10

#send to a log file and echo out
function logEcho {
#echo out to stdout and /var/log/jamf.log
echo "\$(date +'%a %b %d %H:%M:%S') \$(hostname | cut -d . -f1) \${myName:="\$(basename "\${0%%.*}")"}[\${myPID:=\$\$}]: \$@" | tee -a /var/log/jamf.log
}

#until the "jamf policy" is not found in the output of "ps auxww" sleep and keep checking
until [ -z "\$(ps auxww | grep [j]amf\ policy)" ]; do
    logEcho "Waiting jamf policy running, waiting \${sleepIntervalSeconds} seconds..."
    sleep \${sleepIntervalSeconds}
done

logEcho "All clear, running \"/usr/local/bin/jamf policy\""
/usr/local/bin/jamf policy

logEcho "Finished. Exiting and Uninstalling."

#delete this script
rm "\$0"

#erase the launchd file
rm /Library/LaunchDaemons/${reverseDomainName}.runJamfPolicy.plist

#remove the launchd by label name
launchctl remove ${reverseDomainName}.runJamfPolicy
EOF

#ensure correct ownership and mode 
chown root:wheel "/Library/LaunchDaemons/${reverseDomainName}.runJamfPolicy.plist" "/usr/local/bin/runJamfPolicy.command"
chmod ugo+rx,go-w "/usr/local/bin/runJamfPolicy.command"
chmod ugo+r,go-w "/Library/LaunchDaemons/${reverseDomainName}.runJamfPolicy.plist"

#load the launchd
launchctl load "/Library/LaunchDaemons/${reverseDomainName}.runJamfPolicy.plist"