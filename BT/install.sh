#!/bin/bash

# Farben für Ausgabe
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Keine Farbe

echo -e "${GREEN}1. System aktualisieren und benötigte Pakete installieren...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    bluez \
    pulseaudio \
    pulseaudio-module-bluetooth \
    alsa-utils

echo -e "${GREEN}2. Bluetooth-Dienst aktivieren und starten...${NC}"
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

echo -e "${GREEN}3. Pulseaudio stoppen und Bereinigung durchführen...${NC}"
pulseaudio --kill
pkill -9 pulseaudio
rm -rf /run/pulse /var/run/pulse ~/.config/pulse
mkdir -p ~/.config/pulse
touch ~/.config/pulse/cookie
chmod 600 ~/.config/pulse/cookie

echo -e "${GREEN}4. Pulseaudio-Konfiguration aktualisieren...${NC}"
sudo sed -i '/load-module module-bluetooth-policy/d' /etc/pulse/default.pa
sudo sed -i '/load-module module-bluetooth-discover/d' /etc/pulse/default.pa
echo "load-module module-bluetooth-policy" | sudo tee -a /etc/pulse/default.pa
echo "load-module module-bluetooth-discover" | sudo tee -a /etc/pulse/default.pa

echo -e "${GREEN}5. Pulseaudio neu starten...${NC}"
pulseaudio --start

echo -e "${GREEN}6. Bluetooth-Modus konfigurieren...${NC}"
bluetoothctl <<EOF
power on
discoverable on
pairable on
agent NoInputNoOutput
default-agent
EOF

echo -e "${GREEN}7. Warten auf Bluetooth-Verbindung...${NC}"
while true; do
    connected=$(bluetoothctl info | grep -i "Connected: yes")
    if [ ! -z "$connected" ]; then
        echo -e "${GREEN}Gerät verbunden! Konfiguriere Audio-Ausgabe...${NC}"
        
        device=$(bluetoothctl devices | grep Device | awk '{print $2}')
        echo -e "${GREEN}Verbunden mit Gerät: $device${NC}"

        sink=$(pactl list sinks short | grep bluez_sink | awk '{print $1}')
        if [ ! -z "$sink" ]; then
            pacmd set-default-sink "$sink"
            echo -e "${GREEN}Audio-Sink konfiguriert. Bluetooth-Audio ist aktiv.${NC}"
        else
            echo -e "${RED}Kein Bluetooth-Audio-Sink gefunden. Überprüfe Pulseaudio-Konfiguration.${NC}"
        fi

        break
    fi
    sleep 5
done

echo -e "${GREEN}Fertig! Bluetooth-Audio sollte jetzt funktionieren.${NC}"
