#!/usr/bin/env bash
#
# ============================================================
#  Markus Linux Mint Setup
#
#  Installiert Basis-Pakete (tools.txt), Docker, Kubernetes-
#  Tools, Desktop-Apps und richtet ZSH + Aliases + Homelab-
#  Ordnerstruktur ein.
#
#  Verwendung:   ./setup.sh
#  Re-Runs sind sicher: bereits Installiertes wird übersprungen.
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Helfer & Logging
# ------------------------------------------------------------
if [[ -t 1 ]]; then
  C_BLUE=$'\e[1;34m'; C_GREEN=$'\e[1;32m'; C_YELLOW=$'\e[1;33m'; C_RED=$'\e[1;31m'; C_RESET=$'\e[0m'
else
  C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_RESET=""
fi

log()   { echo "${C_BLUE}==>${C_RESET} $*"; }
ok()    { echo "${C_GREEN} ✔${C_RESET} $*"; }
warn()  { echo "${C_YELLOW} ⚠${C_RESET} $*"; }
error() { echo "${C_RED} ✖${C_RESET} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
export DEBIAN_FRONTEND=noninteractive

trap 'rm -rf "$TMP_DIR"' EXIT
trap 'error "Fehler in Zeile $LINENO – Setup abgebrochen."' ERR

require_not_root() {
  if [[ $EUID -eq 0 ]]; then
    error "Bitte nicht als root ausführen – das Script nutzt sudo, wo nötig."
    exit 1
  fi
}

require_amd64() {
  local arch
  arch="$(dpkg --print-architecture)"
  if [[ "$arch" != "amd64" ]]; then
    error "Dieses Script unterstützt nur amd64 (gefunden: $arch)."
    exit 1
  fi
}

# ------------------------------------------------------------
# System & Basis-Pakete
# ------------------------------------------------------------
system_update() {
  log "System aktualisieren..."
  sudo apt-get update
  sudo apt-get upgrade -y
}

# Liest tools.txt (Kommentare/Leerzeilen erlaubt), installiert alle
# verfügbaren Pakete und überspringt nicht verfügbare mit Warnung,
# statt das ganze Setup abzubrechen.
install_base_packages() {
  log "Basis-Pakete aus tools.txt installieren..."
  local line pkg
  local available=() missing=()

  while IFS= read -r line; do
    pkg="${line%%#*}"
    pkg="${pkg//[[:space:]]/}"
    [[ -z "$pkg" ]] && continue
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done < "$SCRIPT_DIR/tools.txt"

  if [[ ${#available[@]} -gt 0 ]]; then
    sudo apt-get install -y "${available[@]}"
    ok "${#available[@]} Pakete installiert."
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Nicht in den Paketquellen gefunden (übersprungen): ${missing[*]}"
  fi
}

setup_flatpak() {
  log "Flathub-Remote einrichten..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

create_directories() {
  log "Homelab-Ordnerstruktur anlegen..."
  mkdir -p ~/dev ~/projects ~/docker ~/monitoring ~/scripts ~/trading ~/lab
  mkdir -p ~/homelab/{proxmox,docker,network,monitoring,backup,docs}
}

# ------------------------------------------------------------
# Desktop-Apps
# ------------------------------------------------------------
install_vscode() {
  if command -v code >/dev/null 2>&1; then
    ok "VS Code ist bereits installiert."
    return
  fi
  log "VS Code installieren..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$TMP_DIR/microsoft.gpg"
  sudo install -D -o root -g root -m 644 "$TMP_DIR/microsoft.gpg" /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y code
}

install_telegram() {
  log "Telegram Desktop installieren..."
  if sudo apt-get install -y telegram-desktop 2>/dev/null; then
    return
  fi
  warn "telegram-desktop nicht über apt verfügbar – nutze Flatpak."
  flatpak install -y flathub org.telegram.desktop
}

install_discord() {
  if command -v discord >/dev/null 2>&1; then
    ok "Discord ist bereits installiert."
    return
  fi
  log "Discord installieren..."
  wget -qO "$TMP_DIR/discord.deb" "https://discord.com/api/download?platform=linux&format=deb"
  sudo apt-get install -y "$TMP_DIR/discord.deb"
}

# ------------------------------------------------------------
# Docker
# ------------------------------------------------------------
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    ok "Docker ist bereits installiert."
    return
  fi
  log "Docker Engine + Compose-Plugin installieren..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # Mint basiert auf Ubuntu → Ubuntu-Codename für das Docker-Repo verwenden
  local codename
  # shellcheck disable=SC1091
  codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"
  if [[ -z "$codename" ]]; then
    error "Ubuntu-Codename konnte nicht aus /etc/os-release ermittelt werden."
    return 1
  fi

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_desktop() {
  if [[ -d /opt/docker-desktop ]]; then
    ok "Docker Desktop ist bereits installiert."
    return
  fi
  log "Docker Desktop installieren..."
  local url
  url="$(curl -fsSL https://desktop.docker.com/linux/main/amd64/appcast.xml \
    | grep -o 'https://[^"]*docker-desktop[^"]*amd64\.deb' | head -n1 || true)"

  if [[ -z "$url" ]]; then
    warn "Docker-Desktop-URL nicht gefunden – überspringe (Docker Engine ist installiert)."
    return
  fi
  wget -qO "$TMP_DIR/docker-desktop.deb" "$url"
  sudo apt-get install -y "$TMP_DIR/docker-desktop.deb"
}

# ------------------------------------------------------------
# Kubernetes-Tools
# ------------------------------------------------------------
install_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    ok "kubectl ist bereits installiert."
    return
  fi
  log "kubectl installieren..."
  local version
  version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o "$TMP_DIR/kubectl" "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl"
  curl -fsSL -o "$TMP_DIR/kubectl.sha256" "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl.sha256"
  (cd "$TMP_DIR" && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check --quiet)
  sudo install -o root -g root -m 0755 "$TMP_DIR/kubectl" /usr/local/bin/kubectl
}

install_helm() {
  if command -v helm >/dev/null 2>&1; then
    ok "Helm ist bereits installiert."
    return
  fi
  log "Helm installieren..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

install_minikube() {
  if command -v minikube >/dev/null 2>&1; then
    ok "Minikube ist bereits installiert."
    return
  fi
  log "Minikube installieren..."
  curl -fsSL -o "$TMP_DIR/minikube" https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
  sudo install -o root -g root -m 0755 "$TMP_DIR/minikube" /usr/local/bin/minikube
}

# ------------------------------------------------------------
# Benutzer & Shell
# ------------------------------------------------------------
setup_groups() {
  log "Benutzer zu Gruppen hinzufügen (docker, libvirt, kvm)..."
  local grp
  for grp in docker libvirt kvm; do
    if getent group "$grp" >/dev/null; then
      sudo usermod -aG "$grp" "$USER"
    fi
  done
}

setup_shell() {
  log "ZSH, Oh My Zsh und Starship einrichten..."

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  if ! command -v starship >/dev/null 2>&1; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  fi

  # Konfiguration aus dem Repo übernehmen
  cp "$SCRIPT_DIR/aliases.sh" ~/.aliases
  cp "$SCRIPT_DIR/zshrc" ~/.zshrc

  # ZSH als Standard-Shell setzen
  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
  fi
}

print_summary() {
  echo
  ok "Setup abgeschlossen!"
  echo
  echo "Nächste Schritte:"
  echo "  1. Neu einloggen (Gruppen + Standard-Shell werden erst dann aktiv)"
  echo "  2. Minikube starten:  minikube start --driver=docker"
  echo "  3. Testen:            docker version / kubectl version --client / helm version"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
main() {
  echo "🚀 Markus Linux Setup startet..."
  require_not_root
  require_amd64

  system_update
  install_base_packages
  setup_flatpak
  create_directories

  install_vscode
  install_telegram
  install_discord

  install_docker
  install_docker_desktop
  install_kubectl
  install_helm
  install_minikube

  setup_groups
  setup_shell
  print_summary
}

main "$@"
