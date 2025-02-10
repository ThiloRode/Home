#!/bin/bash
# Script: install_snapclient.sh
# Beschreibung:
# Dieses Skript installiert den Snapcast-Client (Snapclient) auf einem Debian-basierten System.
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

# Header anzeigen
echo "========================================"
echo " Snapcast-Client Installation "
echo "========================================"

# Update und Installation von Snapclient
echo "[INFO] Aktualisiere Paketlisten und installiere Snapclient..."
sudo apt update
sudo apt install -y snapclient

# Snapclient-Dienst aktivieren und starten
echo "[INFO] Aktiviere und starte Snapclient..."
sudo systemctl enable --now snapclient

# Status überprüfen
echo "[INFO] Überprüfe den Snapclient-Status..."
sudo systemctl status snapclient --no-pager

echo "✅ Snapclient-Installation abgeschlossen!"
