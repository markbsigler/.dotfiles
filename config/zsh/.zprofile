#!/usr/bin/env zsh
# .zprofile in ZDOTDIR - sourced for login shells

# On macOS Terminal.app, login shells need explicit .zshrc sourcing
if [[ -o interactive && -z "$ZSHRC_LOADED" ]]; then
    if [[ -f "$ZDOTDIR/.zshrc" ]]; then
        source "$ZDOTDIR/.zshrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        source "$HOME/.zshrc"
    fi
fi
