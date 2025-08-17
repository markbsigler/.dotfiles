# ~/.zshenv - Environment variables for all shells

# CRITICAL: Set prompt options early for Terminal.app compatibility
# Terminal.app starts login shells that need this set before .zshrc
setopt PROMPT_SUBST 2>/dev/null || true
setopt PROMPT_PERCENT 2>/dev/null || true

# XDG Base Directory specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Zsh configuration directory (point to actual dotfiles location)
export ZDOTDIR="$HOME/.dotfiles/config/zsh"

# Ensure ~/.local/bin is in PATH for user-installed tools
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Rust environment (if installed)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
