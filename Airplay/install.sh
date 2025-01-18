#!/bin/bash
# Script: install_airplay.sh
# Beschreibung:
# Dieses Skript installiert Shairport Sync auf einem Debian-basierten System (z. B. Raspberry Pi).
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

echo "========================================"
echo " Shairport Sync Installation "
echo "========================================"

# Gerätename festlegen
DEVICE_NAME="Zuhause"
echo "[INFO] Gerätename wird auf '$DEVICE_NAME' gesetzt."

# Shairport Sync installieren
echo "[INFO] Installiere Shairport Sync..."
sudo apt install -y shairport-sync

# Status anzeigen
echo "[INFO] Überprüfe Shairport Sync-Status..."
sudo systemctl status shairport-sync --no-pager

echo "[INFO] Shairport Sync wurde erfolgreich installiert und mit dem Namen '$DEVICE_NAME' konfiguriert."
