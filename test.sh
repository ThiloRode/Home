#!/bin/bash

set -e  # Beendet das Skript bei Fehlern

echo "========================================"
echo " Shairport Sync Installation Script "
echo "========================================"

# Update und Grundpakete installieren
echo "[INFO] Aktualisiere Paketquellen und installiere Grundpakete..."
sudo apt-get update
sudo apt-get install -y git build-essential autoconf automake libtool pkg-config \
                        libpopt-dev libconfig-dev libssl-dev avahi-daemon \
                        libavahi-client-dev libasound2-dev libsoxr-dev

# Prüfen, ob xxd installiert ist
if ! command -v xxd &> /dev/null; then
  echo "[INFO] Installiere xxd..."
  sudo apt-get install -y xxd
else
  echo "[INFO] xxd ist bereits installiert."
fi

# Prüfen, ob libplist-dev installiert ist
if ! dpkg -l | grep -q libplist-dev; then
  echo "[INFO] Installiere libplist-dev..."
  sudo apt-get install -y libplist-dev || {
    echo "[WARNING] libplist-dev ist nicht verfügbar. Lade und baue die neueste Version..."
    
    # Neueste Version von libplist installieren
    echo "[INFO] Lade libplist von GitHub herunter..."
    git clone https://github.com/libimobiledevice/libplist.git
    cd libplist
    ./autogen.sh
    make
    sudo make install
    sudo ldconfig
    cd ..
    rm -rf libplist
  }
else
  echo "[INFO] libplist-dev ist bereits installiert."
fi

# Shairport Sync herunterladen und bauen
if [ ! -d "shairport-sync" ]; then
  echo "[INFO] Lade Shairport Sync von GitHub herunter..."
  git clone https://github.com/mikebrady/shairport-sync.git
else
  echo "[INFO] Verzeichnis shairport-sync existiert bereits. Aktualisiere Repository..."
  cd shairport-sync
  git pull origin master
  cd ..
fi

cd shairport-sync

echo "[INFO] Führe ./configure aus..."
sudo ./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi \
                 --with-ssl=openssl --with-systemd --with-airplay-2 \
                 --with-metadata --with-pipe --with-stdout

echo "[INFO] Kompiliere Shairport Sync..."
make

echo "[INFO] Installiere Shairport Sync..."
sudo make install

# Shairport Sync aktivieren und starten
echo "[INFO] Starte und aktiviere Shairport Sync..."
sudo systemctl enable shairport-sync
sudo systemctl start shairport-sync

# Fertigmeldung
echo "========================================"
echo " Shairport Sync wurde erfolgreich installiert!"
echo "========================================"
