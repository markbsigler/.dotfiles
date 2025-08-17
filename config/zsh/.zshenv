#!/usr/bin/env zsh
# .zshenv in ZDOTDIR - sourced for all zsh invocations

# XDG Base Directory specification (ensure they're set)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Ensure ZDOTDIR is set (it should be, but just in case)
export ZDOTDIR="${ZDOTDIR:-$HOME/.dotfiles/config/zsh}"

# Ensure ~/.local/bin is in PATH for user-installed tools
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Rust environment (if installed)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Create necessary directories
[[ ! -d "$XDG_DATA_HOME/zsh" ]] && mkdir -p "$XDG_DATA_HOME/zsh"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"
