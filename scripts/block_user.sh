#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
read -p "Username: " user
if ! user_exists "$user"; then echo "Not found"; exit 1; fi
read -p "Block (b) or Unblock (u)? " act
if [[ "$act" == "b" ]]; then
    set_status "$user" "blocked"
    echo "User blocked."
else
    set_status "$user" "active"
    echo "User unblocked."
fi
