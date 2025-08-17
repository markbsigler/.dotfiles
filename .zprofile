#!/usr/bin/env zsh
# ~/.zprofile - Login shell initialization
# This file is sourced for login shells before .zshrc
# On macOS Terminal.app, login shells don't automatically source .zshrc

# Ensure .zshrc is sourced for interactive login shells
if [[ -o interactive && -z "$ZSHRC_LOADED" ]]; then
    # Source the main .zshrc from home directory
    # (ZDOTDIR points to dotfiles config location, not where .zshrc lives)
    if [[ -f "$HOME/.zshrc" ]]; then
        source "$HOME/.zshrc"
    fi
fi
