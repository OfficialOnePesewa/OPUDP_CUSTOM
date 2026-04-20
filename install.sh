#!/bin/bash
# OPUDP_CUSTOM - UDP Custom with HWID Authentication
# One-line installer: git clone https://github.com/OfficialOnePesewa/OPUDP_CUSTOM.git && cd OPUDP_CUSTOM && sudo bash install.sh

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

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

install_deps() {
    apt-get update -y
    apt-get install -y wget curl git build-essential jq bc systemd ufw net-tools at
}

install_udp_custom() {
    mkdir -p /opt/opudp/{config,scripts,utils,users,logs}
    cd /opt/opudp
    if [[ "$(uname -m)" == "x86_64" ]]; then
        wget -q --show-progress -O udp-custom "https://github.com/http-custom/udp-custom/releases/latest/download/udp-custom-linux-amd64"
        wget -q --show-progress -O udpgw "https://github.com/http-custom/udp-custom/releases/latest/download/udpgw-linux-amd64"
    elif [[ "$(uname -m)" == "aarch64" ]]; then
        wget -q --show-progress -O udp-custom "https://github.com/http-custom/udp-custom/releases/latest/download/udp-custom-linux-arm64"
        wget -q --show-progress -O udpgw "https://github.com/http-custom/udp-custom/releases/latest/download/udpgw-linux-arm64"
    else
        echo -e "${RED}Unsupported architecture${NC}"; exit 1
    fi
    chmod +x udp-custom udpgw
    cd - >/dev/null
}

copy_scripts() {
    # Get the directory where install.sh is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp -r "$SCRIPT_DIR/scripts"/* /opt/opudp/scripts/
    cp -r "$SCRIPT_DIR/utils"/* /opt/opudp/utils/
    cp "$SCRIPT_DIR/auth.sh" /opt/opudp/auth.sh
    chmod +x /opt/opudp/scripts/*.sh /opt/opudp/utils/*.sh /opt/opudp/auth.sh
}

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

main() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root!${NC}"
        exit 1
    fi
    display_header
    display_system_info
    install_deps
    install_udp_custom
    copy_scripts
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
