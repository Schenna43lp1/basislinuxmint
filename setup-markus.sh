#!/bin/bash

echo "🚀 Markus Linux Setup startet..."

sudo apt update && sudo apt upgrade -y

# Tools installieren
xargs sudo apt install -y < tools.txt

# Docker Gruppe
sudo usermod -aG docker $USER

# ZSH als Default
chsh -s $(which zsh)

# Aliases kopieren
cp aliases.sh ~/.aliases

# ZSH Config kopieren
cp zshrc ~/.zshrc

# Ordnerstruktur
mkdir -p ~/dev
mkdir -p ~/projects
mkdir -p ~/homelab
mkdir -p ~/docker
mkdir -p ~/monitoring
mkdir -p ~/scripts
mkdir -p ~/trading

echo "✅ Setup abgeschlossen"
