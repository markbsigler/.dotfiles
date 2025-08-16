#!/usr/bin/env zsh
# Bootstrap .zshenv in ZDOTDIR to load main dotfiles configuration

# Source the main .zshenv from dotfiles
if [[ -f "$HOME/.dotfiles/.zshenv" ]]; then
    source "$HOME/.dotfiles/.zshenv"
fi
