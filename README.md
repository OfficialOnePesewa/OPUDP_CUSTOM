# OPUDP_CUSTOM – UDP Custom Server with HWID Authentication

[![Telegram](https://img.shields.io/badge/Telegram-@OfficialOnePesewa-blue.svg)](https://t.me/OfficialOnePesewa)

**Prevent account sharing** – each user is bound to a unique HWID from the HTTP Custom app.  
Works **alongside** your existing zivpn (different ports).

## Features

- 🔐 HWID authentication (no account sharing)
- 🌍 Server geolocation via ipapi.co
- 📊 CLI dashboard with user management
- 🚀 Coexists with other UDP services (port 5680, range 40000‑49999)
- 📱 HTTP Custom compatible

## Installation

```bash
git clone https://github.com/OfficialOnePesewa/OPUDP_CUSTOM.git
cd OPUDP_CUSTOM
chmod +x install.sh
sudo ./install.sh
