# OPUDP_CUSTOM – UDP Custom Server with HWID Authentication

[![Telegram](https://img.shields.io/badge/Telegram-@OfficialOnePesewa-blue.svg)](https://t.me/OfficialOnePesewa)

**Prevent account sharing** – each user is bound to a unique HWID from the HTTP Custom app.  
Works **alongside** your existing zivpn (different ports). Supports **Ubuntu and Debian**.

## ✨ Features

- 🔐 **HWID Authentication** – Each user account is bound to a unique device HWID.
- 🌍 **Geolocation Tracking** – Shows server location using ipapi.co API.
- 📊 **Interactive CLI Dashboard** – Manage users, services, and view logs.
- 🔧 **Coexistence Support** – Installs alongside existing zivpn without conflicts (port 5680).
- 📱 **HTTP Custom Integration** – Compatible with the HTTP Custom app for Android.

## 📋 Requirements

- **OS:** Ubuntu 20.04/22.04/24.04 or Debian 11/12 (x86_64)
- **RAM:** Minimum 512MB
- **Root access** to the server

## 🚀 One‑Line Installer

Run this command on your VPS as **root**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/OfficialOnePesewa/OPUDP_CUSTOM/main/install.sh)
