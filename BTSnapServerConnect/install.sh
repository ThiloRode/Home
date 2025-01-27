#!/bin/bash
# Script: installt.sh
# Description: Installs Bluetooth and related packages on a Raspberry Pi
# Author: Thilo Rode

set -e  # Exit on error

# Set environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive

# Header
echo "========================================"
echo " Bluetooth and Snapcast Conection Installation"
echo "========================================"

# Variablen
FIFO_DIR="/var/lib/snapfifo"
FIFO_PATH="$FIFO_DIR/bluetooth_fifo"
ALSA_CONFIG_USER="$HOME/.asoundrc"
ALSA_CONFIG_SYSTEM="/etc/asound.conf"
SNAPSERVER_DEFAULTS="/etc/default/snapserver"

# FIFO-Verzeichnis erstellen
echo "Erstelle FIFO-Verzeichnis unter $FIFO_DIR..."
if [ ! -d "$FIFO_DIR" ]; then
    sudo mkdir -p "$FIFO_DIR"
    sudo chmod 777 "$FIFO_DIR"
    echo "FIFO-Verzeichnis erstellt."
else
    echo "FIFO-Verzeichnis existiert bereits."
fi

# FIFO erstellen
echo "Erstelle FIFO unter $FIFO_PATH..."
if [ ! -p "$FIFO_PATH" ]; then
    sudo mkfifo "$FIFO_PATH"
    sudo chmod 666 "$FIFO_PATH"
    echo "FIFO erstellt."
else
    echo "FIFO existiert bereits."
fi

# ALSA-Konfiguration einrichten
echo "Richte ALSA-Konfiguration ein..."
if [ -w "$ALSA_CONFIG_SYSTEM" ]; then
    CONFIG_PATH="$ALSA_CONFIG_SYSTEM"
else
    CONFIG_PATH="$ALSA_CONFIG_USER"
fi

cat <<EOL > "$CONFIG_PATH"
# Bluetooth-Audio direkt ins FIFO leiten
pcm.fifo_output {
    type file
    slave.pcm {
        type bluealsa
        interface "hci0"              # Bluetooth-Adapter (normalerweise hci0)
        profile "a2dp"               # High-Quality Audio-Profil
    }
    file "$FIFO_PATH"                # Pfad zum FIFO
    format "raw"                     # PCM-Daten im Rohformat
}

# Standardausgabe auf das FIFO umleiten
pcm.!default {
    type plug
    slave.pcm "fifo_output"
}
EOL

echo "ALSA-Konfiguration geschrieben: $CONFIG_PATH"

# Snapserver-Defaults bearbeiten
echo "Konfiguriere Snapserver-Defaults unter $SNAPSERVER_DEFAULTS..."
if grep -q "SNAPSERVER_OPTS" "$SNAPSERVER_DEFAULTS"; then
    if grep -q "pipe://$FIFO_PATH" "$SNAPSERVER_DEFAULTS"; then
        echo "FIFO-Stream ist bereits in SNAPSERVER_OPTS konfiguriert."
    else
        sudo sed -i "/SNAPSERVER_OPTS/ s|\"$| --stream pipe://$FIFO_PATH?name=Bluetooth&sampleformat=44100:16:2\"|" "$SNAPSERVER_DEFAULTS"
        echo "FIFO-Stream zu SNAPSERVER_OPTS hinzugefügt."
    fi
else
    echo "SNAPSERVER_OPTS=\"--stream pipe://$FIFO_PATH?name=Bluetooth&sampleformat=44100:16:2\"" | sudo tee -a "$SNAPSERVER_DEFAULTS"
    echo "SNAPSERVER_OPTS hinzugefügt."
fi

# Snapserver neu starten
echo "Starte Snapserver neu..."
sudo systemctl restart snapserver && echo "Snapserver erfolgreich neu gestartet."

echo "Setup abgeschlossen. Bluetooth-Audio wird ins FIFO geleitet."
