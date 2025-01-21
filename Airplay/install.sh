#!/bin/bash
# Script: install.sh
# Beschreibung:
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

echo "========================================"
echo " Shairport Sync Installation "
echo "========================================"


# Update und Installation von Shairport-Sync

sudo apt install -y shairport-sync

# Konfiguration von Shairport-Sync
echo "Configuring Shairport-Sync..."
CONFIG_FILE="/etc/shairport-sync.conf"

sudo sed -i 's|^// output_backend.*|output_backend = "pipe";|' $CONFIG_FILE
sudo sed -i 's|^// output_device.*|output_device = "/tmp/snapfifo";|' $CONFIG_FILE

# FIFO-Ordner erstellen
echo "Creating FIFO pipe for Snapserver..."
sudo mkdir -p /tmp
sudo mkfifo /tmp/snapfifo
sudo chmod 666 /tmp/snapfifo

# Shairport-Sync starten und aktivieren
echo "Starting and enabling Shairport-Sync service..."
sudo systemctl enable shairport-sync
sudo systemctl restart shairport-sync

echo "Shairport-Sync installation and configuration complete!"