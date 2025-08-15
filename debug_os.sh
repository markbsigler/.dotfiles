#!/usr/bin/env bash

echo "Testing os-detection..."
source config/zsh/os-detection.zsh

echo "DOTFILES_OS: $DOTFILES_OS"
echo "DOTFILES_ARCH: $DOTFILES_ARCH"

if declare -f is_macos >/dev/null; then
    echo "is_macos function exists"
    if is_macos; then
        echo "Running on macOS"
    else
        echo "Not running on macOS"
    fi
else
    echo "ERROR: is_macos function not found"
fi
