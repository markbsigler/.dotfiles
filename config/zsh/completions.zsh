# ~/.config/zsh/completions.zsh - Enhanced completion settings
# Cross-platform zsh completion configuration

# ============================================================================
# Completion Path Setup (Platform-Specific)
# ============================================================================

# Add platform-specific completion paths to fpath (before compinit)
# These must be added before compinit is called

# macOS - Homebrew completions
if [[ "$OSTYPE" == darwin* ]]; then
    # Apple Silicon
    [[ -d "/opt/homebrew/share/zsh/site-functions" ]] && \
        fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)
    # Intel Mac
    [[ -d "/usr/local/share/zsh/site-functions" ]] && \
        fpath=("/usr/local/share/zsh/site-functions" $fpath)
fi

# Linux - System and Linuxbrew completions
if [[ "$OSTYPE" == linux* ]]; then
    # System completions
    [[ -d "/usr/share/zsh/site-functions" ]] && \
        fpath=("/usr/share/zsh/site-functions" $fpath)
    [[ -d "/usr/local/share/zsh/site-functions" ]] && \
        fpath=("/usr/local/share/zsh/site-functions" $fpath)
    # Linuxbrew (if installed)
    [[ -d "/home/linuxbrew/.linuxbrew/share/zsh/site-functions" ]] && \
        fpath=("/home/linuxbrew/.linuxbrew/share/zsh/site-functions" $fpath)
fi

# User-local completions (highest priority)
[[ -d "$HOME/.local/share/zsh/completions" ]] && \
    fpath=("$HOME/.local/share/zsh/completions" $fpath)

# ============================================================================
# Completion System Initialization
# ============================================================================

# Skip insecure directory warnings (common with Homebrew on macOS)
export ZSH_DISABLE_COMPFIX=true

# Load completion system
autoload -Uz compinit

# Cross-platform cache management
# Use XDG-compliant cache location
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
mkdir -p "$XDG_CACHE_HOME/zsh" 2>/dev/null

# Smart compinit: only rebuild once per day (performance optimization)
if [[ "$OSTYPE" == darwin* ]]; then
    # macOS stat
    if [[ -f "$ZSH_COMPDUMP" ]] && [[ $(date +'%j') == $(stat -f '%Sm' -t '%j' "$ZSH_COMPDUMP" 2>/dev/null) ]]; then
        compinit -C -d "$ZSH_COMPDUMP"
    else
        compinit -d "$ZSH_COMPDUMP"
    fi
else
    # Linux stat
    if [[ -f "$ZSH_COMPDUMP" ]] && [[ $(date +'%j') == $(stat -c '%Y' "$ZSH_COMPDUMP" 2>/dev/null | xargs -I{} date -d @{} +'%j' 2>/dev/null || echo 0) ]]; then
        compinit -C -d "$ZSH_COMPDUMP"
    else
        compinit -d "$ZSH_COMPDUMP"
    fi
fi

# Set up completion menu navigation
zstyle ':completion:*' menu select

# Set up menuselect bindings after completion is fully loaded
# This function will be called later after all completions are set up
setup_menuselect_bindings() {
    # Check if menuselect keymap is available
    if zle -la | grep -q "^menuselect"; then
        bindkey -M menuselect '^p' vi-up-line-or-history
        bindkey -M menuselect '^n' vi-down-line-or-history
        bindkey -M menuselect '^h' vi-backward-char
        bindkey -M menuselect '^l' vi-forward-char
    fi
}

# Completion styling
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

# Process completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Directory completion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

# Git completion speedup
__git_files () { 
    _wanted files expl 'local files' _files     
}

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Partial completion suggestions
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

# ============================================================================
# Completion Caching (Performance)
# ============================================================================

# Enable completion caching for faster subsequent completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# Ensure cache directory exists
mkdir -p "$XDG_CACHE_HOME/zsh/zcompcache" 2>/dev/null

# ============================================================================
# Tool-Specific Completions (Cross-Platform)
# ============================================================================

# Docker completion
if command -v docker &> /dev/null; then
    zstyle ':completion:*:*:docker:*' option-stacking yes
    zstyle ':completion:*:*:docker-*:*' option-stacking yes
fi

# SSH/SCP/Rsync hostname completion
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# ============================================================================
# Modern CLI Tools (Cross-Platform)
# ============================================================================

# Kubernetes (kubectl)
if command -v kubectl &> /dev/null; then
    source <(kubectl completion zsh) 2>/dev/null
    alias k=kubectl
    compdef kubectl k 2>/dev/null
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    eval "$(gh completion -s zsh)" 2>/dev/null
fi

# Helm (Kubernetes package manager)
if command -v helm &> /dev/null; then
    source <(helm completion zsh) 2>/dev/null
fi

# Terraform
if command -v terraform &> /dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C terraform terraform 2>/dev/null
fi

# ============================================================================
# Language-Specific Completions (Cross-Platform)
# ============================================================================

# Python/pip
if command -v pip &> /dev/null; then
    eval "$(pip completion --zsh)" 2>/dev/null
elif command -v pip3 &> /dev/null; then
    eval "$(pip3 completion --zsh)" 2>/dev/null
fi

# Rust (rustup)
if command -v rustup &> /dev/null; then
    compdef _rustup rustup 2>/dev/null
fi

# ============================================================================
# Cloud Provider CLIs (Cross-Platform)
# ============================================================================

# AWS CLI (platform-specific paths)
if command -v aws &> /dev/null; then
    # macOS Homebrew
    if [[ "$OSTYPE" == darwin* ]] && [[ -f /opt/homebrew/bin/aws_completer ]]; then
        complete -C /opt/homebrew/bin/aws_completer aws
    elif [[ "$OSTYPE" == darwin* ]] && [[ -f /usr/local/bin/aws_completer ]]; then
        complete -C /usr/local/bin/aws_completer aws
    # Linux
    elif [[ "$OSTYPE" == linux* ]] && [[ -f /usr/local/bin/aws_completer ]]; then
        complete -C /usr/local/bin/aws_completer aws
    elif [[ "$OSTYPE" == linux* ]] && [[ -f /usr/bin/aws_completer ]]; then
        complete -C /usr/bin/aws_completer aws
    fi
fi

# Google Cloud SDK
if [[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]]; then
    source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# Azure CLI
if command -v az &> /dev/null && [[ -f /etc/bash_completion.d/azure-cli ]]; then
    autoload -U +X bashcompinit && bashcompinit
    source /etc/bash_completion.d/azure-cli 2>/dev/null
fi
