#!/bin/bash
# Script: installt.sh
# Beschreibung:
# Dieses Skript installiert den Bluetooth auf einem Debian-basierten System (z. B. Raspberry Pi).
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

# Header anzeigen
echo "========================================"
echo " Bluetooth Installation "
echo "========================================"



# System aktualisieren und benötigte Pakete installieren
#echo "Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    bluez \
    pulseaudio \
    pulseaudio-module-bluetooth \
    alsa-utils

# Bluetooth-Dienst aktivieren und starten
echo "Configuring Bluetooth service..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Pulseaudio neu starten und Module laden
echo "Configuring Pulseaudio..."
pulseaudio --kill
pulseaudio --start
pactl load-module module-bluetooth-policy
pactl load-module module-bluetooth-discover

# Bluetooth-Modus konfigurieren
echo "Setting up Bluetooth in pairing mode..."
bluetoothctl <<EOF
power on
discoverable on
pairable on
agent NoInputNoOutput
default-agent
EOF

echo "Waiting for a Bluetooth device to connect..."

# Endlosschleife: Warten auf Verbindung
while true; do
    # Überprüfen, ob ein Gerät verbunden ist
    connected=$(bluetoothctl info | grep -i "Connected: yes")
    if [ ! -z "$connected" ]; then
        echo "Device connected. Setting up audio sink..."
        
        # Verbundenes Gerät ermitteln
        device=$(bluetoothctl devices | grep Device | awk '{print $2}')
        echo "Connected to device: $device"

        # Audiowiedergabe konfigurieren
        sink=$(pactl list sinks short | grep bluez_sink | awk '{print $1}')
        if [ ! -z "$sink" ]; then
            pacmd set-default-sink "$sink"
            echo "Audio sink configured. Bluetooth audio is now active."
        else
            echo "No Bluetooth sink found. Please check Pulseaudio setup."
        fi

        break
    fi
    sleep 5
done
