# ===== Oh My Zsh =====
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"

  ZSH_THEME="robbyrussell"

  plugins=(
    git
    docker
    sudo
    history
  )

  source "$ZSH/oh-my-zsh.sh"
fi

# ===== Aliases =====
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ===== Starship Prompt =====
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
