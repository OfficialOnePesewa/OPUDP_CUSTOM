#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
read -p "Username to remove: " user
if user_exists "$user"; then
    remove_user "$user"
    echo "✅ User $user removed."
else
    echo "❌ User not found."
fi
