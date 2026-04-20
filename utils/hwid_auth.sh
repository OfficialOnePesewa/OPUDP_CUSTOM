#!/bin/bash
HWID_DB="/opt/opudp/users/hwid.db"

init_db() { mkdir -p /opt/opudp/users; touch "$HWID_DB"; }

add_user() {
    local user="$1" hwid="$2" expiry="$3" limit="$4"
    local hwid_hash=$(echo -n "$hwid" | sha256sum | awk '{print $1}')
    echo "$user:$hwid_hash:$expiry:$limit:active" >> "$HWID_DB"
}

remove_user() { sed -i "/^$1:/d" "$HWID_DB"; }
user_exists() { grep -q "^$1:" "$HWID_DB"; }

list_users() {
    echo "══════════════════════════════════════════════════════════════════"
    printf "%-15s %-20s %-12s %-8s %-10s\n" "Username" "HWID Hash" "Expiry" "Limit" "Status"
    echo "──────────────────────────────────────────────────────────────────"
    while IFS=':' read -r u h e l s; do
        exp_date=$(date -d "@$e" "+%Y-%m-%d")
        printf "%-15s %-20s %-12s %-8s %-10s\n" "$u" "${h:0:16}..." "$exp_date" "$l" "$s"
    done < "$HWID_DB"
}

renew_user() {
    local user="$1" days="$2"
    local new_expiry=$(date -d "+$days days" +%s)
    sed -i "s/^$user:\([^:]*\):[0-9]*:\([^:]*\):\(.*\)$/$user:\1:$new_expiry:\2:\3/" "$HWID_DB"
}

set_status() {
    local user="$1" status="$2"
    sed -i "s/^\($user:[^:]*:[^:]*:[^:]*:\).*$/\1$status/" "$HWID_DB"
}

get_user_info() { grep "^$1:" "$HWID_DB"; }
init_db
