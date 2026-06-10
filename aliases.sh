# ===== System =====
alias update="sudo apt update && sudo apt upgrade -y"
alias install="sudo apt install"

# ===== Navigation =====
alias ..="cd .."
alias ...="cd ../.."

# ===== Dateien =====
alias ll="ls -lah"
alias tree="tree -L 2"

# Ubuntu/Mint installieren bat und fd unter anderen Namen
command -v batcat >/dev/null 2>&1 && alias bat="batcat"
command -v fdfind >/dev/null 2>&1 && alias fd="fdfind"

# ===== Disk & Monitoring =====
alias disk="ncdu /"
alias cpu="htop"
alias ram="free -h"

# ===== Docker =====
alias dps="docker ps"
alias dcu="docker compose up -d"
alias dcd="docker compose down"

# ===== Kubernetes =====
alias k="kubectl"
alias mk="minikube"
alias h="helm"

# ===== Netzwerk =====
alias ports="ss -tulpen"
alias myip="curl -4 ifconfig.me && echo"

# ===== Git =====
alias gs="git status"
alias gp="git pull"
alias gcm="git commit -m"

# ===== Homelab =====
alias pve="ssh root@192.168.1.69"
