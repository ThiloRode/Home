import subprocess
import sys

# Prüfen, ob eine IP-Adresse übergeben wurde
if len(sys.argv) < 2:
    print("❌ Fehler: Bitte eine IP-Adresse des Raspberry Pi angeben!")
    print("✅ Beispiel: python3 configure_pi.py 192.168.1.139")
    sys.exit(1)

# IP-Adresse des Raspberry Pi
pi_ip = sys.argv[1]

# Liste der Features, die installiert werden sollen
features = [
    "Update",
    "Airplay",
    "SnapCastServer",
    "APSnapSererverConnect"
]

# Skript, das für jedes Feature aufgerufen wird
script_name = "InitDevice.py"

# Loop über alle Features und ausführen
for feature in features:
    print(f"🚀 Starte Installation von '{feature}' auf {pi_ip} ...")
    
    try:
        # InitDevice.py für das Feature ausführen
        result = subprocess.run(
            ["python3", script_name, pi_ip, feature],
            check=True,
            capture_output=True,
            text=True
        )

        # Ausgabe des Skripts anzeigen
        print(f"✅ {feature} erfolgreich installiert:\n{result.stdout}")

    except subprocess.CalledProcessError as e:
        print(f"❌ Fehler bei der Installation von {feature}:\n{e.stderr}")

print("🎉 Alle Features wurden verarbeitet!")
