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


# Installation der benötigten Pakete
echo "Installing required packages..."
sudo apt install -y \
    bluez \
    pulseaudio \
    pulseaudio-module-bluetooth \
    python3-pip \
    python3-dbus \
    dbus \
    alsa-utils

# Bluetooth-Dienste aktivieren
echo "Enabling and starting Bluetooth service..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Pulseaudio Bluetooth-Modul aktivieren
echo "Loading Pulseaudio Bluetooth module..."
pactl load-module module-bluetooth-discover

# Konfiguration von Pulseaudio für Bluetooth-Audio
echo "Configuring Pulseaudio for Bluetooth audio..."
cat <<EOF | sudo tee /etc/pulse/default.pa > /dev/null
### Load Bluetooth modules
load-module module-bluetooth-policy
load-module module-bluetooth-discover
EOF

# Neuladen von Pulseaudio
echo "Restarting Pulseaudio..."
pulseaudio --kill
pulseaudio --start

# Pairing-Modus für Bluetooth aktivieren
echo "Configuring Bluetooth in pairable mode..."
sudo bluetoothctl <<EOF
power on
discoverable on
pairable on
agent on
default-agent
EOF

# Hinweis für den Benutzer
echo "Setup complete. Your Raspberry Pi is now a Bluetooth receiver."
echo "You can pair devices by searching for your Raspberry Pi in the Bluetooth settings of your device."

# The MAC address of the target Bluetooth device
TARGET_DEVICE_MAC="7C:96:D2:A0:AF:6F"
RETRY_INTERVAL=5  # Time in seconds to wait between connection attempts

echo "Waiting to connect to Bluetooth device with MAC address '$TARGET_DEVICE_MAC'..."

while true; do
  # Check if the device is already paired
  PAIRING_STATUS=$(bluetoothctl info "$TARGET_DEVICE_MAC" | grep "Connected: yes")

  if [ -n "$PAIRING_STATUS" ]; then
    echo "Device '$TARGET_DEVICE_MAC' is already connected."
    break
  else
    echo "Attempting to connect to device '$TARGET_DEVICE_MAC'..."
    
    # Attempt to connect to the device
    bluetoothctl connect "$TARGET_DEVICE_MAC"
    
    if [ $? -eq 0 ]; then
      echo "Successfully connected to '$TARGET_DEVICE_MAC'."
      break
    else
      echo "Failed to connect. Retrying in $RETRY_INTERVAL seconds..."
    fi
  fi

  # Wait for the retry interval before attempting again
  sleep "$RETRY_INTERVAL"
done