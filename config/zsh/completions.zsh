# ~/.config/zsh/completions.zsh - Enhanced completion settings
# =============================================================================
# Cross-platform zsh completion configuration
# Supports: macOS (Intel & Apple Silicon), Linux (various distros)
# =============================================================================

# =============================================================================
# Completion Path Setup (Platform-specific)
# =============================================================================
# Add completion directories to fpath before initializing completion system

case "$(uname -s)" in
    Darwin*)
        # macOS - Homebrew completions
        if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
            # Apple Silicon
            fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)
        fi
        if [[ -d "/usr/local/share/zsh/site-functions" ]]; then
            # Intel Mac
            fpath=("/usr/local/share/zsh/site-functions" $fpath)
        fi
        ;;
    Linux*)
        # Linux - various package manager completion directories
        
        # Homebrew on Linux (if installed)
        if [[ -d "/home/linuxbrew/.linuxbrew/share/zsh/site-functions" ]]; then
            fpath=("/home/linuxbrew/.linuxbrew/share/zsh/site-functions" $fpath)
        fi
        
        # System-wide zsh completions (common on Debian/Ubuntu)
        if [[ -d "/usr/share/zsh/site-functions" ]]; then
            fpath=("/usr/share/zsh/site-functions" $fpath)
        fi
        
        # Fedora/RHEL/CentOS
        if [[ -d "/usr/share/zsh/$ZSH_VERSION/functions" ]]; then
            fpath=("/usr/share/zsh/$ZSH_VERSION/functions" $fpath)
        fi
        ;;
esac

# User-local completions (custom completions)
if [[ -d "$ZDOTDIR/completions" ]]; then
    fpath=("$ZDOTDIR/completions" $fpath)
fi
if [[ -d "$HOME/.zsh/completions" ]]; then
    fpath=("$HOME/.zsh/completions" $fpath)
fi

# =============================================================================
# Completion System Initialization
# =============================================================================

# Skip insecure directory warnings (useful when using mixed permissions)
export ZSH_DISABLE_COMPFIX=true

# Load completion system
autoload -Uz compinit

# Smart completion cache (only rebuild once per day)
# This significantly improves startup time
typeset -i updated_at

case "$(uname -s)" in
    Darwin*)
        # macOS stat
        updated_at=$(stat -f '%Sm' -t '%j' "$XDG_CACHE_HOME/zsh/zcompdump" 2>/dev/null || echo 0)
        ;;
    Linux*)
        # GNU stat (Linux)
        if stat --version &>/dev/null 2>&1; then
            # GNU stat
            updated_at=$(stat -c '%Y' "$XDG_CACHE_HOME/zsh/zcompdump" 2>/dev/null | xargs -I{} date -d @{} +'%j' 2>/dev/null || echo 0)
        else
            # BSD stat (some Linux distros)
            updated_at=$(stat -f '%Sm' -t '%j' "$XDG_CACHE_HOME/zsh/zcompdump" 2>/dev/null || echo 0)
        fi
        ;;
esac

# Only rebuild completion cache if older than a day
if [[ ${updated_at} -lt $(date +'%j') ]]; then
    compinit -i -d "$XDG_CACHE_HOME/zsh/zcompdump"
else
    compinit -C -i -d "$XDG_CACHE_HOME/zsh/zcompdump"
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

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# Create cache directory if it doesn't exist
[[ ! -d "$XDG_CACHE_HOME/zsh" ]] && mkdir -p "$XDG_CACHE_HOME/zsh"

# Docker completion
if command -v docker &> /dev/null; then
    zstyle ':completion:*:*:docker:*' option-stacking yes
    zstyle ':completion:*:*:docker-*:*' option-stacking yes
fi

# SSH/SCP hostname completion
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# =============================================================================
# Tool-specific Completions (Cross-platform)
# =============================================================================
# Load completions for modern development tools if they're installed

# Kubernetes (kubectl)
if command -v kubectl &> /dev/null; then
    source <(kubectl completion zsh)
    alias k=kubectl
    compdef kubectl k
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    eval "$(gh completion -s zsh)"
fi

# Helm (Kubernetes package manager)
if command -v helm &> /dev/null; then
    source <(helm completion zsh)
fi

# Terraform
if command -v terraform &> /dev/null; then
    complete -o nospace -C terraform terraform
fi

# Python/pip completion
if command -v pip &> /dev/null; then
    eval "$(pip completion --zsh)" 2>/dev/null
fi
if command -v pip3 &> /dev/null; then
    eval "$(pip3 completion --zsh)" 2>/dev/null
fi

# Poetry (Python dependency management)
if command -v poetry &> /dev/null; then
    poetry completions zsh > "$ZDOTDIR/completions/_poetry" 2>/dev/null
fi

# Cargo (Rust package manager)
if command -v rustup &> /dev/null; then
    rustup completions zsh > "$ZDOTDIR/completions/_rustup" 2>/dev/null
    rustup completions zsh cargo > "$ZDOTDIR/completions/_cargo" 2>/dev/null
fi

# AWS CLI completion (cross-platform paths)
if command -v aws &> /dev/null; then
    # Try various possible locations for aws_completer
    for completer_path in \
        "/opt/homebrew/bin/aws_completer" \
        "/usr/local/bin/aws_completer" \
        "/usr/bin/aws_completer" \
        "$(dirname $(which aws))/aws_completer"; do
        if [[ -f "$completer_path" ]]; then
            complete -C "$completer_path" aws
            break
        fi
    done
fi

# Docker Compose (both v1 and v2)
if command -v docker-compose &> /dev/null; then
    compdef _docker-compose docker-compose
fi
if command -v docker &> /dev/null; then
    # Docker compose v2 (docker compose)
    compdef _docker docker
fi

# Vagrant
if command -v vagrant &> /dev/null; then
    compdef _vagrant vagrant
fi

# Make
if command -v make &> /dev/null; then
    compdef _make make
fi

# npm/yarn/pnpm
if command -v npm &> /dev/null; then
    compdef _npm npm
fi
if command -v yarn &> /dev/null; then
    compdef _yarn yarn
fi
if command -v pnpm &> /dev/null; then
    # pnpm completion
    [[ -f "$HOME/.config/tabtab/zsh/__tabtab.zsh" ]] && source "$HOME/.config/tabtab/zsh/__tabtab.zsh"
fi

# Git (enhanced)
compdef _git git
compdef _git g  # if you use 'g' as git alias
