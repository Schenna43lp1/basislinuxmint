# Markus Linux Setup

Automatisches Setup für meine Linux-Mint-Workstation.

## Installation

```bash
git clone https://github.com/Schenna43lp1/basislinuxmint.git
cd basislinuxmint
chmod +x setup.sh
./setup.sh
```

Das Script kann gefahrlos mehrfach ausgeführt werden – bereits
installierte Komponenten werden übersprungen.

## Features

- System-Update + Basis-Pakete aus `tools.txt` (CLI-, Dev-, Netzwerk- und Monitoring-Tools)
- Docker Engine + Compose-Plugin (offizielles Docker-Repo) + Docker Desktop
- Kubernetes-Tools: kubectl, Helm, Minikube
- Desktop-Apps: VS Code, Telegram, Discord
- Gaming: Steam, Lutris, MangoHud, GameMode, OBS Studio
- Virtualisierung: KVM/QEMU, virt-manager
- ZSH + Oh My Zsh + Starship
- Custom Aliases
- Homelab-Ordnerstruktur

## Repo-Struktur

| Datei        | Zweck                                              |
| ------------ | -------------------------------------------------- |
| `setup.sh`   | Haupt-Setup-Script (modular, idempotent)           |
| `tools.txt`  | Paketliste für apt – einfach Zeilen ergänzen       |
| `aliases.sh` | Aliases → wird nach `~/.aliases` kopiert           |
| `zshrc`      | ZSH-Konfiguration → wird nach `~/.zshrc` kopiert   |

## Ordnerstruktur (Home)

```
dev/        → Coding Projekte
projects/   → Allgemeine Projekte
homelab/    → Proxmox / Infrastruktur (proxmox, docker, network, monitoring, backup, docs)
docker/     → Container Projekte
monitoring/ → Uptime / Metrics
scripts/    → Automationen
trading/    → Trading Tools
lab/        → Experimente
```

## Nach dem Setup

1. Neu einloggen (Docker-Gruppe + ZSH als Standard-Shell werden erst dann aktiv)
2. Minikube starten: `minikube start --driver=docker`
3. Testen: `docker version`, `kubectl version --client`, `helm version`
