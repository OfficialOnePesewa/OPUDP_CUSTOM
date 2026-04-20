#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
read -p "Username: " user
if ! user_exists "$user"; then echo "Not found"; exit 1; fi
read -p "Additional days: " days
renew_user "$user" "$days"
echo "✅ Renewed. New expiry: $(date -d "+$days days" '+%Y-%m-%d')"
