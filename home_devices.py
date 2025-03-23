import logging
import threading
import time
import requests


class ShellyDevice(threading.Thread):
    """Basisklasse für alle Shelly-Geräte"""

    def __init__(self, device_id, ip):
        super().__init__(daemon=True)
        self.device_id = device_id
        self.ip = ip
        self.name = self.get_device_name()
        self.running = True
        self.mothership_callback = lambda device_id: None  # Standardfunktion

    def get_device_name(self):
        """Fragt den Gerätenamen über die Shelly-API ab"""
        try:
            url = f"http://{self.ip}/settings"
            response = requests.get(url, timeout=3)
            response.raise_for_status()
            data = response.json()
            return data.get("name", f"Shelly-{self.device_id}")
        except requests.RequestException:
            return f"Shelly-{self.device_id}"

    def stop(self):
        """Beendet den Thread"""
        self.running = False


class Shelly1(ShellyDevice):
    """Klasse für einen Shelly 1 Schalter"""

    def __init__(self, device_id, ip):
        super().__init__(device_id, ip)
        self.status = None
        self.update_status()

    def update_status(self):
        """Aktualisiert den Status des Geräts und benachrichtigt die GUI."""
        try:
            url = f"http://{self.ip}/relay/0"
            response = requests.get(url, timeout=3)
            response.raise_for_status()
            data = response.json()
            self.status = "on" if data.get("ison") else "off"
            print(f"[DEBUG] 🔄 Status von {self.name} geladen: {self.status}")
        except requests.RequestException:
            print(f"[ERROR] ❌ Konnte Status von {self.name} nicht abrufen")

        # Benachrichtige die GUI über die Statusänderung
        if hasattr(self, 'mothership_callback'):
            self.mothership_callback(self.device_id)

    def run(self):
        """Überwacht Änderungen und gibt nur Updates aus, wenn sich Werte ändern"""
        last_status = self.status
        while self.running:
            if self.status != last_status:
                print("\n")
                print(f"🔎 Shelly 1: {self.name} ({self.device_id})")
                print(f"🔁 Status: {self.status}")
                print("\n")
                last_status = self.status
            time.sleep(1)


class Heizregler(Shelly1):
    """Erweiterung für einen Shelly 1 mit Temperatursensor"""

    def __init__(self, device_id, ip):
        super().__init__(device_id, ip)
        self.temperature = None  # Aktuelle Temperatur
        self.set_temp = None  # Solltemperatur (Mittelwert)
        self.update_status()

    def update_status(self):
        """Aktualisiert den Status des Geräts und benachrichtigt die GUI."""
        try:
            # Abrufen der Statusdaten
            status_url = f"http://{self.ip}/status"
            response = requests.get(status_url, timeout=3)
            response.raise_for_status()
            status_data = response.json()

            # Temperatur auslesen
            ext_temp = status_data.get("ext_temperature", {})
            for sensor in ext_temp.values():
                if isinstance(sensor, dict) and "tC" in sensor:
                    self.temperature = float(sensor["tC"])

            # Over- und Under-temperature thresholds auslesen
            settings_url = f"http://{self.ip}/settings"
            response = requests.get(settings_url, timeout=3)
            response.raise_for_status()
            settings_data = response.json()

            ext_temp_settings = settings_data.get("ext_temperature", {})
            over_temp = None
            under_temp = None
            for sensor in ext_temp_settings.values():
                if isinstance(sensor, dict):
                    over_temp = sensor.get("overtemp_threshold_tC", None)
                    under_temp = sensor.get("undertemp_threshold_tC", None)

            if over_temp is not None and under_temp is not None:
                self.set_temp = (float(over_temp) + float(under_temp)) / 2
            else:
                self.set_temp = None

            # Relaisstatus auslesen
            self.status = "on" if status_data.get("relays", [{}])[0].get("ison") else "off"

            # Debug-Ausgabe
            print(f"[DEBUG] 🔄 Werte für {self.name} geladen: {self.temperature}°C, {self.status}, Soll: {self.set_temp}°C")
        except requests.RequestException as e:
            print(f"[ERROR] ❌ Konnte Status von {self.name} nicht abrufen: {e}")

        # Benachrichtige die GUI über die Statusänderung
        if hasattr(self, 'mothership_callback'):
            self.mothership_callback(self.device_id)

    def run(self):
        """Überwacht Änderungen und gibt nur Updates aus, wenn sich Werte ändern"""
        last_temperature = self.temperature
        last_status = self.status
        while self.running:
            if self.temperature != last_temperature or self.status != last_status:
                print("\n")
                print(f"🔎 Heizregler: {self.name} ({self.device_id})")
                print(f"🌡 Temperatur: {self.temperature}°C")
                print(f"🔥 Status: {self.status}")
                print("\n")

                last_temperature = self.temperature
                last_status = self.status

            time.sleep(1)


