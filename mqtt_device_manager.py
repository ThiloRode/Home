import time
import json
import requests
import threading
import queue
import paho.mqtt.client as mqtt

# 🛠 Konfigurationswerte
MQTT_BROKER = "192.168.1.135"
MQTT_PORT = 1883
MQTT_TOPIC_ANNOUNCE = "shellies/announce"


class MQTTClientThread(threading.Thread):
    """Thread für die MQTT-Kommunikation"""
    def __init__(self, message_queue):
        super().__init__(daemon=True)
        self.client = mqtt.Client()
        self.client.on_message = self.on_message
        self.message_queue = message_queue

    def on_message(self, _client, _userdata, message):
        """Wird aufgerufen, wenn eine MQTT-Nachricht empfangen wird"""
        try:
            device_info = json.loads(message.payload.decode("utf-8"))
            self.message_queue.put(device_info)
        except json.JSONDecodeError:
            print("[DEBUG] ⚠ Fehler beim Verarbeiten der Nachricht")

    def run(self):
        """Startet den MQTT-Loop"""
        self.client.connect(MQTT_BROKER, MQTT_PORT, 60)
        self.client.subscribe(MQTT_TOPIC_ANNOUNCE)
        self.client.publish("shellies/command", "announce")
        self.client.loop_forever()


class DeviceManager(threading.Thread):
    """Thread zur Verwaltung aller Geräte"""
    def __init__(self, message_queue):
        super().__init__(daemon=True)
        self.message_queue = message_queue
        self.devices = {}

    def is_thermostat(self, ip):
        """Prüft, ob ein Gerät ein Heizregler ist"""
        try:
            url = f"http://{ip}/status"
            response = requests.get(url, timeout=3)
            response.raise_for_status()
            data = response.json()
            ext_temp = data.get("ext_temperature", {})
            return any(isinstance(sensor, dict) and "tC" in sensor for sensor in ext_temp.values())
        except requests.RequestException:
            return False

    def run(self):
        """Wartet auf neue Geräte und startet sie als eigene Threads"""
        while True:
            device_info = self.message_queue.get()
            device_id = device_info.get("id")
            ip = device_info.get("ip")

            if device_id and ip and self.is_thermostat(ip):
                if device_id not in self.devices:
                    heizregler = Heizregler(device_id, ip)
                    heizregler.start()
                    self.devices[device_id] = heizregler
                    print(f"[DEBUG] 🌡 {heizregler.name} erkannt und als Heizregler gestartet")


class Heizregler(threading.Thread):
    """Thread für ein Heizregler-Gerät"""
    def __init__(self, device_id, ip):
        super().__init__(daemon=True)
        self.device_id = device_id
        self.ip = ip
        self.name = self.get_device_name()  # 🔥 Ruft den Gerätenamen über die API ab
        self.temperature = None
        self.running = True

    def get_device_name(self):
        """Fragt den Namen des Geräts über die Shelly-API ab."""
        try:
            url = f"http://{self.ip}/settings"
            response = requests.get(url, timeout=3)
            response.raise_for_status()
            data = response.json()
            return data.get("name", f"Shelly-{self.device_id}")
        except requests.RequestException:
            return f"Shelly-{self.device_id}"

    def update(self):
        """Aktualisiert Temperatur- und Statusdaten"""
        try:
            url = f"http://{self.ip}/status"
            response = requests.get(url, timeout=3)
            response.raise_for_status()
            data = response.json()
            ext_temp = data.get("ext_temperature", {})
            for sensor_data in ext_temp.values():
                if isinstance(sensor_data, dict) and "tC" in sensor_data:
                    self.temperature = float(sensor_data["tC"])
        except requests.RequestException:
            pass

    def run(self):
        """Überwacht kontinuierlich den Zustand des Geräts"""
        while self.running:
            self.update()
            print(f"[DEBUG] 🔎 {self.name} ({self.device_id}): {self.temperature}°C")
            time.sleep(10)

    def stop(self):
        """Stoppt das Gerät"""
        self.running = False
