# Remove Dupliclate Certificates
# All duplicate domain certificates on the device


ComputerName=$(/usr/sbin/scutil --get ComputerName)
#LogFile
LogFile="/var/log/adcs-certificates.log"
#Log Function
logger() {
    /bin/echo $(date "+%Y-%m-%d %H:%M:%S ") $1 >>"${LogFile}"
    /bin/echo $(date "+%Y-%m-%d %H:%M:%S ") $1
}
logger "-------------------------------------"
logger "Start: Check for mutilpe Certificates"
certList=$(security find-certificate -c $ComputerName -p -a)
# Get each cert into an array element
# Remove spaces
certList=$(echo "$certList" | sed 's/ //g')
# Put a space after the end of each cert
certList=$(echo "$certList" | sed 's/-----ENDCERTIFICATE-----/-----ENDCERTIFICATE----- /g')
# echo "$certList"
OIFS="$IFS"
IFS=' '
# read -a certArray <<< "${certList}"
declare -a certArray=($certList)
IFS="$OIFS"
i=-1
dateHashList=''
# Print what we got...
for cert in "${certArray[@]}"; do
    let "i++"
    # Fix the begin/end certificate
    cert=$(echo "$cert" | sed 's/-----BEGINCERTIFICATE-----/-----BEGIN CERTIFICATE-----/g')
    cert=$(echo "$cert" | sed 's/-----ENDCERTIFICATE-----/-----END CERTIFICATE-----/g')
    #   echo "$cert"
    #   echo "$cert" | openssl x509 -text
    certMD5=$(echo "$cert" | openssl x509 -noout -fingerprint -sha1 -inform pem | cut -d "=" -f 2 | sed 's/://g')
    certDate=$(echo "$cert" | openssl x509 -text | grep 'Not After' | sed -E 's|.*Not After : ||')
    certDateFormatted=$(date -jf "%b %d %T %Y %Z" "${certDate}" +%Y%m%d%H%M%S)
    logger "Cert ${i} : ${certDate} => $certDateFormatted"
    logger "Cert ${i} : ${certMD5}"
    NL=$'\n'
    dateHashList="${dateHashList}${NL}${certDateFormatted} ${certMD5}"
done
dateHashList=$(echo "$dateHashList" | sort | uniq)
lines=$(echo "$dateHashList" | wc -l | tr -d ' ')
let "lines--"
logger "Info There are $lines lines in the certificate date-hash list."
i=0
OIFS="$IFS"
IFS=$'\n' # make newlines the only separator
for dateHash in $dateHashList; do
    let "i++"
    dateNum="${dateHash%% *}"
    hash="${dateHash##* }"
    logger "${i}| Hash : \"$hash\" | dateNum : \"$dateNum\""
    if [[ i -ne $lines ]]; then
        logger "=> This cert will be removed"
        sudo security delete-certificate -Z $hash /Library/Keychains/System.keychain
        logger "=> Cert was $hash removed"
    else
        logger "=> This cert will not be touched because it has the latest expiration date."
    fi
done
IFS="$OIFS"
logger "-------------------------------------"
logger "End: Check for mutilpe Certificates"