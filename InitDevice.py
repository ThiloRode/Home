import os
import paramiko

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
    print(f"Führe Befehl aus: {command}")
    stdin, stdout, stderr = ssh.exec_command(command)
    for line in iter(stdout.readline, ""):
        print(line, end="")
    for line in iter(stderr.readline, ""):
        print(line, end="")
    stdout.channel.recv_exit_status()  # Warten, bis der Befehl abgeschlossen ist

def is_git_installed(ssh):
    """Überprüft, ob Git auf dem Remote-System installiert ist."""
    stdin, stdout, stderr = ssh.exec_command("git --version")
    git_version = stdout.read().decode().strip()
    return "git version" in git_version, git_version

def install_git(ssh):
    """Installiert Git auf dem Remote-System."""
    print("Git ist nicht installiert. Installiere Git...")
    execute_command(ssh, "sudo apt install -y git")
    print("Git wurde erfolgreich installiert.")

def check_and_install_git(ssh):
    """Überprüft, ob Git installiert ist, und installiert es bei Bedarf."""
    git_installed, git_version = is_git_installed(ssh)
    if git_installed:
        print(f"Git ist installiert: {git_version}")
    else:
        install_git(ssh)

def clone_or_pull_repo(ssh):
    """Klonen oder Aktualisieren eines Repositories über HTTPS und gibt den Pfad zurück."""
    repo_url = os.getenv("HOME_REPO")
    if not repo_url:
        raise ValueError("HOME_REPO muss als Umgebungsvariable gesetzt sein.")

    repo_name = repo_url.split("/")[-1].replace(".git", "")
    repo_path = f"./{repo_name}"
    print(f"Überprüfe Repository: {repo_name}")

    # Prüfen, ob das Verzeichnis existiert
    stdin, stdout, stderr = ssh.exec_command(f"[ -d {repo_name} ] && echo 'exists' || echo 'not exists'")
    repo_status = stdout.read().decode().strip()

    if repo_status == "exists":
        print(f"Repository {repo_name} gefunden. Führe 'git pull' aus...")
        execute_command(ssh, f"cd {repo_name} && git pull")
    else:
        print(f"Repository {repo_name} nicht gefunden. Klone Repository...")
        execute_command(ssh, f"git clone {repo_url}")

    return repo_path

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        raise ValueError("Bitte geben Sie die IP-Adresse als Argument an. Beispiel: python InitDevice.py 192.168.1.100")

    raspberry_pi_hostname = sys.argv[1]

    username, password = get_ssh_credentials()

    try:
        print(f"Verbinde mit {raspberry_pi_hostname}...")
        ssh = establish_ssh_connection(raspberry_pi_hostname, username, password)
        print("Verbindung erfolgreich hergestellt.")

        check_and_install_git(ssh)
        repo_path = clone_or_pull_repo(ssh)
        print(f"Repository-Pfad: {repo_path}")

    except Exception as e:
        print(f"Fehler bei der Verbindung oder Installation: {e}")

    finally:
        if 'ssh' in locals() and ssh:
            ssh.close()
            print("SSH-Verbindung geschlossen.")
