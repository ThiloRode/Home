#!/bin/bash
# Script: installt.sh
# Description: Installs Bluetooth and related packages on a Raspberry Pi
# Author: Thilo Rode

set -e  # Exit on error

# Set environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive

# Header
echo "========================================"
echo "Airplay and Snapcast Conection Installation"
echo "========================================"


CONFIG_FILE="/etc/snapserver.conf"
BACKUP_FILE="/etc/snapserver.conf.bak"

# Die neuen Einträge, die hinter [stream] eingefügt werden sollen
NEW_ENTRIES="source = airplay:///usr/bin/shairport-sync?name=ZuhauseAirplay&dryout_ms=2000&port=5000
source = airplay:///shairport-sync?name=Airplay

# Backup der Datei erstellen (nur einmal, falls noch nicht vorhanden)
if [ ! -f "$BACKUP_FILE" ]; then
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "✅ Backup erstellt: $BACKUP_FILE"
fi

# Prüfen, ob der Abschnitt [stream] existiert
if grep -q "^\[stream\]" "$CONFIG_FILE"; then
    # Prüfen, ob mindestens ein neuer Eintrag bereits existiert
    ADD_REQUIRED=0
    for entry in "$NEW_ENTRIES"; do
        if ! grep -qF "$entry" "$CONFIG_FILE"; then
            ADD_REQUIRED=1
            break
        fi
    done

    if [ $ADD_REQUIRED -eq 1 ]; then
        # Falls mindestens ein Eintrag fehlt, werden ALLE neuen Einträge hinzugefügt
        sudo sed -i "/^\[stream\]/a $NEW_ENTRIES" "$CONFIG_FILE"
        echo "✅ Snapserver-Konfiguration aktualisiert."
        # Snapserver neu starten
        sudo systemctl restart snapserver
        echo "✅ Snapserver neu gestartet."
    else
        echo "⚠️ Alle gewünschten Einträge sind bereits vorhanden. Keine Änderung notwendig."
    fi
else
    echo "Fehler: Der Abschnitt stream wurde nicht in der Datei gefunden!"
fi
