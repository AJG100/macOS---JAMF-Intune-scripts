#!/bin/bash
#
# CrowdStrike Falcon - License with CID
# Run as a Jamf Pro Script, ordered AFTER the FalconSensor package install
# in the same policy. Idempotent: skips if already licensed.
#
# Jamf Script Parameter Labels:
#   Parameter 4 = CID (e.g. XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XX)

CID="$4"
FALCONCTL="/Applications/Falcon.app/Contents/Resources/falconctl"

if [[ -z "$CID" ]]; then
    echo "ERROR: No CID supplied in Parameter 4. Exiting."
    exit 1
fi

if [[ ! -x "$FALCONCTL" ]]; then
    echo "ERROR: falconctl not found at $FALCONCTL. Is the Falcon package installed?"
    exit 1
fi

# Skip if already licensed
CURRENT_STATE=$("$FALCONCTL" stats 2>/dev/null)
if echo "$CURRENT_STATE" | grep -q "cid="; then
    echo "Falcon sensor already licensed. Skipping."
    exit 0
fi

echo "Licensing Falcon sensor with provided CID..."
"$FALCONCTL" license "$CID"
RESULT=$?

if [[ $RESULT -eq 0 ]]; then
    echo "Falcon sensor licensed successfully."
else
    echo "ERROR: falconctl license failed with exit code $RESULT."
    exit $RESULT
fi

exit 0
