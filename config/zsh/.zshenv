# ~/.config/zsh/.zshenv
# This file is sourced on ALL zsh invocations (login, interactive, non-interactive)
# It should be the first file loaded, so it sets up the foundation for everything else
#
# Purpose: Define XDG Base Directory Specification paths that other configs depend on
# These paths are used throughout the shell environment for consistent file locations

# XDG Base Directory Specification
# See: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Set ZDOTDIR to keep zsh config organized in XDG location
# This tells zsh where to find .zshrc, .zprofile, etc.
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Ensure critical directories exist (cross-platform)
# Create directories silently without error if they already exist
mkdir -p "$XDG_DATA_HOME/zsh" \
         "$XDG_CACHE_HOME/zsh" \
         "$XDG_STATE_HOME" \
         "$ZDOTDIR" 2>/dev/null || true

# Set up history location (XDG compliant)
export HISTFILE="$XDG_DATA_HOME/zsh/history"

# Ensure history directory exists
mkdir -p "$(dirname "$HISTFILE")" 2>/dev/null || true
