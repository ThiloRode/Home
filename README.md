# README

## Projektübersicht
Dieses Projekt umfasst ein Python-Skript (`InitDevice.py`) und ein Bash-Skript (`install.sh`) zur Verwaltung und Aktualisierung eines Raspberry Pi sowie zur Synchronisierung mit einem Git-Repository.

### 1. Python-Skript: `InitDevice.py`
#### Funktionen:
- **SSH-Verbindung herstellen:** Verbindet sich mit einem Raspberry Pi unter Verwendung von Umgebungsvariablen für den Benutzernamen und das Passwort.
- **Git-Installation überprüfen und konfigurieren:** Prüft, ob Git installiert ist, installiert es bei Bedarf und konfiguriert Git-Benutzernamen und E-Mail.
- **Repository klonen oder aktualisieren:** Klont ein Git-Repository oder aktualisiert es, falls es bereits vorhanden ist.
- **Unterverzeichnis verwalten:** Stellt sicher, dass ein spezifisches Unterverzeichnis im Repository existiert, und führt ein darin enthaltenes Shell-Skript aus.

#### Nutzung:
```bash
python3 InitDevice.py <IP-Adresse> <Unterverzeichnis>
```
Beispiel:
```bash
python3 InitDevice.py 192.168.1.139 my_subdirectory
```

#### Voraussetzungen:
- **Umgebungsvariablen:**
  - `SSH_USERNAME`: SSH-Benutzername
  - `SSH_PASSWORD`: SSH-Passwort
  - `HOME_REPO`: URL des Git-Repositorys

- **Python-Abhängigkeiten:**
  - `paramiko`
  - `subprocess`

### 2. Bash-Skript: `install.sh`
#### Funktionen:
- Aktualisiert die Paketlisten auf dem Raspberry Pi.
- Installiert die neuesten Versionen aller Pakete.
- Entfernt veraltete oder nicht mehr benötigte Pakete.

#### Nutzung:
```bash
bash install.sh
```

### 3. Beispielablauf
1. Führen Sie das Python-Skript aus, um den Raspberry Pi zu konfigurieren und das Repository zu synchronisieren.
2. Verwenden Sie das Bash-Skript, um das System des Raspberry Pi zu aktualisieren.

### 4. Struktur
```
.
├── InitDevice.py   # Python-Skript zur Verwaltung des Raspberry Pi
├── install.sh      # Bash-Skript zur Systemaktualisierung
└── README.md       # Dokumentation
```

### 5. Autor
Thilo Rode

---
Bitte wenden Sie sich bei Fragen oder Problemen an den Autor. Verbesserungsvorschläge sind willkommen!

