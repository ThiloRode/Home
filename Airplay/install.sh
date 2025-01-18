#!/bin/bash
# Script: install_airplay.sh
# Beschreibung:
# Dieses Skript installiert Shairport Sync und konfiguriert AirPlay mit 48 kHz Resampling.
# Außerdem wird der Gerätename "Zuhause" für das AirPlay-Gerät festgelegt.
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

echo "========================================"
echo " Shairport Sync Installation "
echo "========================================"

# Gerätename festlegen
DEVICE_NAME="Zuhause"
echo "[INFO] Gerätename wird auf '$DEVICE_NAME' gesetzt."

# Paketlisten aktualisieren
echo "[INFO] Aktualisiere Paketlisten..."
sudo apt update

# Shairport Sync installieren
echo "[INFO] Installiere Shairport Sync..."
sudo apt install -y shairport-sync

# Konfigurationsdatei anpassen
echo "[INFO] Konfiguriere Shairport Sync für 48 kHz und den Gerätenamen '$DEVICE_NAME'..."
CONFIG_FILE="/etc/shairport-sync.conf"
sudo sed -i 's/^#?output_rate =.*/output_rate = "48000";/' "$CONFIG_FILE"
sudo sed -i 's/^#?output_backend =.*/output_backend = "alsa";/' "$CONFIG_FILE"
sudo sed -i 's/^#?resample =.*/resample = "soxr";/' "$CONFIG_FILE"

# Gerätenamen setzen
sudo sed -i "s/^#?name =.*/name = \"$DEVICE_NAME\";/" "$CONFIG_FILE"

# Shairport Sync neu starten
echo "[INFO] Starte Shairport Sync neu..."
sudo systemctl restart shairport-sync

# Status anzeigen
echo "[INFO] Überprüfe Shairport Sync-Status..."
sudo systemctl status shairport-sync --no-pager

echo "[INFO] Shairport Sync wurde erfolgreich installiert und mit dem Namen '$DEVICE_NAME' konfiguriert."
