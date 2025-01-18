#!/bin/bash
# Script: install_airplay.sh
# Beschreibung:
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

echo "========================================"
echo " Shairport Sync Installation "
echo "========================================"


# Shairport Sync installieren
echo "[INFO] Installiere Shairport Sync..."
sudo apt install -y shairport-sync

# Status anzeigen
echo "[INFO] Überprüfe Shairport Sync-Status..."
sudo systemctl status shairport-sync --no-pager

echo "[INFO] Shairport Sync wurde erfolgreich installiert."
