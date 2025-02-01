import subprocess
import sys

def run_feature_install(ip, feature):
    """
    Führt InitDevice.py mit der gegebenen IP und dem Feature aus und gibt alle Terminalausgaben in Echtzeit aus.
    
    :param ip: Die IP-Adresse des Raspberry Pi
    :param feature: Das zu installierende Feature
    """
    print(f"🚀 Starte Installation von '{feature}' auf {ip} ...")

    process = subprocess.Popen(
        ["python3", "InitDevice.py", ip, feature],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # In Echtzeit die Ausgabe des Skripts übernehmen
    for line in process.stdout:
        print(line, end="")  # Direkt ausgeben

    for line in process.stderr:
        print(line, end="")  # Fehlerausgabe ebenfalls direkt übernehmen

    # Warten, bis das Skript beendet ist
    process.wait()

    if process.returncode == 0:
        print(f"✅ Installation von '{feature}' erfolgreich abgeschlossen.")
    else:
        print(f"❌ Fehler bei der Installation von '{feature}' (Exit-Code: {process.returncode})")

# Prüfen, ob eine IP-Adresse übergeben wurde
if len(sys.argv) < 2:
    print("❌ Fehler: Bitte eine IP-Adresse des Raspberry Pi angeben!")
    print("✅ Beispiel: python3 configure_pi.py 192.168.1.139")
    sys.exit(1)

# IP-Adresse des Raspberry Pi
pi_ip = sys.argv[1]

# Liste der Features, die installiert werden sollen
features = [
    "APSnapServerConnect",
    "Feature2",
    "Feature3"
]

# Loop über alle Features und ausführen
for feature in features:
    run_feature_install(pi_ip, feature)

print("🎉 Alle Features wurden verarbeitet!")
