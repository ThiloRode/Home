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


# FIFO-Datei definieren
FIFO_PATH="/home/pi/fifos/pafifo"

# 1️⃣ Prüfen, ob FIFO existiert – falls nicht, erstellen
if [ ! -p "$FIFO_PATH" ]; then
    echo "📌 Erstelle FIFO-Datei: $FIFO_PATH"
    mkfifo "$FIFO_PATH"
    chmod 666 "$FIFO_PATH"
fi

# 2️⃣ PulseAudio FIFO-Sink erstellen (falls noch nicht vorhanden)
if ! pactl list sinks short | grep -q "pulseaudio_fifo"; then
    echo "🔄 Erstelle PulseAudio FIFO-Sink..."
    pactl load-module module-pipe-sink file="$FIFO_PATH" format=s16le rate=48000 channels=2 sink_name=pulseaudio_fifo
else
    echo "✅ PulseAudio FIFO-Sink existiert bereits."
fi

# 3️⃣ Setze das FIFO-Sink als Standardausgabe für PulseAudio
echo "🔄 Setze pulseaudio_fifo als Standard-Sink..."
pactl set-default-sink pulseaudio_fifo

echo "✅ Alle Audio-Ausgaben werden jetzt ins FIFO geschrieben!"




echo "Rebooting to apply changes..."


