#!/usr/bin/env zsh
# ~/.config/zsh/.zprofile
# Sourced for login shells BEFORE .zshrc
#
# Purpose: Set up PATH and environment for login shells
# This runs once per login session, not for every shell

# Prevent double-loading
[[ -n "$ZPROFILE_LOADED" ]] && return
export ZPROFILE_LOADED=1

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
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# ============================================================================
# Language-Specific Setup (Cross-Platform)
# ============================================================================

# Rust/Cargo
if [[ -d "$HOME/.cargo/bin" ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Go
if [[ -d "$HOME/go/bin" ]]; then
    export PATH="$HOME/go/bin:$PATH"
fi

# Node.js global packages (npm)
if [[ -d "$HOME/.npm-global/bin" ]]; then
    export PATH="$HOME/.npm-global/bin:$PATH"
fi

# ============================================================================
# Platform-Specific GNU Tools (macOS)
# ============================================================================

if [[ "$OSTYPE" == darwin* ]]; then
    # GNU tools take precedence over macOS BSD versions
    # These paths are only added if Homebrew installed them
    
    # GNU coreutils (ls, cat, etc.)
    [[ -d "/opt/homebrew/opt/coreutils/libexec/gnubin" ]] && \
        export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    [[ -d "/usr/local/opt/coreutils/libexec/gnubin" ]] && \
        export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    
    # GNU findutils (find, xargs, etc.)
    [[ -d "/opt/homebrew/opt/findutils/libexec/gnubin" ]] && \
        export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
    [[ -d "/usr/local/opt/findutils/libexec/gnubin" ]] && \
        export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
    
    # GNU tar
    [[ -d "/opt/homebrew/opt/gnu-tar/libexec/gnubin" ]] && \
        export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
    [[ -d "/usr/local/opt/gnu-tar/libexec/gnubin" ]] && \
        export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
    
    # GNU sed
    [[ -d "/opt/homebrew/opt/gnu-sed/libexec/gnubin" ]] && \
        export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
    [[ -d "/usr/local/opt/gnu-sed/libexec/gnubin" ]] && \
        export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# ============================================================================
# Login Shell Information (Debug)
# ============================================================================

# Uncomment for debugging login shell setup
# echo "✓ .zprofile loaded for login shell"
# echo "  OS Type: $OSTYPE"
# echo "  PATH: $PATH"
