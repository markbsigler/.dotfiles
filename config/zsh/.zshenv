# ~/.zshenv - Environment variables for all zsh sessions
# This file is always sourced by zsh, so it's perfect for XDG setup

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Set ZDOTDIR to use XDG
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Ensure XDG directories exist
[[ -d "$XDG_CONFIG_HOME" ]] || mkdir -p "$XDG_CONFIG_HOME"
[[ -d "$XDG_DATA_HOME" ]] || mkdir -p "$XDG_DATA_HOME"
[[ -d "$XDG_CACHE_HOME" ]] || mkdir -p "$XDG_CACHE_HOME"
[[ -d "$XDG_STATE_HOME" ]] || mkdir -p "$XDG_STATE_HOME"
[[ -d "$ZDOTDIR" ]] || mkdir -p "$ZDOTDIR"
