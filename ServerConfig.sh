#!/bin/bash

# Prüfen, ob eine IP-Adresse übergeben wurde
if [ -z "$1" ]; then
    echo "❌ Fehler: Bitte eine IP-Adresse des Raspberry Pi angeben!"
    echo "✅ Beispiel: ./configure_pi.sh 192.168.1.139"
    exit 1
fi

# IP-Adresse aus Argument übernehmen
PI_IP="$1"

# Liste der Features, die installiert werden sollen
FEATURES=("Update" "Airplay" "SnapCastServer" "APSnapServerConnect")

# Loop über alle Features und ausführen
for FEATURE in "${FEATURES[@]}"; do
    echo "🚀 Starte Installation von '$FEATURE' auf $PI_IP ..."

    # Führe das Python-Skript aus und leite die Ausgabe in Echtzeit weiter
    python3 InitDevice.py "$PI_IP" "$FEATURE" 2>&1 | tee /dev/tty

    # Prüfen, ob das Skript erfolgreich war
    if [ "${PIPESTATUS[0]}" -eq 0 ]; then
        echo "✅ Installation von '$FEATURE' erfolgreich abgeschlossen."
    else
        echo "❌ Fehler bei der Installation von '$FEATURE'."
    fi
done

echo "🎉 Alle Features wurden verarbeitet!"
