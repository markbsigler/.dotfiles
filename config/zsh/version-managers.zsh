# ~/.config/zsh/version-managers.zsh - Version managers (lazy loaded)

# Pyenv with cross-platform support
if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$PYENV_ROOT/bin:"* ]]; then
        export PATH="$PYENV_ROOT/bin:$PATH"
    fi
    
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# jenv (Java version manager)
if command -v jenv &> /dev/null; then
    export PATH="$HOME/.jenv/bin:$PATH"
    eval "$(jenv init -)"
fi

# rbenv (Ruby version manager) - cross-platform
if command -v rbenv &> /dev/null; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init - zsh)"
fi

# NVM (lazy loading with cross-platform support)
nvm_lazy_load() {
    unset -f nvm node npm npx
    export NVM_DIR="$HOME/.nvm"
    
    # Try multiple NVM locations based on platform and installation method
    local nvm_script=""
    local nvm_completion=""
    
    if is_macos; then
        # macOS Homebrew paths (Apple Silicon)
        if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
            nvm_script="/opt/homebrew/opt/nvm/nvm.sh"
            nvm_completion="/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
        # macOS Homebrew paths (Intel)
        elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
            nvm_script="/usr/local/opt/nvm/nvm.sh"
            nvm_completion="/usr/local/opt/nvm/etc/bash_completion.d/nvm"
        fi
    elif is_linux; then
        # Linux package manager installations
        if [[ -s "/usr/share/nvm/init-nvm.sh" ]]; then
            # Some Linux distributions install NVM here
            nvm_script="/usr/share/nvm/init-nvm.sh"
        elif [[ -s "/etc/profile.d/nvm.sh" ]]; then
            # Some system-wide installations
            nvm_script="/etc/profile.d/nvm.sh"
        fi
    fi
    
    # Standard locations (all platforms) - user installation
    if [[ -z "$nvm_script" && -s "$NVM_DIR/nvm.sh" ]]; then
        nvm_script="$NVM_DIR/nvm.sh"
        nvm_completion="$NVM_DIR/bash_completion"
    fi
    
    # Load NVM if found
    if [[ -n "$nvm_script" ]]; then
        source "$nvm_script"
        [[ -n "$nvm_completion" && -s "$nvm_completion" ]] && source "$nvm_completion"
    else
        echo "NVM not found. Install with:"
        if is_macos; then
            echo "  brew install nvm"
        else
            echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        fi
        return 1
    fi
}

# Create placeholder functions that will lazy load nvm
nvm() {
    nvm_lazy_load
    nvm "$@"
}

node() {
    nvm_lazy_load
    node "$@"
}

npm() {
    nvm_lazy_load
    npm "$@"
}

npx() {
    nvm_lazy_load
    npx "$@"
}

# fnm (Fast Node Manager) - alternative to NVM
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# Rust version manager (rustup)
if command -v rustup &> /dev/null; then
    # Ensure Rust tools are in PATH
    [[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
fi

# Go version manager (g - go version manager)
if command -v g &> /dev/null && [[ -d "$HOME/.g" ]]; then
    export GOROOT="$HOME/.g/go"
    export PATH="$GOROOT/bin:$PATH"
elif command -v go &> /dev/null; then
    # Standard Go installation
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
fi

# PHP version manager (phpenv) if available
if command -v phpenv &> /dev/null; then
    export PATH="$HOME/.phpenv/bin:$PATH"
    eval "$(phpenv init -)"
fi

# Conda/Miniconda (cross-platform)
__conda_setup="$HOME/miniconda3/bin/conda"
if [[ -f "$__conda_setup" ]]; then
    __conda_setup="$("$__conda_setup" 'shell.zsh' 'hook' 2> /dev/null)"
    if [[ $? -eq 0 ]]; then
        eval "$__conda_setup"
    else
        if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="$HOME/miniconda3/bin:$PATH"
        fi
    fi
fi
unset __conda_setup

# Anaconda (alternative location)
if [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [[ -d "$HOME/anaconda3/bin" ]]; then
    export PATH="$HOME/anaconda3/bin:$PATH"
fi

# SDK Man (cross-platform)
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Optional: Auto-switch Node versions (silent)
auto_switch_node() {
    if [[ -f .nvmrc ]]; then
        # Only load nvm if we haven't already
        if ! command -v nvm &> /dev/null; then
            nvm_lazy_load
        fi
        
        local node_version="$(nvm version 2>/dev/null)"
        local nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"
        
        if [[ -n "$nvmrc_path" ]]; then
            local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")" 2>/dev/null)
            
            if [[ "$nvmrc_node_version" != "N/A" && "$nvmrc_node_version" != "$node_version" ]]; then
                nvm use --silent 2>/dev/null || nvm use 2>/dev/null
            fi
        fi
    fi
}

# Auto-switch Python versions with pyenv
auto_switch_python() {
    if command -v pyenv &> /dev/null && [[ -f .python-version ]]; then
        local python_version="$(cat .python-version)"
        if pyenv versions --bare | grep -q "^$python_version\$"; then
            pyenv local "$python_version" 2>/dev/null
        fi
    fi
}

# Uncomment the following lines to enable auto-switching
# autoload -U add-zsh-hook
# add-zsh-hook chpwd auto_switch_node
# add-zsh-hook chpwd auto_switch_python
# auto_switch_node
# auto_switch_python

# Version manager aliases
alias nodeversions="nvm list"
alias pythonversions="pyenv versions"
alias rubyversions="rbenv versions"
alias javaversions="jenv versions"
