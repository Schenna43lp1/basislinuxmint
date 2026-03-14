export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
git
docker
sudo
history
)

source $ZSH/oh-my-zsh.sh

# Aliases laden
source ~/.aliases

# Starship prompt
eval "$(starship init zsh)"
