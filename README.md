# Home Automation System

## Overview
This repository contains scripts for managing a home automation system based on a Raspberry Pi. The system integrates MQTT for communication and controls heating as well as Snapserver configuration. The key components include:
- **Device Initialization** for setting up hardware and network configurations.
- **Snapserver Configuration** for managing multi-room audio streaming.
- **MQTT Device Management** for automatic detection and control of Shelly devices.
- **Heating Control** for smart temperature regulation.

## Features
### 1. Device Initialization (`InitDevice.py`)
This script is responsible for setting up the environment and configuring the system on startup. It:
- Detects connected devices.
- Sets up initial configurations for the Raspberry Pi.
- Ensures required dependencies and services are running.

### 2. Snapserver Configuration (`SnapserverConfig.py`)
This script configures Snapserver for multi-room audio streaming. It:
- Reads and modifies Snapserver's configuration file.
- Ensures correct audio routing settings.
- Restarts Snapserver when necessary.
- Allows dynamic updates to streaming configurations.

### 3. MQTT Device Management (`mqtt_device_manager.py`)
This script manages Shelly devices using MQTT. It:
- Detects all available MQTT-enabled Shelly devices.
- Filters devices relevant to the heating system.
- Subscribes to their topics to monitor status and control them.
- Maintains a list of active devices and their states.

### 4. Heating Control (`heizungregelung.py`)
This script implements a smart heating regulation system. It:
- Reads temperature data from Shelly devices.
- Processes control logic to determine heating needs.
- Sends MQTT commands to adjust heating settings.
- Allows configurable setpoints and hysteresis control.
- Logs data for analysis and debugging.

## Prerequisites
To run this system, you need:
- **Hardware:** Raspberry Pi Zero 2 E (or similar), Shelly switches with temperature sensors.
- **Software:**
  - Python 3.9+
  - MQTT broker (e.g., Mosquitto)
  - Snapserver installed on the Raspberry Pi
  - Required Python packages (see below)

## Installation
1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd Home
   ```
2. Create a virtual environment and install dependencies:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows use: venv\Scripts\activate
   pip install -r requirements.txt
   ```

## Configuration
### MQTT Settings
Modify `config.json` (if available) to specify:
- MQTT broker IP (`192.168.1.135` by default)
- Topics for Shelly devices
- Device-specific settings (e.g., temperature thresholds)

### Snapserver Configuration
- The script modifies Snapserver’s configuration file dynamically.
- Ensure that Snapserver is installed and running before execution.

### Heating Control
- Define target temperatures and regulation parameters in `config.json`.
- Ensure that MQTT devices are detected correctly before starting regulation.

## Usage
Run individual scripts as needed:
```bash
python InitDevice.py  # Initializes the device and setup
python SnapserverConfig.py  # Configures Snapserver for audio streaming
python mqtt_device_manager.py  # Detects and manages Shelly devices
python heizungregelung.py  # Controls the heating system
```

To run everything together, consider setting up a systemd service or a startup script.

## Logging and Debugging
- Logs are written to `logs/` (if implemented) for monitoring.
- Debugging messages can be enabled by setting a debug flag in `config.json`.

## License
This project is licensed under the MIT License.

## Author
Thilo Rode

