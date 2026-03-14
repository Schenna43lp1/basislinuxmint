#!/usr/bin/env bash
set -e

echo "🚀 Starte Markus Setup..."

# Basis
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
  curl wget gpg apt-transport-https ca-certificates software-properties-common \
  git htop btop neofetch tmux zsh tree ncdu ranger tldr jq unzip zip \
  nmap tcpdump dnsutils iperf3 traceroute net-tools mtr whois \
  glances remmina virt-manager wireshark timeshift \
  qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils \
  flatpak

# Homelab-Ordner
mkdir -p ~/dev ~/projects ~/homelab ~/docker ~/monitoring ~/scripts ~/trading ~/lab
mkdir -p ~/homelab/{proxmox,docker,network,monitoring,backup,docs}

# ---------------------------
# VS Code
# ---------------------------
echo "📦 Installiere VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install -y code

# ---------------------------
# Telegram Desktop
# ---------------------------
echo "📦 Installiere Telegram Desktop..."
sudo apt install -y telegram-desktop || true

# Fallback über Flatpak, falls Paket nicht verfügbar ist
if ! command -v telegram-desktop >/dev/null 2>&1; then
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install -y flathub org.telegram.desktop
fi

# ---------------------------
# Docker Engine + Compose Plugin
# ---------------------------
echo "📦 Installiere Docker Engine..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

UBUNTU_CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-noble}")
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"

# ---------------------------
# Docker Desktop
# ---------------------------
echo "📦 Installiere Docker Desktop..."
TMP_DEB="/tmp/docker-desktop-amd64.deb"
LATEST_URL=$(curl -fsSL https://desktop.docker.com/linux/main/amd64/appcast.xml | grep -o 'https://[^"]*docker-desktop[^"]*amd64\.deb' | head -n1)

if [ -n "$LATEST_URL" ]; then
  wget -O "$TMP_DEB" "$LATEST_URL"
  sudo apt install -y "$TMP_DEB"
else
  echo "⚠️ Docker Desktop Download-URL konnte nicht automatisch gefunden werden."
  echo "   Docker Engine ist aber bereits installiert."
fi

# ---------------------------
# kubectl
# ---------------------------
echo "📦 Installiere kubectl..."
KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

# ---------------------------
# Helm
# ---------------------------
echo "📦 Installiere Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ---------------------------
# Minikube
# ---------------------------
echo "📦 Installiere Minikube..."
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

# ---------------------------
# Shell
# ---------------------------
echo "📦 Setze ZSH als Standard-Shell..."
chsh -s "$(which zsh)" "$USER" || true

# ---------------------------
# Quick aliases
# ---------------------------
cat > ~/.aliases <<'EOF'
alias update='sudo apt update && sudo apt upgrade -y'
alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias dps='docker ps'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias k='kubectl'
alias mk='minikube'
alias h='helm'
alias ports='ss -tulpen'
alias myip='curl -4 ifconfig.me && echo'
alias pve='ssh root@192.168.1.69'
EOF

if [ -f ~/.zshrc ]; then
  grep -q 'source ~/.aliases' ~/.zshrc || echo 'source ~/.aliases' >> ~/.zshrc
fi

echo ""
echo "✅ Fertig."
echo "➡️ Danach neu einloggen."
echo "➡️ Minikube mit Docker starten:"
echo "   minikube start --driver=docker"
echo "➡️ Testen:"
echo "   kubectl version --client"
echo "   helm version"
echo "   docker version"
