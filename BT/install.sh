#!/bin/bash
# Script: installt.sh
# Description: Installs Bluetooth and related packages on a Raspberry Pi
# Author: Thilo Rode

set -e  # Exit on error

# Set environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive

# Header
echo "========================================"
echo " Bluetooth Installation "
echo "========================================"

install_bluetooth() {
    echo "Updating package lists..."
    sudo apt-get update

    echo "Installing Bluetooth tools and dependencies..."
    sudo apt-get -o Dpkg::Options::="--force-confdef" \
                 -o Dpkg::Options::="--force-confold" \
                 install -y bluez-tools bluez-alsa-utils pulseaudio pulseaudio-module-bluetooth

    echo "Configuring Bluetooth settings..."
    sudo tee /etc/bluetooth/main.conf >/dev/null <<'EOF'
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF

    echo "Setting up Bluetooth agent..."
    sudo tee /etc/systemd/system/bt-agent@.service >/dev/null <<'EOF'
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStartPre=/usr/bin/bluetoothctl discoverable on
ExecStartPre=/bin/hciconfig %I piscan
ExecStartPre=/bin/hciconfig %I sspmode 1
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable bt-agent@hci0.service

    echo "Creating udev rules for Bluetooth..."
    sudo tee /usr/local/bin/bluetooth-udev >/dev/null <<'EOF'
#!/bin/bash
if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

if [ "$action" = "add" ]; then
    bluetoothctl discoverable off
elif [ "$action" = "remove" ]; then
    bluetoothctl discoverable on
fi
EOF
    sudo chmod 755 /usr/local/bin/bluetooth-udev

    sudo tee /etc/udev/rules.d/99-bluetooth-udev.rules >/dev/null <<'EOF'
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluetooth-udev"
EOF
}

echo "Starting installation..."
install_bluetooth


sudo systemctl restart bluetooth
pulseaudio --kill && pulseaudio --start

