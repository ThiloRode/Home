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

echo "Starting setup for Raspberry Pi as a Bluetooth audio adapter..."

# Update and upgrade system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing necessary packages..."
sudo apt install -y bluealsa pulseaudio-module-bluetooth pavucontrol alsa-utils bluetooth

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

# Configure Bluetooth pairing
echo "Setting up Bluetooth pairing..."
sudo bluetoothctl << EOF
power on
discoverable on
pairable on
EOF

# Optional: Enable PulseAudio system mode (if needed)
# Uncomment the following lines if you need PulseAudio in system mode
# echo "Enabling PulseAudio system-wide..."
# sudo sed -i 's/^#autospawn = yes/autospawn = no/' /etc/pulse/client.conf
# sudo systemctl restart pulseaudio

# Instructions for user
echo "Setup complete! You can now pair your Bluetooth device."
echo "Use 'bluetoothctl' to manage Bluetooth connections manually."
echo "You may need to open 'pavucontrol' to select the Bluetooth audio device as the output."

# Finish
echo "Rebooting system to apply changes..."
sudo reboot