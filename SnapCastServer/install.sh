#!/bin/bash
# Script: install_snapcast_server.sh
# Beschreibung:
# Dieses Skript installiert den Snapcast-Server auf einem Debian-basierten System (z. B. Raspberry Pi).
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

# Header anzeigen
echo "========================================"
echo " Snapcast-Server Installation "
echo "========================================"
echo "Configuring Snapserver..."
CONFIG_FILE="/etc/snapserver.conf"

sudo bash -c "cat > $CONFIG_FILE" <<EOF
[stream]
source = pipe:///tmp/snapfifo?name=AirPlay
EOF

# Snapserver starten und aktivieren
echo "Starting and enabling Snapserver service..."
sudo systemctl enable snapserver
sudo systemctl restart snapserver

echo "Snapserver installation and configuration complete!"
