# ~/.config/zsh/completions.zsh - Enhanced completion settings

# Modern completion system
autoload -Uz compinit
compinit

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

# Modern CLI tools completion
if command -v kubectl &> /dev/null; then
    source <(kubectl completion zsh)
    alias k=kubectl
    compdef kubectl k
fi

if command -v gh &> /dev/null; then
    eval "$(gh completion -s zsh)"
fi

if command -v helm &> /dev/null; then
    source <(helm completion zsh)
fi

# Python/pip completion
if command -v pip &> /dev/null; then
    eval "$(pip completion --zsh)"
fi

# AWS CLI completion
if command -v aws &> /dev/null && [[ -f /opt/homebrew/bin/aws_completer ]]; then
    compdef _aws_completer aws
fi
