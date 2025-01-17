#!/bin/bash
# Script: install.sh
# Beschreibung:
# Dieses Skript aktualisiert den Raspberry Pi, indem es die Paketlisten aktualisiert und alle Pakete auf den neuesten Stand bringt.
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

# Ausgabe eines Headers
echo "========================================"
echo " Raspberry Pi: System aktualisieren "
echo "========================================"

# Aktualisierung der Paketlisten
echo "[INFO] Aktualisiere Paketlisten..."
sudo apt update

# Upgrade der Pakete
echo "[INFO] Aktualisiere installierte Pakete..."
sudo apt upgrade -y

# Optional: Veraltete Pakete entfernen
echo "[INFO] Entferne veraltete Pakete..."
sudo apt autoremove -y

# Abschlussmeldung
echo "[INFO] Raspberry Pi wurde erfolgreich aktualisiert."
