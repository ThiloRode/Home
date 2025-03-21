import queue
from mqtt_client import MQTTClientThread
from home_devices import DeviceManager
import time

if __name__ == "__main__":
    message_queue = queue.Queue()

    # Starte MQTT und Device Manager
    mqtt_thread = MQTTClientThread(message_queue)
    device_manager = DeviceManager(message_queue)

    mqtt_thread.start()
    device_manager.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[DEBUG] ❌ Beende das Programm...")
