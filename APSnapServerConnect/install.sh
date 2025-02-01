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

# Die neuen Zeilen, die hinter [stream] eingefügt werden sollen
NEW_ENTRIES="source = airplay:///usr/bin/shairport-sync?name=ZuhauseAirplay&dryout_ms=2000&port=5000
source = airplay:///shairport-sync?name=Airplay
source = pipe:///tmp/snapfifo?name=default"

# Prüfen, ob [stream] existiert
if grep -q "^\[stream\]" "$CONFIG_FILE"; then
    # Prüfen, ob die Einträge bereits vorhanden sind
    if ! grep -q "source = airplay" "$CONFIG_FILE" && ! grep -q "source = pipe" "$CONFIG_FILE"; then
        # Backup der Datei erstellen
        sudo cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

        # Die neuen Einträge direkt nach [stream] einfügen
        sudo sed -i "/^\[stream\]/a $NEW_ENTRIES" "$CONFIG_FILE"

        echo "✅ Snapserver-Konfiguration aktualisiert."
        # Snapserver neu starten, damit die Änderungen aktiv werden
        sudo systemctl restart snapserver
        echo "✅ Snapserver neu gestartet."
    else
        echo "⚠️ Die gewünschten Einträge sind bereits in der Konfiguration vorhanden. Keine Änderung notwendig."
    fi
else
    echo "❌ Fehler: Der Abschnitt [stream] wurde nicht in der Datei gefunden!"
fi

sudo reboot
