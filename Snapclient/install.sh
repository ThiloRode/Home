#!/bin/bash
# Script: install_snapclient.sh
# Beschreibung:
# Dieses Skript installiert den Snapcast-Client (Snapclient) auf einem Debian-basierten System
# und setzt ihn auf das ALSA-Gerät "left_only".
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

# Snapclient-Konfiguration setzen
echo "[INFO] Setze Snapclient-Optionen auf -s left_only..."
sudo tee /etc/default/snapclient > /dev/null <<EOF
SNAPCLIENT_OPTS="-s left_only"
EOF

# Snapclient-Dienst aktivieren
echo "[INFO] Aktiviere Snapclient..."
sudo systemctl enable snapclient

# Neustart von ALSA und Snapclient
echo "[INFO] Starte ALSA neu..."
sudo systemctl restart alsa-restore

echo "[INFO] Starte Snapclient neu..."
sudo systemctl restart snapclient

# Status überprüfen
echo "[INFO] Überprüfe den Snapclient-Status..."
sudo systemctl status snapclient --no-pager

echo "✅ Snapclient-Installation abgeschlossen!"
