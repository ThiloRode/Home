# README

## Projektbeschreibung
Dieses Projekt bietet ein Python-Skript (`InitDevice.py`) und ein Bash-Skript (`install.sh`), um einen Raspberry Pi über SSH zu verwalten. Es ermöglicht die Installation und Konfiguration von Git, das Klonen oder Aktualisieren eines Git-Repositorys sowie die Verwaltung von Features innerhalb des Repositorys.

### 1. Python-Skript: `InitDevice.py`
#### Funktionen:
- **SSH-Verbindung herstellen:** Verbindet sich mit einem Raspberry Pi unter Verwendung von Umgebungsvariablen für Benutzername und Passwort.
- **Git installieren und konfigurieren:** Prüft, ob Git installiert ist, installiert es bei Bedarf und konfiguriert Benutzername und E-Mail basierend auf lokalen Git-Einstellungen.
- **Repository klonen oder aktualisieren:** Klont ein Git-Repository oder führt ein `git pull` aus, falls das Repository bereits vorhanden ist.
- **Feature verwalten:** Stellt sicher, dass ein bestimmtes Feature-Verzeichnis im Repository existiert, und führt ein Skript innerhalb dieses Verzeichnisses aus.

#### Nutzung:
```bash
python3 InitDevice.py <IP-Adresse> <Feature-Name>
```
Beispiel:
```bash
python3 InitDevice.py 192.168.1.139 UpdateFeature
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
- Aktualisiert die Paketlisten des Raspberry Pi.
- Führt ein Upgrade aller installierten Pakete durch.
- Entfernt veraltete oder nicht mehr benötigte Pakete.

#### Nutzung:
```bash
bash install.sh
```

### 3. Beispielablauf
1. **SSH-Zugang einrichten:** Stellen Sie sicher, dass die Umgebungsvariablen korrekt gesetzt sind.
2. **Python-Skript ausführen:** Führen Sie `InitDevice.py` aus, um Git zu installieren, das Repository zu synchronisieren und ein spezifisches Feature zu verwalten.
3. **Bash-Skript ausführen:** Verwenden Sie `install.sh`, um das System des Raspberry Pi zu aktualisieren.

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
Bei Fragen oder Problemen wenden Sie sich bitte an den Autor. Vorschläge zur Verbesserung sind willkommen!

