# System
alias update="sudo apt update && sudo apt upgrade -y"
alias install="sudo apt install"

# Navigation
alias ..="cd .."
alias ...="cd ../.."

# Files
alias ll="ls -lah"
alias tree="tree -L 2"

# Disk
alias disk="ncdu /"

# Monitoring
alias cpu="htop"
alias ram="free -h"

# Docker
alias dps="docker ps"
alias dcu="docker compose up -d"
alias dcd="docker compose down"

# Networking
alias myip="curl ifconfig.me"

# Git
alias gs="git status"
alias gp="git pull"
alias gcm="git commit -m"
