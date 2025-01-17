import os
import paramiko
import subprocess

# Globale Variable für Git-Informationen
GIT_INFO = None

def get_ssh_credentials():
    """Liest SSH-Benutzername und Passwort aus den Umgebungsvariablen."""
    username = os.getenv("SSH_USERNAME")
    password = os.getenv("SSH_PASSWORD")
    if not username or not password:
        raise ValueError("SSH_USERNAME und SSH_PASSWORD müssen als Umgebungsvariablen gesetzt sein.")
    return username, password

def establish_ssh_connection(hostname, username, password):
    """Stellt eine SSH-Verbindung zum angegebenen Host her."""
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Automatisch unbekannte Hosts akzeptieren
    try:
        ssh.connect(hostname, username=username, password=password)
    except paramiko.ssh_exception.SSHException as e:
        raise ValueError(f"Fehler bei der Verbindung mit {hostname}: {e}")
    return ssh

def execute_command(ssh, command):
    """Führt einen Befehl auf dem Remote-System aus und gibt die Ausgabe zurück."""
    print(f"[COMMAND] {command}")
    stdin, stdout, stderr = ssh.exec_command(command)
    for line in iter(stdout.readline, ""):
        print(f"[STDOUT] {line.strip()}")
    for line in iter(stderr.readline, ""):
        print(f"[STDERR] {line.strip()}")
    stdout.channel.recv_exit_status()  # Warten, bis der Befehl abgeschlossen ist

def is_git_installed(ssh):
    """Überprüft, ob Git auf dem Remote-System installiert ist."""
    print("[INFO] Überprüfe, ob Git auf dem Raspberry Pi installiert ist...")
    stdin, stdout, stderr = ssh.exec_command("git --version")
    git_version = stdout.read().decode().strip()
    if "git version" in git_version:
        print(f"[INFO] Git ist installiert: {git_version}")
        return True, git_version
    else:
        print("[WARN] Git ist nicht installiert.")
        return False, None

def install_git(ssh):
    """Installiert Git auf dem Remote-System."""
    print("[INFO] Installiere Git auf dem Raspberry Pi...")
    execute_command(ssh, "sudo apt update && sudo apt install -y git")
    print("[INFO] Git wurde erfolgreich installiert.")

def check_and_install_git(ssh):
    """Überprüft, ob Git installiert ist, installiert es bei Bedarf und setzt Benutzername und E-Mail."""
    git_installed, git_version = is_git_installed(ssh)
    if not git_installed:
        install_git(ssh)

    print("[INFO] Konfiguriere Git-Benutzername und E-Mail auf dem Raspberry Pi...")
    if GIT_INFO:
        if GIT_INFO['user_name']:
            print(f"[SETUP] Git-Benutzername: {GIT_INFO['user_name']}")
            execute_command(ssh, f"git config --global user.name \"{GIT_INFO['user_name']}\"")
        if GIT_INFO['user_email']:
            print(f"[SETUP] Git-E-Mail: {GIT_INFO['user_email']}")
            execute_command(ssh, f"git config --global user.email \"{GIT_INFO['user_email']}\"")

def clone_or_pull_repo(ssh):
    """Klonen oder Aktualisieren eines Repositories über HTTPS und gibt den Pfad zurück."""
    repo_url = os.getenv("HOME_REPO")
    if not repo_url:
        raise ValueError("[ERROR] HOME_REPO muss als Umgebungsvariable gesetzt sein.")

    repo_name = repo_url.split("/")[-1].replace(".git", "")
    repo_path = f"./{repo_name}"
    print(f"[INFO] Überprüfe Repository: {repo_name}")

    # Prüfen, ob das Verzeichnis existiert
    stdin, stdout, stderr = ssh.exec_command(f"[ -d {repo_name} ] && echo 'exists' || echo 'not exists'")
    repo_status = stdout.read().decode().strip()

    if repo_status == "exists":
        print(f"[INFO] Repository {repo_name} gefunden. Aktualisiere mit 'git pull'...")
        execute_command(ssh, f"cd {repo_name} && git pull")
    else:
        print(f"[INFO] Repository {repo_name} nicht gefunden. Klone Repository...")
        execute_command(ssh, f"git clone {repo_url}")

    # Branch auschecken, falls Branch-Name vorhanden ist
    if GIT_INFO and GIT_INFO['branch_name']:
        branch_name = GIT_INFO['branch_name']
        print(f"[INFO] Checke Branch '{branch_name}' aus...")
        execute_command(ssh, f"cd {repo_name} && git checkout {branch_name}")
    else:
        print("[WARN] Kein Branch-Name in GIT_INFO gefunden. Es wird der Standardbranch verwendet.")

    return repo_path

