from kivy.app import App
from kivy.lang import Builder
from kivy.uix.boxlayout import BoxLayout
from kivy.config import Config
from home_devices import DeviceManager, Heizregler
from mqtt_client import MQTTClientThread
from queue import Queue
from MothershipWidgets import HeizreglerWidget
from threading import Thread, Lock
from kivy.clock import Clock
import time
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)

# Load the KV files
#Builder.load_file('MothershipWidgets.kv')  # Load the Heizregler widget definition

class Mothership(BoxLayout):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # Message queue for communication between threads
        self.message_queue = Queue()

        # Initialize MQTT client and DeviceManager
        self.mqtt_thread = MQTTClientThread(self.message_queue)
        self.device_manager = DeviceManager(self.message_queue, self)

        # Track added Heizregler devices and widgets
        self.added_devices = set()
        self.widget_map = {}  # Map device_id to widgets for efficient updates

        # Lock for thread safety
        self.devices_lock = Lock()

        # Start the threads
        logging.info("Starting MQTT and DeviceManager threads...")
        self.mqtt_thread.start()
        self.device_manager.start()

        # Start the GUI update thread
        self.running = True
        self.gui_update_thread = Thread(target=self.update_gui_thread, daemon=True)
        self.gui_update_thread.start()
        logging.info("GUI update thread started.")

    def update_gui_thread(self):
        """Runs in a separate thread to periodically check for new devices."""
        while self.running:
            try:
                with self.devices_lock:
                    # Check for new devices
                    for device_id, device in self.device_manager.devices.items():
                        if isinstance(device, Heizregler) and device_id not in self.added_devices:
                            logging.info("New Heizregler detected: %s. Scheduling widget addition.", device_id)
                            # Schedule the addition of the widget in the main thread
                            Clock.schedule_once(lambda dt, d=device, d_id=device_id: self.add_heizregler_widget(d, d_id))
                time.sleep(1)
            except (KeyError, AttributeError, RuntimeError) as e:
                logging.error("Error in GUI update thread: %s", e)

    def add_heizregler_widget(self, device, device_id):
        """Adds a Heizregler widget to the GUI (must run in the main thread)."""
        regler_widget = HeizreglerWidget()

        print("------------------------------Adding widget for device_id: ", device_id)

        # Verknüpfe das Widget mit der device_id
        regler_widget.device_id = device_id

        # Remove "Heizung " from the name for display
        display_name = device.name.replace("Heizung ", "")
        regler_widget.ids.name.text = display_name
        regler_widget.ids.curr_temp.text = f"{device.temperature or 'N/A'}°C"
        regler_widget.ids.set_temp.text = f"{device.set_temp or 'N/A'}°C"

        # Add the widget to the heiz_tab
        self.ids.heiz_tab.add_widget(regler_widget)

        # Track the widget and mark the device as added
        self.widget_map[device_id] = regler_widget
        self.added_devices.add(device_id)

        logging.info("Widget for Heizregler %s added to the GUI.", device_id)

        # Aktualisiere die GUI basierend auf dem aktuellen Status des Geräts
        self.update_heizregler_ui(device_id)

    def update_heizregler_ui(self, device_id):
        """Aktualisiert das UI eines Heizregler-Geräts."""
        if device_id in self.widget_map:
            widget = self.widget_map[device_id]
            device = self.device_manager.devices[device_id]

            # Runde die Temperatur und Solltemperatur auf eine Stelle nach dem Komma
            current_temp = f"{round(device.temperature, 1) if device.temperature is not None else 'N/A'}°C"
            set_temp = f"{round(device.set_temp, 1) if device.set_temp is not None else 'N/A'}°C"

            # Aktualisiere die Temperatur und Solltemperatur in der GUI
            widget.ids.curr_temp.text = current_temp
            widget.ids.set_temp.text = set_temp

            # Aktivieren/Deaktivieren des set_temp-Widgets basierend auf dem Relaisstatus
            widget.ids.set_temp.disabled = device.status == "off"

            logging.info("UI updated for Heizregler %s: Current Temp: %s, Set Temp: %s, Relay Status: %s",
                         device_id, current_temp, set_temp, device.status)

    def stop_threads(self):
        """Stops the MQTT and DeviceManager threads."""
        logging.info("Stopping all threads...")
        self.running = False  # Stop the GUI update thread
        self.mqtt_thread.stop()
        self.device_manager.stop()
        logging.info("All threads stopped.")

class MothershipApp(App):
    Config.set("graphics", "show_cursor", 1)
    Config.set("graphics", "allow_screensaver", 1)
    Config.write()

    def build(self):
        return Mothership()

    def on_stop(self):
        """Ensure threads are stopped when the app is closed."""
        self.root.stop_threads()

if __name__ == '__main__':
    MothershipApp().run()
