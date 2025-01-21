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

#!/bin/bash

# Bluetooth-Pakete installieren
sudo apt install -y \
    bluez \
    pulseaudio \
    pulseaudio-module-bluetooth \
    alsa-utils

# Bluetooth-Dienste aktivieren und konfigurieren
echo "Configuring Bluetooth..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Pulseaudio Bluetooth-Modul aktivieren
echo "Loading Pulseaudio Bluetooth modules..."
pactl load-module module-bluetooth-policy
pactl load-module module-bluetooth-discover

# Bluetooth-Modus einstellen
echo "Setting up Bluetooth pairing mode..."
bluetoothctl <<EOF
power on
discoverable on
pairable on
agent NoInputNoOutput
default-agent
EOF

echo "Bluetooth is now discoverable and pairable. Waiting for a device to connect..."

# Warten auf Verbindung eines Geräts
while true; do
    connected=$(bluetoothctl info | grep -i "Connected: yes")
    if [ ! -z "$connected" ]; then
        echo "Device connected. Setting up as audio sink..."
        
        # Standard-Audioausgabe konfigurieren
        device=$(bluetoothctl devices | grep Device | awk '{print $2}')
        sink=$(pactl list sinks short | grep bluez_sink | awk '{print $1}')
        
        if [ ! -z "$sink" ]; then
            pacmd set-default-sink "$sink"
            echo "Audio sink set for device $device."
            echo "Bluetooth audio is now active. Enjoy streaming!"
        else
            echo "No Bluetooth sink found. Please check your Pulseaudio setup."
        fi

        break
    fi
    sleep 5
done
