#!/bin/bash
# Script: install_accesspoint.sh
# Beschreibung:
# Dieses Skript konfiguriert einen Raspberry Pi als WLAN-Access-Point ohne Internetverbindung.
# Autor: Thilo Rode

set -e  # Beende das Skript bei Fehlern

echo "========================================"
echo " Raspberry Pi Access Point Einrichtung "
echo "========================================"

# WLAN-Schnittstelle festlegen
WLAN_INTERFACE="wlan0"
SSID="RaspberryAP"
PASSPHRASE="12345678"

# Paketlisten aktualisieren
echo "[INFO] Aktualisiere Paketlisten..."
sudo apt update

# Notwendige Pakete installieren
echo "[INFO] Installiere erforderliche Pakete..."
sudo apt install -y hostapd dnsmasq

# 1️⃣ `wpa_supplicant` zuerst deaktivieren & maskieren
echo "[INFO] Deaktiviere wpa_supplicant..."
sudo systemctl stop wpa_supplicant || true
sudo systemctl disable wpa_supplicant || true
sudo systemctl mask wpa_supplicant

# 2️⃣ `dhcpcd` deaktivieren, aber erst nach `wpa_supplicant`
echo "[INFO] Deaktiviere DHCP-Client (dhcpcd)..."
sudo systemctl stop dhcpcd || true
sudo systemctl disable dhcpcd || true

# 3️⃣ Entferne vorherige WLAN-Configs erst jetzt
echo "[INFO] Entferne bestehende WLAN-Konfiguration..."
sudo rm -f /etc/wpa_supplicant/wpa_supplicant.conf

# 4️⃣ WLAN-Freigabe erst ganz am Schluss setzen
echo "[INFO] WLAN-Schnittstelle entsperren..."
sudo rfkill unblock wlan

# 5️⃣ Hostapd (Access Point) konfigurieren
echo "[INFO] Konfiguriere Hostapd..."
echo "interface=$WLAN_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSPHRASE
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" | sudo tee /etc/hostapd/hostapd.conf > /dev/null

# Hostapd-Datei anpassen
sudo sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# 6️⃣ DHCP-Server (Dnsmasq) konfigurieren
echo "[INFO] Konfiguriere Dnsmasq..."
echo "interface=$WLAN_INTERFACE
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h" | sudo tee /etc/dnsmasq.conf > /dev/null

# 7️⃣ Statische IP-Adresse für den Access Point setzen mit systemd-networkd
echo "[INFO] Setze statische IP-Adresse über systemd-networkd..."
echo "[Match]
Name=$WLAN_INTERFACE

[Network]
Address=192.168.4.1/24
DHCPServer=yes" | sudo tee /etc/systemd/network/10-wlan0.network > /dev/null

# 8️⃣ Dienste aktivieren und starten
echo "[INFO] Aktiviere und starte Hostapd, Dnsmasq und systemd-networkd..."
sudo systemctl unmask hostapd
sudo systemctl enable --now hostapd dnsmasq systemd-networkd

# 9️⃣ Neustart des Raspberry Pi
echo "[INFO] Neustart des Systems erforderlich..."
sudo reboot
