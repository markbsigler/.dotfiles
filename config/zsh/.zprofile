#!/usr/bin/env zsh
# ~/.config/zsh/.zprofile
# =============================================================================
# Zsh profile - sourced for LOGIN shells before .zshrc
# Use for: PATH setup, environment that GUI apps need, one-time initialization
# =============================================================================

# Prevent double-loading
[[ -n "$ZPROFILE_LOADED" ]] && return
export ZPROFILE_LOADED=1

# =============================================================================
# Package Manager Setup (Platform-specific)
# =============================================================================
# These need to be set early so that tools installed via package managers
# are available to subsequent configuration files

# Detect OS for platform-specific setup
case "$(uname -s)" in
    Darwin*)
        # macOS - Homebrew setup
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon (M1/M2/M3) Macs
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            # Intel Macs
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ;;
    Linux*)
        # Linux - check for optional Homebrew installation
        # (Native package managers don't need shellenv setup)
        if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            # System-wide Homebrew on Linux
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
            # User-local Homebrew on Linux
            eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        fi
        ;;
esac

# =============================================================================
# Essential PATH Setup
# =============================================================================
# Add user-local bin directories early in PATH
# These take precedence over system binaries

# User's local bin (for user-installed tools)
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Platform-specific PATH additions
case "$(uname -s)" in
    Darwin*)
        # macOS-specific paths
        
        # GNU tools (if installed via Homebrew)
        # These override BSD versions with GNU versions
        [[ -d "/opt/homebrew/opt/coreutils/libexec/gnubin" ]] && \
            export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
        [[ -d "/opt/homebrew/opt/findutils/libexec/gnubin" ]] && \
            export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
        [[ -d "/opt/homebrew/opt/gnu-tar/libexec/gnubin" ]] && \
            export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
        [[ -d "/opt/homebrew/opt/gnu-sed/libexec/gnubin" ]] && \
            export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
        [[ -d "/opt/homebrew/opt/grep/libexec/gnubin" ]] && \
            export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
        
        # Intel Mac paths
        [[ -d "/usr/local/opt/coreutils/libexec/gnubin" ]] && \
            export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
        [[ -d "/usr/local/opt/findutils/libexec/gnubin" ]] && \
            export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
        [[ -d "/usr/local/opt/gnu-tar/libexec/gnubin" ]] && \
            export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
        ;;
    Linux*)
        # Linux-specific paths
        
        # Snap packages (Ubuntu, Pop!_OS, etc.)
        [[ -d "/snap/bin" ]] && export PATH="/snap/bin:$PATH"
        
        # Flatpak
        [[ -d "/var/lib/flatpak/exports/bin" ]] && \
            export PATH="/var/lib/flatpak/exports/bin:$PATH"
        [[ -d "$HOME/.local/share/flatpak/exports/bin" ]] && \
            export PATH="$HOME/.local/share/flatpak/exports/bin:$PATH"
        
        # AppImage directory (common location)
        [[ -d "$HOME/Applications" ]] && export PATH="$HOME/Applications:$PATH"
        ;;
esac

# =============================================================================
# Language-specific Setup
# =============================================================================
# Early initialization for language version managers and runtimes

# Rust/Cargo
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Go
if command -v go &> /dev/null; then
    export GOPATH="${GOPATH:-$HOME/go}"
    [[ -d "$GOPATH/bin" ]] && export PATH="$GOPATH/bin:$PATH"
fi

# Ruby gems (if using system ruby)
if command -v ruby &> /dev/null && command -v gem &> /dev/null; then
    # Only add if rbenv is not being used
    if [[ ! -d "$HOME/.rbenv" ]]; then
        RUBY_GEM_PATH="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)/bin"
        [[ -d "$RUBY_GEM_PATH" ]] && export PATH="$RUBY_GEM_PATH:$PATH"
    fi
fi

# Python user packages
[[ -d "$HOME/.local/lib/python3/bin" ]] && \
    export PATH="$HOME/.local/lib/python3/bin:$PATH"

# Node.js global packages (if using npm global without nvm)
[[ -d "$HOME/.npm-global/bin" ]] && export PATH="$HOME/.npm-global/bin:$PATH"

# =============================================================================
# Environment Variables for GUI Applications
# =============================================================================
# These are needed for applications launched from GUI (not just terminal)

# Default editor (in order of preference)
if command -v nvim &> /dev/null; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v vim &> /dev/null; then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="vi"
    export VISUAL="vi"
fi

# Browser (platform-specific defaults)
case "$(uname -s)" in
    Darwin*)
        # macOS - use default open command
        export BROWSER="open"
        ;;
    Linux*)
        # Linux - try to detect default browser
        if command -v xdg-open &> /dev/null; then
            export BROWSER="xdg-open"
        elif command -v firefox &> /dev/null; then
            export BROWSER="firefox"
        elif command -v chromium &> /dev/null; then
            export BROWSER="chromium"
        fi
        ;;
esac

# =============================================================================
# System-specific Tweaks
# =============================================================================

case "$(uname -s)" in
    Darwin*)
        # macOS-specific environment
        
        # Disable Homebrew analytics
        export HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_INSECURE_REDIRECT=1
        
        # Suppress last login message
        [[ -f "$HOME/.hushlogin" ]] || touch "$HOME/.hushlogin"
        ;;
    Linux*)
        # Linux-specific environment
        
        # Fix for Java applications on tiling window managers
        export _JAVA_AWT_WM_NONREPARENTING=1
        
        # Qt applications use GTK theme
        export QT_QPA_PLATFORMTHEME="gtk2"
        
        # Enable colored man pages (if not already colored by other means)
        export MANPAGER="less -R --use-color -Dd+r -Du+b"
        ;;
esac

# =============================================================================
# SSH Agent (Login shells only)
# =============================================================================
# Start ssh-agent if not already running (useful for GUI sessions)

if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -z "$SSH_AGENT_PID" ]]; then
    # Check for existing ssh-agent
    if [[ -f "$XDG_RUNTIME_DIR/ssh-agent.env" ]]; then
        source "$XDG_RUNTIME_DIR/ssh-agent.env" > /dev/null
    elif [[ -f "$HOME/.ssh-agent.env" ]]; then
        source "$HOME/.ssh-agent.env" > /dev/null
    fi
    
    # Start new ssh-agent if still not available
    if ! ps -p "$SSH_AGENT_PID" > /dev/null 2>&1; then
        eval "$(ssh-agent -s)" > /dev/null
        if [[ -d "$XDG_RUNTIME_DIR" ]]; then
            echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$XDG_RUNTIME_DIR/ssh-agent.env"
            echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$XDG_RUNTIME_DIR/ssh-agent.env"
        else
            echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$HOME/.ssh-agent.env"
            echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$HOME/.ssh-agent.env"
        fi
    fi
fi

# =============================================================================
# Local Overrides
# =============================================================================
# Load machine-specific profile settings if they exist

[[ -f "$HOME/.zprofile.local" ]] && source "$HOME/.zprofile.local"
[[ -f "$ZDOTDIR/.zprofile.local" ]] && source "$ZDOTDIR/.zprofile.local"
