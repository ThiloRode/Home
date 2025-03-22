import json
import paho.mqtt.client as mqtt
import threading
import requests
import time


# 🛠 Konfigurationswerte
MQTT_BROKER = "192.168.1.135"
MQTT_PORT = 1883
MQTT_TOPIC_ANNOUNCE = "shellies/announce"


class MQTTClientThread(threading.Thread, mqtt.Client):
    """Thread für die MQTT-Kommunikation"""
    def __init__(self, message_queue):
        threading.Thread.__init__(self, daemon=True)  # ✅ Thread initialisieren
        mqtt.Client.__init__(self)  # ✅ MQTT Client initialisieren
        self.message_queue = message_queue
        self.on_connect = self.handle_connect
        self.on_message = self.handle_message
        self.running = True  # Flag to control the thread

    def handle_connect(self, client, userdata, flags, rc):
        """Wird ausgeführt, wenn die Verbindung zum Broker hergestellt ist."""
        print("[DEBUG] 📡 MQTT-Client verbunden")
        self.subscribe(MQTT_TOPIC_ANNOUNCE)
        self.publish("shellies/command", "announce")

    def handle_message(self, client, userdata, message):
        """Verarbeitet eingehende MQTT-Nachrichten"""
        topic = message.topic
        payload = message.payload.decode("utf-8")
        print(f"[DEBUG] 📩 Nachricht empfangen: {topic}")

        # 📡 Shelly-Geräte melden sich an
        if topic == MQTT_TOPIC_ANNOUNCE:
            self.process_announcement(payload)
        else:
            self.process_device_update(topic, payload)

    def process_announcement(self, payload):
        """Verarbeitet neue Geräte-Anmeldungen"""
        try:
            device_info = json.loads(payload)
            device_id = device_info.get("id")
            device_type = self.identify_device(device_info)

            if device_type != "Unbekannt":
                self.subscribe_to_device(device_id, device_type)
                self.message_queue.put({
                    "topic": "announce",
                    "device_info": device_info,
                    "type": device_type
                })
                print(f"[DEBUG] 📩 Gerät angemeldet: {device_type}")
        except json.JSONDecodeError:
            print("[DEBUG] ⚠ Fehler beim Verarbeiten der Shelly-Announce-Nachricht")

    def identify_device(self, device_info):
        """Überprüft, ob das Gerät ein Heizregler ist oder ein regulärer Shelly 1"""
        ip = device_info.get("ip")
        model = device_info.get("model")

        try:
            url = f"http://{ip}/status"
            response = requests.get(url, timeout=3)
            response.raise_for_status()
            data = response.json()

            ext_temp = data.get("ext_temperature", {})

            # Prüfen, ob ext_temperature gültige Werte hat
            has_sensor = any(
                isinstance(sensor, dict) and "tC" in sensor for sensor in ext_temp.values()
            )

            if model == "SHSW-1" and has_sensor:
                return "Heizregler"
            elif model == "SHSW-1":
                return "Shelly1"
            elif model.startswith("SHDM-"):
                return "ShellyDimmer"
            else:
                return "Unbekannt"

        except requests.RequestException:
            return "Unbekannt"


    def subscribe_to_device(self, device_id, device_type):
        """Abonniert relevante Topics für das Gerät"""
        if device_type in ["Heizregler", "Shelly1"]:
            self.subscribe(f"shellies/{device_id}/relay/0")

        if device_type == "Heizregler":
            self.subscribe(f"shellies/{device_id}/ext_temperature/0")

        if device_type == "ShellyDimmer":
            self.subscribe(f"shellies/{device_id}/light/0/status")
            self.subscribe(f"shellies/{device_id}/light/0/power")

        print(f"[DEBUG] 🔔 Abonniere Topics für {device_id} ({device_type})")

    def process_device_update(self, topic, payload):
        """Verarbeitet MQTT-Nachrichten von bekannten Geräten"""
        topic_parts = topic.split("/")
        if len(topic_parts) < 4:
            print("[DEBUG] ⚠ Unbekannte Nachricht")
            return

        device_id = topic_parts[1]
        data_type = topic_parts[2]

        if data_type == "relay": 
            message = {"topic": "relay", "device_id": device_id, "value": payload}
            self.message_queue.put(message)

        elif data_type == "ext_temperature":
            message = {"topic": "ext_temperature", "device_id": device_id, "value": payload}
            self.message_queue.put(message)

        elif data_type == "light" and topic_parts[4] == "status":

            message = {"topic": "dimmer_ison", "device_id": device_id, "value": json.loads(payload)["ison"]}
            print(message)
            self.message_queue.put(message)

            message = {"topic": "dimmer_brightness", "device_id": device_id, "value": json.loads(payload)["brightness"]}
            self.message_queue.put(message)

        elif data_type == "light" and topic_parts[4] == "power":
            message = {"topic": "dimmer_power", "device_id": device_id, "value": payload}
            self.message_queue.put(message)

    def run(self):
        """Startet die MQTT-Verbindung"""
        self.connect(MQTT_BROKER, MQTT_PORT, 60)
        print("[DEBUG] 🔄 MQTT-Client gestartet...")
        while self.running:
            self.loop()
            time.sleep(1)

    def stop(self):
        """Stops the thread."""
        self.running = False
