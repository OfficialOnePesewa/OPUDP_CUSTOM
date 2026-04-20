#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
source /opt/opudp/utils/geolocation.sh

read -p "Username: " user
entry=$(get_user_info "$user")
if [[ -z "$entry" ]]; then echo "Not found"; exit 1; fi
IFS=':' read -r u h e l s <<< "$entry"

server_ip=$(curl -s -4 icanhazip.com 2>/dev/null)
location=$(get_server_location)

echo ""
echo "══════════════════════════════════════════════════════════════════"
echo "                     USER CARD INFO                               "
echo "══════════════════════════════════════════════════════════════════"
echo "👤 Username   : $u"
echo "🔑 HWID hash  : ${h:0:16}..."
echo "📅 Expires    : $(date -d "@$e" '+%Y-%m-%d')"
echo "🔗 Limit      : $l"
echo "📊 Status     : $s"
echo "🌍 Server     : $server_ip ($location)"
echo "📱 Admin      : @OfficialOnePesewa"
echo "💸 Telecel Cash for contributions"
