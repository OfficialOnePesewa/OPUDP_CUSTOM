#!/bin/bash
# OPUDP_CUSTOM - UDP Custom Server with HWID Authentication
# Repo: https://github.com/OfficialOnePesewa/OPUDP_CUSTOM
# One-liner: wget -O install.sh https://raw.githubusercontent.com/OfficialOnePesewa/OPUDP_CUSTOM/main/install.sh && chmod +x install.sh && bash install.sh

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

# ----------------------------------------------------------------------
# HEADER & SYSTEM INFO
# ----------------------------------------------------------------------
display_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║   ██████╗ ██████╗ ██╗   ██╗██████╗  ██████╗██╗   ██╗████████╗    ║"
    echo "║  ██╔═══██╗██╔══██╗██║   ██║██╔══██╗██╔════╝██║   ██║╚══██╔══╝    ║"
    echo "║  ██║   ██║██████╔╝██║   ██║██║  ██║██║     ██║   ██║   ██║       ║"
    echo "║  ██║   ██║██╔═══╝ ██║   ██║██║  ██║██║     ██║   ██║   ██║       ║"
    echo "║  ╚██████╔╝██║     ╚██████╔╝██████╔╝╚██████╗╚██████╔╝   ██║       ║"
    echo "║   ╚═════╝ ╚═╝      ╚═════╝ ╚═════╝  ╚═════╝ ╚═════╝    ╚═╝       ║"
    echo "║                   UDP CUSTOM PANEL v1.0                          ║"
    echo "║                   Telegram: @OfficialOnePesewa                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

display_system_info() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                         SYSTEM INFORMATION                       ║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
    . /etc/os-release 2>/dev/null || true
    OS_NAME="${NAME:-$(uname -s)}"
    OS_VERSION="${VERSION_ID:-$(uname -r)}"
    echo -e "${GREEN}║ OS:${NC} $OS_NAME $OS_VERSION"
    ARCH=$(uname -m)
    [[ "$ARCH" == "x86_64" ]] && echo -e "${GREEN}║ Architecture:${NC} 64-bit" || echo -e "${GREEN}║ Architecture:${NC} 32-bit"
    echo -e "${GREEN}║ System Time (GMT):${NC} $(date -u '+%Y-%m-%d %H:%M:%S GMT')"
    SERVER_IP=$(curl -s -4 icanhazip.com 2>/dev/null || curl -s -4 ifconfig.me 2>/dev/null)
    echo -e "${GREEN}║ Server IP:${NC} $SERVER_IP"
    if command -v jq &>/dev/null; then
        GEO_DATA=$(curl -s "https://ipapi.co/$SERVER_IP/json/")
        CITY=$(echo "$GEO_DATA" | jq -r '.city // "Unknown"')
        COUNTRY=$(echo "$GEO_DATA" | jq -r '.country_name // "Unknown"')
        echo -e "${GREEN}║ Location:${NC} $CITY, $COUNTRY"
    fi
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
}

# ----------------------------------------------------------------------
# DEPENDENCIES & BINARY DOWNLOAD
# ----------------------------------------------------------------------
install_deps() {
    apt-get update -y
    apt-get install -y wget curl git build-essential jq bc systemd ufw net-tools at
}

install_udp_custom() {
    mkdir -p /opt/opudp/{config,scripts,utils,users,logs}
    cd /opt/opudp
    echo -e "${YELLOW}Downloading UDP Custom binary...${NC}"
    wget -q --show-progress -O udp-custom 'https://github.com/http-custom/udp-custom/raw/refs/heads/main/bin/udp-custom-linux-amd64'
    echo -e "${YELLOW}Downloading UDP Gateway binary...${NC}"
    wget -q --show-progress -O udpgw 'https://github.com/http-custom/udp-custom/raw/refs/heads/main/module/udpgw'
    chmod +x udp-custom udpgw
    cd - >/dev/null
}

