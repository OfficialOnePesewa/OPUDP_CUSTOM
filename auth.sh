#!/bin/bash
USERNAME="$1"
PASSWORD_FIELD="$2"
HWID_DB="/opt/opudp/users/hwid.db"

HWID=$(echo "$PASSWORD_FIELD" | awk -F':' '{print $NF}')

[[ -z "$USERNAME" || -z "$HWID" ]] && exit 1

entry=$(grep "^$USERNAME:" "$HWID_DB" 2>/dev/null) || exit 1
IFS=':' read -r user stored_hwid_hash expiry limit status <<< "$entry"

[[ "$status" != "active" ]] && exit 1
[[ $(date +%s) -gt $expiry ]] && exit 1

provided_hash=$(echo -n "$HWID" | sha256sum | awk '{print $1}')
[[ "$provided_hash" == "$stored_hwid_hash" ]] && exit 0 || exit 1
