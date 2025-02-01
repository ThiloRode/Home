#!/bin/bash
# Script: install.sh
# Beschreibung:
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

echo "========================================"
echo " Shairport Sync Installation "
echo "========================================"

# Update und Installation von Shairport-Sync
sudo apt install -y shairport-sync
sudo systemctl disable --now shairport-sync