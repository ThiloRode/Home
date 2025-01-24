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

# Script to set up Raspberry Pi as a Bluetooth audio adapter using PulseAudio

echo "Starting setup for Raspberry Pi as a Bluetooth audio adapter..."

# Update and upgrade system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
sudo apt install -y pulseaudio pulseaudio-module-bluetooth pavucontrol alsa-utils bluetooth bluez-tools

# Enable and start Bluetooth service
echo "Enabling and starting Bluetooth service..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Configure PulseAudio for Bluetooth
echo "Configuring PulseAudio..."
PA_CONFIG="/etc/pulse/default.pa"
if ! grep -q "load-module module-bluetooth-discover" "$PA_CONFIG"; then
    echo "Adding Bluetooth discover module to PulseAudio configuration..."
    echo "load-module module-bluetooth-discover" | sudo tee -a "$PA_CONFIG"
else
    echo "Bluetooth module already configured in PulseAudio."
fi

# Restart PulseAudio
echo "Restarting PulseAudio..."
pulseaudio --kill
pulseaudio --start

# Set up Bluetooth pairing
echo "Setting up Bluetooth pairing..."
sudo bluetoothctl << EOF
power on
discoverable on
pairable on
agent on
default-agent
EOF

# Instructions for user
echo "Setup complete!"
echo "1. Use 'bluetoothctl' to pair and connect your Bluetooth audio device."
echo "2. Use 'pavucontrol' to select the Bluetooth device as the default audio output."

# Optional: Reboot system
echo "Rebooting system to apply changes..."
sudo reboot