# ----------------------------------------------------------------------
# AUTHENTICATION SCRIPTS
# ----------------------------------------------------------------------
create_auth_script() {
    cat > /opt/opudp/auth.sh << 'EOF'
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
EOF
    chmod +x /opt/opudp/auth.sh
}

create_hwid_utils() {
    cat > /opt/opudp/utils/hwid_auth.sh << 'EOF'
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
EOF
    chmod +x /opt/opudp/utils/hwid_auth.sh
}

create_geolocation_utils() {
    cat > /opt/opudp/utils/geolocation.sh << 'EOF'
#!/bin/bash
get_geolocation() {
    local ip="$1"
    local data=$(curl -s "https://ipapi.co/$ip/json/")
    if command -v jq &>/dev/null; then
        city=$(echo "$data" | jq -r '.city // "Unknown"')
        country=$(echo "$data" | jq -r '.country_name // "Unknown"')
        echo "$city, $country"
    else
        echo "Unknown"
    fi
}
get_server_location() {
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    get_geolocation "$ip"
}
EOF
    chmod +x /opt/opudp/utils/geolocation.sh
}

# ----------------------------------------------------------------------
# USER MANAGEMENT SCRIPTS
# ----------------------------------------------------------------------
create_create_user_script() {
    cat > /opt/opudp/scripts/create_user.sh << 'EOF'
#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
source /opt/opudp/utils/geolocation.sh
clear
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    CREATE HWID-BOUND USER                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
read -p "Username (4-12 chars): " username
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
EOF
    chmod +x /opt/opudp/scripts/create_user.sh
}

create_other_scripts() {
    cat > /opt/opudp/scripts/remove_user.sh << 'EOF'
#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
read -p "Username to remove: " user
if user_exists "$user"; then
    remove_user "$user"
    echo "✅ User $user removed."
else
    echo "❌ User not found."
fi
EOF
    chmod +x /opt/opudp/scripts/remove_user.sh

    cat > /opt/opudp/scripts/list_users.sh << 'EOF'
#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
list_users
EOF
    chmod +x /opt/opudp/scripts/list_users.sh

    cat > /opt/opudp/scripts/renew_user.sh << 'EOF'
#!/bin/bash
source /opt/opudp/utils/hwid_auth.sh
read -p "Username: " user
if ! user_exists "$user"; then echo "Not found"; exit 1; fi
read -p "Additional days: " days
renew_user "$user" "$days"
echo "✅ Renewed. New expiry: $(date -d "+$days days" '+%Y-%m-%d')"
EOF
    chmod +x /opt/opudp/scripts/renew_user.sh

    cat > /opt/opudp/scripts/block_user.sh << 'EOF'
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
EOF
    chmod +x /opt/opudp/scripts/block_user.sh

    cat > /opt/opudp/scripts/user_info.sh << 'EOF'
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
EOF
    chmod +x /opt/opudp/scripts/user_info.sh

    cat > /opt/opudp/scripts/service_control.sh << 'EOF'
#!/bin/bash
echo "1) Start  2) Stop  3) Restart  4) Status"
read -p "Choice: " opt
case $opt in
    1) systemctl start opudp-custom opudpgw;;
    2) systemctl stop opudp-custom opudpgw;;
    3) systemctl restart opudp-custom opudpgw;;
    4) systemctl status opudp-custom opudpgw --no-pager;;
