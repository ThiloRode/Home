#!/bin/bash
# Script: install.sh
# Beschreibung:
# Dieses Skript richtet D3V als Audiogeraet ein.
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

# Header anzeigen
echo "========================================"
echo " D3V Installation "
echo "========================================"


# 1️⃣ Finde die Card-Nummer für D3V
CARD_NUM=$(cat /proc/asound/cards | grep -i "D3V" | head -n 1 | awk '{print $1}')
CARD_NAME=$(aplay -L | grep -oP '(?<=CARD=)D3V' | head -n 1)

echo $CARD_NUM
echo $CARD_NAME

# 2️⃣ Überprüfen, ob D3V gefunden wurde

if [[ -n "$CARD_NUM" ]]; then
    echo "ADAM Audio D3V gefunden als hw:$CARD_NUM,0"
    ALSA_HW="hw:$CARD_NUM,0"
else
    echo "❌ Fehler: D3V wurde nicht gefunden!"
    exit 1
fi

# 3️⃣ Schreibe die ALSA-Konfigurationsdatei
echo "📄 Erstelle /etc/asound.conf für D3V..."
sudo bash -c "cat > /etc/asound.conf <<EOL
pcm.left_only {
    type plug
    slave.pcm \"$ALSA_HW\"
    ttable.0.0 0  # Linker Eingang (0) -> Linker Ausgang (0) AUS (Stumm)
    ttable.1.0 1  # Rechter Eingang (1) -> Linker Ausgang (0) AN

}

pcm.!default pcm.left_only
ctl.!default ctl.hw
EOL"

echo "Snapclient wird mit Default-Output konfiguriert..."
#echo 'SNAPCLIENT_OPTS="--soundcard plug:default"' | sudo tee /etc/default/snapclient
sudo echo 'SNAPCLIENT_OPTS="--soundcard left_only"' | sudo tee /etc/default/snapclient

# 4️⃣ Neustart der ALSA-Dienste
echo "🔄 Neustart von ALSA..."
sudo alsactl init
sudo systemctl restart alsa-restore.service

echo "✅ D3V wurde erfolgreich als Standard-Soundkarte mit nur linkem Kanal gesetzt!"


