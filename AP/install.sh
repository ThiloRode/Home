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

# Hostapd (Access Point) konfigurieren
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

# DHCP-Server (Dnsmasq) konfigurieren
echo "[INFO] Konfiguriere Dnsmasq..."
echo "interface=$WLAN_INTERFACE
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h" | sudo tee /etc/dnsmasq.conf > /dev/null

# Statische IP-Adresse für den Access Point setzen
echo "[INFO] Setze statische IP-Adresse..."
echo "interface $WLAN_INTERFACE
static ip_address=192.168.4.1/24" | sudo tee -a /etc/dhcpcd.conf > /dev/null

# Dienste aktivieren und starten
echo "[INFO] Aktiviere und starte Hostapd und Dnsmasq..."
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
echo "[INFO] Neustart des Systems erforderlich..."
sudo reboot
