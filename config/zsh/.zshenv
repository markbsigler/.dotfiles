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

# Keep the default at the path provisioned and backed up by the installer.
# An explicit ZDOTDIR override must be provisioned separately.
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

if [[ "${DOTFILES_ZPROF:-}" == 1 ]]; then
	zmodload zsh/zprof
fi

# Clear guard flags inherited from parent shells so startup files still run
unset ZPROFILE_LOADED
unset ZSHRC_LOADED

# Set up history location (XDG compliant)
export HISTFILE="$XDG_DATA_HOME/zsh/history"