class ShellyDimmer(ShellyDevice):
    """Klasse für einen Shelly Dimmer"""

    def __init__(self, device_id, ip):
        super().__init__(device_id, ip)
        self.brightness = None
        self.status= None
        self.power = None
        self.update_status()

    def update_status(self):
        """Aktualisiert den Status des Geräts und benachrichtigt die GUI."""
        try:
            url = f"http://{self.ip}/light/0/status"
            response = requests.get(url, timeout=3)
            response.raise_for_status()
            data = response.json()

            self.status = "on" if data.get("ison") else "off"

            self.brightness = data.get("brightness")

            print(f"[DEBUG] 🔄 Werte für {self.name} geladen: {self.brightness}%, {self.status}")
        except requests.RequestException:
            print(f"[ERROR] ❌ Konnte Status von {self.name} nicht abrufen")

        # Benachrichtige die GUI über die Statusänderung
        if hasattr(self, 'mothership_callback'):
            self.mothership_callback(self.device_id)

    def run(self):
        """Überwacht Änderungen und gibt nur Updates aus, wenn sich Werte ändern"""
        last_brightness = self.brightness
        last_power = self.power
        last_status = self.status
        while self.running:
            if self.brightness != last_brightness or self.power != last_power or self.status != last_status:

                print("\n")
                print(f"🔎 Shelly Dimmer: {self.name} ({self.device_id})")
                print(f"💡 Helligkeit: {self.brightness}%")
                print(f"⚡ Leistung: {self.power} W")
                print(f"🔘 Status: {self.status}")
                print("\n")

                last_brightness = self.brightness
                last_power = self.power
                last_status = self.status

            time.sleep(1)


class DeviceManager(threading.Thread):
    """Thread zur Verwaltung aller Geräte"""

    def __init__(self, message_queue, mothership=None):
        super().__init__()
        self.message_queue = message_queue
        self.mothership = mothership  # Referenz zur Mothership-Instanz
        self.running = True
        self.devices = {}  # Dictionary zur Verwaltung der Geräte

    def run(self):
        """Überwacht die Geräte und verarbeitet Nachrichten aus der Queue"""
        while self.running:
            message = self.message_queue.get()

            if message["topic"] == "announce":
                self.process_announcement(message)
            elif message["topic"] in ["relay", 
                                      "ext_temperature",
                                      "dimmer_ison", 
                                      "dimmer_brightness", 
                                      "dimmer_power"]:
                self.update_device_status(message)

            # Simulate device management logic
            time.sleep(1)
            print("[DEBUG] 🔄 DeviceManager läuft...")

    def stop(self):
        """Stops the thread."""
        self.running = False

    def process_announcement(self, message):
        """Registriert neue Geräte"""
        device_type = message["type"]
        device_info = message["device_info"]
        device_id = device_info.get("id")
        ip = device_info.get("ip")

        if device_id not in self.devices:
            if device_type == "Heizregler":
                device = Heizregler(device_id, ip)
            elif device_type == "Shelly1":
                device = Shelly1(device_id, ip)
            elif device_type == "ShellyDimmer":
                device = ShellyDimmer(device_id, ip)
            else:
                logging.warning("Unbekanntes Gerät: %s", device_type)
                return

            device.start()
            self.devices[device_id] = device

            # Registriere die Mothership-Callback-Methode
            if self.mothership:
                device.mothership_callback = self.mothership.update_heizregler_ui

            logging.info("%s als %s registriert", device.name, type(device).__name__)

    def update_device_status(self, message):
        """Aktualisiert den Status eines registrierten Geräts"""
        device_id = message["device_id"]
        value = message["value"]
        topic = message["topic"]

        if device_id in self.devices:
            device = self.devices[device_id]
            if topic == "dimmer_ison":
                device.status = "on" if value else "off"
            elif topic == "dimmer_brightness":
                device.brightness = int(value)
            elif topic == "dimmer_power":
                device.power = float(value)
            elif topic == "relay":
                device.status = value
            elif topic == "ext_temperature":
                device.temperature = float(value)

            # Aufruf der update_status-Methode des Geräts
            device.update_status()

            print(f"[UPDATE] {device.name}: {topic} -> {value}")