esac
EOF
    chmod +x /opt/opudp/scripts/service_control.sh

    cat > /opt/opudp/scripts/dashboard.sh << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                OPUDP CUSTOM PANEL - DASHBOARD                    ║"
    echo "║                Telegram: @OfficialOnePesewa                     ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "🕐 GMT Time : $(date -u '+%Y-%m-%d %H:%M:%S')"
    echo "💻 OS       : $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo ""
    echo "📋 MENU"
    echo "──────────────────────────────────────────────────────────────────"
    echo " 1) Create HWID-bound user"
    echo " 2) List all users"
    echo " 3) Remove user"
    echo " 4) Renew user"
    echo " 5) Block/Unblock user"
    echo " 6) Show user card with geolocation"
    echo " 7) Start/Stop services"
    echo " 8) View logs"
    echo " 9) Exit"
    read -p "Choice [1-9]: " ch
    case $ch in
        1) /opt/opudp/scripts/create_user.sh; read -p "Enter to continue...";;
        2) /opt/opudp/scripts/list_users.sh; read -p "Enter to continue...";;
        3) /opt/opudp/scripts/remove_user.sh; read -p "Enter to continue...";;
        4) /opt/opudp/scripts/renew_user.sh; read -p "Enter to continue...";;
        5) /opt/opudp/scripts/block_user.sh; read -p "Enter to continue...";;
        6) /opt/opudp/scripts/user_info.sh; read -p "Enter to continue...";;
        7) /opt/opudp/scripts/service_control.sh; read -p "Enter to continue...";;
        8) tail -50 /opt/opudp/logs/opudp.log 2>/dev/null || echo "No logs yet"; read -p "Enter...";;
        9) exit 0;;
    esac
done
EOF
    chmod +x /opt/opudp/scripts/dashboard.sh
}

# ----------------------------------------------------------------------
# CONFIGURATION, SERVICES, FIREWALL
# ----------------------------------------------------------------------
create_config() {
    cat > /opt/opudp/config/config.json << EOF
{
    "listen": ":5680",
    "stream_buffer": 209715200,
    "receive_buffer": 209715200,
    "auth": {
        "mode": "exec",
        "exec": "/opt/opudp/auth.sh"
    },
    "udp_gateway": {
        "address": "127.0.0.1:7300",
        "max_clients": 1000,
        "max_connections_per_client": 100
    }
}
EOF
}

create_services() {
    cat > /etc/systemd/system/opudp-custom.service << EOF
[Unit]
Description=OPUDP Custom Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/opudp
ExecStart=/opt/opudp/udp-custom server
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/opudpgw.service << EOF
[Unit]
Description=OPUDP Gateway Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/opudp/udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 100
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable opudp-custom opudpgw
}

configure_firewall() {
    ufw allow 5680/udp comment 'OPUDP_CUSTOM' 2>/dev/null || true
    ufw allow 7300/udp comment 'OPUDP_GATEWAY' 2>/dev/null || true
    ufw allow 40000:49999/udp comment 'OPUDP_PORT_RANGE' 2>/dev/null || true
    ufw reload 2>/dev/null || true
}

start_services() {
    systemctl start opudp-custom opudpgw
    sleep 2
    if systemctl is-active --quiet opudp-custom && systemctl is-active --quiet opudpgw; then
        echo -e "${GREEN}✅ Services started successfully.${NC}"
    else
        echo -e "${RED}❌ Services failed to start. Check logs: journalctl -u opudp-custom${NC}"
        exit 1
    fi
}

create_opudp_command() {
    cat > /usr/local/bin/opudp << 'EOF'
#!/bin/bash
/opt/opudp/scripts/dashboard.sh
EOF
    chmod +x /usr/local/bin/opudp
}

# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------
main() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root!${NC}"
        exit 1
    fi
    display_header
    display_system_info
    install_deps
    install_udp_custom
    create_auth_script
    create_hwid_utils
    create_geolocation_utils
    mkdir -p /opt/opudp/scripts
    create_create_user_script
    create_other_scripts
    create_config
    create_services
    configure_firewall
    start_services
    create_opudp_command
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                     INSTALLATION COMPLETE!                        ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "👉 Run ${CYAN}opudp${NC} to open the dashboard and create HWID‑bound users."
    echo -e "📱 Configuration string format: ${CYAN}YOUR_IP:5680@USERNAME:PASSWORD:HWID${NC}"
    echo ""
}

main
