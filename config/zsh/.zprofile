#!/usr/bin/env zsh
# ~/.config/zsh/.zprofile
# Sourced for login shells BEFORE .zshrc
#
# Purpose: Set up PATH and environment for login shells
# This runs once per login session, not for every shell

# Prevent double-loading
[[ -n "$ZPROFILE_LOADED" ]] && return
ZPROFILE_LOADED=1

# Safe PATH helper: add only existing, non-duplicate entries (prepend)
if ! typeset -f add_to_path >/dev/null 2>&1; then
add_to_path() {
    local target="$1"
    if [[ -d "$target" && ":$PATH:" != *":$target:"* ]]; then
        PATH="$target:$PATH"
    fi
}
fi

# ============================================================================
# Package Manager Setup (Cross-Platform)
# ============================================================================

# macOS - Homebrew
if [[ "$OSTYPE" == darwin* ]]; then
    # Detect Apple Silicon vs Intel Mac
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon (M1/M2/M3) - /opt/homebrew
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        # Intel Mac - /usr/local
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
# Linux - Check for Homebrew (optional on Linux)
elif [[ "$OSTYPE" == linux* ]]; then
    # Linuxbrew installations (optional, user-installed)
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
fi

# ============================================================================
# Essential PATH Setup (Platform-Independent)
# ============================================================================

# User-local binaries (highest priority)
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/bin"

# ============================================================================
# Language-Specific Setup (Cross-Platform)
# ============================================================================

# Rust/Cargo
add_to_path "$HOME/.cargo/bin"

# Go
add_to_path "$HOME/go/bin"

# Node.js global packages (npm)
add_to_path "$HOME/.npm-global/bin"

# ============================================================================
# Platform-Specific GNU Tools (macOS)
# ============================================================================

if [[ "$OSTYPE" == darwin* ]]; then
    # GNU tools take precedence over macOS BSD versions
    # These paths are only added if Homebrew installed them
    
    # GNU coreutils (ls, cat, etc.)
    add_to_path "/opt/homebrew/opt/coreutils/libexec/gnubin"
    add_to_path "/usr/local/opt/coreutils/libexec/gnubin"
    
    # GNU findutils (find, xargs, etc.)
    add_to_path "/opt/homebrew/opt/findutils/libexec/gnubin"
    add_to_path "/usr/local/opt/findutils/libexec/gnubin"
    
    # GNU tar
    add_to_path "/opt/homebrew/opt/gnu-tar/libexec/gnubin"
    add_to_path "/usr/local/opt/gnu-tar/libexec/gnubin"
    
    # GNU sed
    add_to_path "/opt/homebrew/opt/gnu-sed/libexec/gnubin"
    add_to_path "/usr/local/opt/gnu-sed/libexec/gnubin"
fi

# ============================================================================
# Login Shell Information (Debug)
# ============================================================================

# Uncomment for debugging login shell setup
# echo "✓ .zprofile loaded for login shell"
# echo "  OS Type: $OSTYPE"
# echo "  PATH: $PATH"
