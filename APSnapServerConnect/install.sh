#!/bin/bash
# Script: installt.sh
# Description: Installs AirPlay and Snapcast connection on a Raspberry Pi
# Author: Thilo Rode

set -e  # Exit on error

# Set environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive

# Header
echo "========================================"
echo "Airplay and Snapcast Connection Installation"
echo "========================================"

CONFIG_FILE="/etc/snapserver.conf"
BACKUP_FILE="/etc/snapserver.conf.bak"

# Backup der Datei erstellen (nur einmal, falls noch nicht vorhanden)
if [ ! -f "$BACKUP_FILE" ]; then
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "✅ Backup erstellt: $BACKUP_FILE"
fi

# 1️⃣ **Ersetze die gesamte Zeile, die mit "# airplay: airplay" beginnt**
sudo sed -i '/^# airplay: airplay/c\airplay: airplay:///usr/bin/shairport-sync?name=ZuhauseAirplay&dryout_ms=2000&port=5000' "$CONFIG_FILE"

# 2️⃣ **Falls "source = airplay:///shairport-sync?name=Airplay" fehlt, füge es ein**
if ! grep -q "^source = airplay:///shairport-sync?name=Airplay" "$CONFIG_FILE"; then
    sudo sed -i '/^source = pipe:\/\/\/tmp\/snapfifo?name=default/i source = airplay:///shairport-sync?name=Airplay' "$CONFIG_FILE"
    echo "✅ 'source = airplay:///shairport-sync?name=Airplay' wurde eingefügt."
else
    echo "⚠️ 'source = airplay:///shairport-sync?name=Airplay' existiert bereits. Keine Änderung notwendig."
fi

# Snapserver neu starten
sudo systemctl restart snapserver
echo "✅ Snapserver neu gestartet."
