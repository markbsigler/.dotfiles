# ~/.config/zsh/exports.zsh - Environment variables

# Default editor - cross-platform preference
if command -v code &> /dev/null; then
    export EDITOR="code --wait"
    export VISUAL="code --wait"
elif command -v nvim &> /dev/null; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v vim &> /dev/null; then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="nano"
    export VISUAL="nano"
fi

# Note: Core PATH setup is in .zprofile (loaded for login shells)
# Additional platform-specific paths for interactive shells

if is_linux; then
    # Linux-specific package system paths
    
    # Snap packages (Ubuntu/Pop!_OS/etc.)
    [[ -d "/snap/bin" ]] && export PATH="/snap/bin:$PATH"
    
    # Flatpak applications
    [[ -d "/var/lib/flatpak/exports/bin" ]] && export PATH="/var/lib/flatpak/exports/bin:$PATH"
    [[ -d "$HOME/.local/share/flatpak/exports/bin" ]] && export PATH="$HOME/.local/share/flatpak/exports/bin:$PATH"
    
    # AppImage directory (common location for portable Linux apps)
    [[ -d "$HOME/Applications" ]] && export PATH="$HOME/Applications:$PATH"
fi

# Clean up PATH (remove duplicates while preserving order)
clean_path() {
    if [ -n "$PATH" ]; then
        old_PATH=$PATH:
        PATH=
        while [ -n "$old_PATH" ]; do
            x=${old_PATH%%:*}
            case $PATH: in
                *:"$x":*) ;;
                *) PATH=$PATH:$x;;
            esac
            old_PATH=${old_PATH#*:}
        done
        PATH=${PATH#:}
        export PATH
    fi
}

# Clean PATH on load
clean_path

# Language and locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Less configuration
export LESS="-R -X -F"
export LESSHISTFILE="$XDG_DATA_HOME/less/history"

# Platform-specific environment variables
if is_macos; then
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_INSECURE_REDIRECT=1
    # export HOMEBREW_CASK_OPTS="--require-sha"
elif is_linux; then
    # Linux-specific environment
    export BROWSER="${BROWSER:-firefox}"
    # Fix for some applications not finding the correct browser
    export CHROME_EXECUTABLE="$(command -v google-chrome || command -v chromium-browser || command -v chromium)"
elif is_windows; then
    # Windows-specific environment
    export BROWSER="${BROWSER:-chrome}"
fi

# Development
export DISABLE_AUTO_TITLE="true"
export CLICOLOR=1
# GREP_OPTIONS is deprecated - color is set via aliases

# FZF configuration with fallbacks
if command -v bat &> /dev/null; then
    export FZF_DEFAULT_OPTS="--height 40% --reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {}'"
elif command -v batcat &> /dev/null; then
    export FZF_DEFAULT_OPTS="--height 40% --reverse --border --preview 'batcat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {}'"
else
    export FZF_DEFAULT_OPTS="--height 40% --reverse --border --preview 'cat {} 2>/dev/null || echo \"Directory: {}\"'"
fi

if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
elif command -v fdfind &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'  
elif command -v find &> /dev/null; then
    if is_macos; then
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*" -not -name ".DS_Store"'
    else
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/.git/*" -not -name ".DS_Store"'
    fi
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Tool-specific configurations
if command -v bat &> /dev/null; then
    export BAT_THEME="TwoDark"
elif command -v batcat &> /dev/null; then
    export BAT_THEME="TwoDark"
    # Create bat alias if only batcat is available (Ubuntu)
    [[ ! -f "$HOME/.local/bin/bat" ]] && mkdir -p "$HOME/.local/bin" && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# Ollama configuration (local LLM server)
export OLLAMA_API_BASE="http://localhost:11434"

# Go configuration (GOPATH set, PATH managed in .zprofile)
if command -v go &> /dev/null; then
    export GOPATH="$HOME/go"
fi

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Node.js
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node/repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# GPG
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# Platform-specific tweaks
if is_linux; then
    # Fix for Java applications on some Linux systems
    export _JAVA_AWT_WM_NONREPARENTING=1
    
    # Qt applications theming
    export QT_QPA_PLATFORMTHEME="gtk2"
fi
