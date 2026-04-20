#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
source /opt/opudp/utils/geolocation.sh

clear
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    CREATE HWID-BOUND USER                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"

read -p "Username (e.g., post): " username
[[ ! "$username" =~ ^[a-zA-Z0-9]{4,12}$ ]] && { echo "Invalid username"; exit 1; }

read -p "Password (any string, e.g., post): " password
[[ -z "$password" ]] && { echo "Password cannot be empty"; exit 1; }

read -p "HWID (from user's HTTP Custom app): " hwid
read -p "Expiry days (1-365): " days
[[ ! "$days" =~ ^[0-9]+$ ]] && { echo "Invalid days"; exit 1; }
expiry=$(date -d "+$days days" +%s)

read -p "Connection limit (1-999): " limit
[[ ! "$limit" =~ ^[0-9]+$ ]] && { echo "Invalid limit"; exit 1; }

add_user "$username" "$hwid" "$expiry" "$limit"

server_ip=$(curl -s -4 icanhazip.com 2>/dev/null)
location=$(get_server_location)

echo ""
echo "══════════════════════════════════════════════════════════════════"
echo "✅ USER CREATED"
echo "══════════════════════════════════════════════════════════════════"
echo "👤 Username : $username"
echo "🔑 Password : $password"
echo "🔐 HWID     : ${hwid:0:12}..."
echo "📅 Expires  : $(date -d "@$expiry" '+%Y-%m-%d')"
echo "🔗 Limit    : $limit"
echo "🌍 Server   : $server_ip ($location)"
echo ""
echo "📱 CONFIGURATION STRING (single port 5680):"
echo "   ${server_ip}:5680@${username}:${password}:${hwid}"
echo ""
echo "──────────────────────────────────────────────────────────────────"
echo "👉 User should copy the above line and paste it into HTTP Custom"
echo "   (UDP Custom section). The HWID is included at the end."
echo "──────────────────────────────────────────────────────────────────"
echo "Telegram: @OfficialOnePesewa | Telecel Cash for support"
