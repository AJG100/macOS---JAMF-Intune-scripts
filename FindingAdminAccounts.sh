#!/bin/bash

usersInAdminGroup=( $(dscl . read /Groups/admin GroupMembership) )
for user in "${usersInAdminGroup[@]}"
	do
		
		case ${user} in
			
			daemon)
				
				echo "Found ${user}! No Changes Made."
				
			;;
			
			jamfmgmt)
				
				echo "Found ${user}! No Changes Made."
				
			;;
			
			MacMDAdmin)
				
				echo "Found ${user}! No Changes Made."
				
			;;
			
			nobody)
				
				echo "Found ${user}! No Changes Made."
				
			;;
			
			root)
				
				echo "Found ${user}! No Changes Made."
				
			;;
			
			papercut)
				
				echo "Found ${user}! No Changes Made."
				
				;;
				
			*)
				echo "Found ${user}! Found Admin User."
				foundAdminUser="Admin User Found"
				;;
				
		esac
	
done

echo "<result>$foundAdminUser</result>"

exit $?