def install_feature(ssh, repo_path, subdirectory):
    """Stellt sicher, dass ein Unterverzeichnis im Repository existiert, beendet script andernfalls."""
    subdirectory_path = f"{repo_path}/{subdirectory}"
    script_path = f"{subdirectory_path}/install.sh"

    print(f"[INFO] Überprüfe, ob das Unterverzeichnis '{subdirectory}' existiert...")
    # Prüfen, ob das Unterverzeichnis existiert
    stdin, stdout, stderr = ssh.exec_command(f"[ -d {subdirectory_path} ] && echo 'exists' || echo 'not exists'")
    subdirectory_status = stdout.read().decode().strip()

    if subdirectory_status == "not exists":
        print("[ERROR] Feature existiert nicht. Das Skript wird beendet.")
        raise SystemExit(1)
        
    print(f"[INFO] Feature '{subdirectory}' gefunden.")

    # Skript ausführen
    print(f"[INFO] Führe Shell-Skript aus: {script_path}")
    execute_command(ssh, f"bash {script_path}")

    return subdirectory_path

def get_git_info():
    """Ermittelt den aktuellen Branch-Namen, die URL des Repositories, den Benutzername und die E-Mail."""
    try:
        branch_name = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"], stderr=subprocess.STDOUT
        ).decode().strip()
    except subprocess.CalledProcessError:
        branch_name = None

    try:
        repo_url = subprocess.check_output(
            ["git", "config", "--get", "remote.origin.url"], stderr=subprocess.STDOUT
        ).decode().strip()
    except subprocess.CalledProcessError:
        repo_url = None

    try:
        user_name = subprocess.check_output(
            ["git", "config", "user.name"], stderr=subprocess.STDOUT
        ).decode().strip()
    except subprocess.CalledProcessError:
        user_name = None

    try:
        user_email = subprocess.check_output(
            ["git", "config", "user.email"], stderr=subprocess.STDOUT
        ).decode().strip()
    except subprocess.CalledProcessError:
        user_email = None

    return {
        "branch_name": branch_name,
        "repo_url": repo_url,
        "user_name": user_name,
        "user_email": user_email,
    }

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        raise ValueError("Bitte geben Sie die IP-Adresse und das Unterverzeichnis als Argumente an. Beispiel: python InitDevice.py 192.168.1.100 my_subdirectory")

    # Git-Informationen global speichern
    GIT_INFO = get_git_info()
    print("[INFO] Git-Informationen:")
    print(f"[INFO] Branch-Name: {GIT_INFO['branch_name']}")
    print(f"[INFO] Repository-URL: {GIT_INFO['repo_url']}")
    print(f"[INFO] Benutzername: {GIT_INFO['user_name']}")
    print(f"[INFO] E-Mail: {GIT_INFO['user_email']}")

    raspberry_pi_hostname = sys.argv[1]
    subdirectory = sys.argv[2]

    username, password = get_ssh_credentials()

    try:
        print(f"[INFO] Verbinde mit {raspberry_pi_hostname}...")
        ssh = establish_ssh_connection(raspberry_pi_hostname, username, password)
        print("[INFO] Verbindung erfolgreich hergestellt.")

        check_and_install_git(ssh)
        repo_path = clone_or_pull_repo(ssh)
        subdirectory_path = install_feature(ssh, repo_path, subdirectory)
        print(f"[INFO] Pfad zum Unterverzeichnis: {subdirectory_path}")

    except Exception as e:
        print(f"[ERROR] Fehler bei der Verbindung oder Installation: {e}")

    finally:
        if 'ssh' in locals() and ssh:
            ssh.close()
            print("[INFO] SSH-Verbindung geschlossen.")
