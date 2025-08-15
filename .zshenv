# ~/.zshenv - Environment variables for all shells

# XDG Base Directory specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Zsh configuration directory
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Ensure ~/.local/bin is in PATH for user-installed tools
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Rust environment (if installed)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
