# ~/.config/zsh/.zshenv
# =============================================================================
# Zsh environment file - sourced on ALL zsh invocations
# This file must be lightweight and cross-platform compatible
# =============================================================================

# XDG Base Directory Specification
# These directories provide a standard way to organize user files
# Reference: https://specifications.freedesktop.org/basedir-spec/latest/
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Set ZDOTDIR to keep zsh config in XDG-compliant location
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Ensure critical directories exist
# Create them silently to avoid noise on every shell invocation
mkdir -p "$XDG_DATA_HOME/zsh" "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME" 2>/dev/null

# Set history file location (XDG-compliant)
export HISTFILE="$XDG_DATA_HOME/zsh/history"

# Ensure history file directory exists
mkdir -p "$(dirname "$HISTFILE")" 2>/dev/null

# Set up XDG-compliant locations for common tools
# These help keep $HOME clean by directing tools to XDG directories

# Less
export LESSHISTFILE="$XDG_DATA_HOME/less/history"
mkdir -p "$XDG_DATA_HOME/less" 2>/dev/null

# Wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# Readline
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# npm
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node/repl_history"

# GnuPG
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# Cross-platform TMPDIR setup
# macOS and Linux handle temp directories differently
if [[ -z "$TMPDIR" ]]; then
    # Set a sensible default if not already set
    if [[ -d "$HOME/tmp" ]]; then
        export TMPDIR="$HOME/tmp"
    elif [[ -d "/tmp" ]]; then
        export TMPDIR="/tmp"
    fi
fi

# Ensure TMPDIR exists and is writable
if [[ -n "$TMPDIR" ]] && [[ ! -d "$TMPDIR" ]]; then
    mkdir -p "$TMPDIR" 2>/dev/null || export TMPDIR="/tmp"
fi
