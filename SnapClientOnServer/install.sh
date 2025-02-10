#!/bin/bash
# Script: install_local_snapclient.sh
# Beschreibung:
# Dieses Skript installiert den Snapcast-Client (Snapclient) und verbindet ihn explizit mit dem lokalen Snapserver.
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

# Header anzeigen
echo "========================================"
echo " Lokaler Snapcast-Client Installation "
echo "========================================"

# Update und Installation von Snapclient
echo "[INFO] Aktualisiere Paketlisten und installiere Snapclient..."
sudo apt update
sudo apt install -y snapclient

# Snapclient mit lokalem Snapserver verbinden
CONFIG_FILE="/etc/default/snapclient"
BACKUP_FILE="/etc/default/snapclient.bak"

# Backup der Datei erstellen (nur einmal, falls noch nicht vorhanden)
if [ ! -f "$BACKUP_FILE" ]; then
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "✅ Backup der Konfigurationsdatei erstellt."
fi

# Lokalen Snapserver als Host setzen
echo "[INFO] Konfiguriere Snapclient für lokalen Snapserver..."
echo 'SNAPCLIENT_OPTS="-h 127.0.0.1"' | sudo tee "$CONFIG_FILE" > /dev/null

# Snapclient-Dienst aktivieren und starten
echo "[INFO] Aktiviere und starte Snapclient..."
sudo systemctl enable --now snapclient

# Status überprüfen
echo "[INFO] Überprüfe den Snapclient-Status..."
sudo systemctl status snapclient --no-pager

echo "✅ Lokale Snapclient-Installation abgeschlossen!"
