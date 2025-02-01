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
                        libavahi-client-dev libasound2-dev libsoxr-dev \
                        cmake xxd libplist-dev

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
  sudo apt-get install -y libplist-dev
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

# Prüfen, ob CMake verwendet werden soll
if [ -f "CMakeLists.txt" ]; then
  echo "[INFO] Verwende CMake für die Konfiguration..."
  
  # Build-Verzeichnis erstellen
  mkdir -p build
  cd build

  # Konfiguration mit CMake
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONFDIR=/etc \
           -DWITH_ALSA=ON -DWITH_SOXR=ON -DWITH_AVAHI=ON \
           -DWITH_SSL=ON -DWITH_SYSTEMD=ON -DWITH_METADATA=ON \
           -DWITH_PIPE=ON -DWITH_STDOUT=ON -DWITH_AIRPLAY_2=ON

  echo "[INFO] Kompiliere Shairport Sync..."
  make

  echo "[INFO] Installiere Shairport Sync..."
  sudo make install

else
  echo "[INFO] Fallback: Prüfe, ob ./configure verwendet werden kann..."

  # Prüfen, ob configure generiert werden muss
  if [ -f "configure.ac" ]; then
    echo "[INFO] Generiere ./configure mit autoreconf..."
    autoreconf -i
  fi

  if [ -f "./configure" ]; then
    echo "[INFO] Führe ./configure aus..."
    sudo ./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi \
                     --with-ssl=openssl --with-systemd --with-airplay-2 \
                     --with-metadata --with-pipe --with-stdout

    echo "[INFO] Kompiliere Shairport Sync..."
    make

    echo "[INFO] Installiere Shairport Sync..."
    sudo make install
  else
    echo "[ERROR] Weder CMake noch ./configure verfügbar. Abbruch."
    exit 1
  fi
fi

# Shairport Sync aktivieren und starten
echo "[INFO] Starte und aktiviere Shairport Sync..."
sudo systemctl enable shairport-sync
sudo systemctl start shairport-sync

# Fertigmeldung
echo "========================================"
echo " Shairport Sync wurde erfolgreich installiert!"
echo "========================================"
