#!/bin/bash
# Called by udp-custom with: username password
# Password field contains "password:hwid" because the app sends "username:password:hwid"
USERNAME="$1"
PASSWORD_FIELD="$2"
HWID_DB="/opt/opudp/users/hwid.db"

# Extract HWID (part after the last colon)
HWID=$(echo "$PASSWORD_FIELD" | awk -F':' '{print $NF}')

if [[ -z "$USERNAME" || -z "$HWID" ]]; then
    exit 1
fi

entry=$(grep "^$USERNAME:" "$HWID_DB" 2>/dev/null)
if [[ -z "$entry" ]]; then
    exit 1
fi

IFS=':' read -r user stored_hwid_hash expiry limit status <<< "$entry"

[[ "$status" != "active" ]] && exit 1
[[ $(date +%s) -gt $expiry ]] && exit 1

provided_hash=$(echo -n "$HWID" | sha256sum | awk '{print $1}')
[[ "$provided_hash" == "$stored_hwid_hash" ]] && exit 0 || exit 1
