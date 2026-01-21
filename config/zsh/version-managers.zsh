# ~/.config/zsh/version-managers.zsh - Version managers

# Ensure add_to_path exists (defined in .zprofile/exports)
if ! typeset -f add_to_path >/dev/null 2>&1; then
add_to_path() {
    local target="$1"
    if [[ -d "$target" && ":$PATH:" != *":$target:"* ]]; then
        PATH="$target:$PATH"
    fi
}
fi

# Pyenv
if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    add_to_path "$PYENV_ROOT/bin"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# rbenv
if command -v rbenv &> /dev/null; then
    add_to_path "$HOME/.rbenv/bin"
    eval "$(rbenv init - zsh)"
fi

# jenv
if command -v jenv &> /dev/null; then
    add_to_path "$HOME/.jenv/bin"
    eval "$(jenv init -)"
fi

# NVM (deterministic load, no lazy wrapper)
# Choose NVM_DIR (XDG first)
if [[ -d "$HOME/.config/nvm" ]]; then
    export NVM_DIR="$HOME/.config/nvm"
else
    export NVM_DIR="$HOME/.nvm"
fi

# Homebrew/system locations take precedence if present
if [[ -z "${NVM_SCRIPT:-}" && -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    NVM_SCRIPT="/opt/homebrew/opt/nvm/nvm.sh"
    NVM_COMPLETION="/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -z "${NVM_SCRIPT:-}" && -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    NVM_SCRIPT="/usr/local/opt/nvm/nvm.sh"
    NVM_COMPLETION="/usr/local/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -z "${NVM_SCRIPT:-}" && -s "$NVM_DIR/nvm.sh" ]]; then
    NVM_SCRIPT="$NVM_DIR/nvm.sh"
    NVM_COMPLETION="$NVM_DIR/bash_completion"
fi

if [[ -n "${NVM_SCRIPT:-}" ]]; then
    add_to_path "$NVM_DIR"
    source "$NVM_SCRIPT"
    [[ -n "${NVM_COMPLETION:-}" && -s "$NVM_COMPLETION" ]] && source "$NVM_COMPLETION"
fi

# fnm (Fast Node Manager) - optional
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# Rust
if command -v rustup &> /dev/null; then
    add_to_path "$HOME/.cargo/bin"
fi

# Go
if command -v g &> /dev/null && [[ -d "$HOME/.g" ]]; then
    export GOROOT="$HOME/.g/go"
    add_to_path "$GOROOT/bin"
elif command -v go &> /dev/null; then
    export GOPATH="$HOME/go"
    add_to_path "$GOPATH/bin"
fi

# PHP
if command -v phpenv &> /dev/null; then
    add_to_path "$HOME/.phpenv/bin"
    eval "$(phpenv init -)"
fi

# Conda/Miniconda
__conda_setup="$HOME/miniconda3/bin/conda"
if [[ -f "$__conda_setup" ]]; then
    __conda_setup="$($__conda_setup 'shell.zsh' 'hook' 2> /dev/null)"
    if [[ $? -eq 0 ]]; then
        eval "$__conda_setup"
    else
        if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
        else
            add_to_path "$HOME/miniconda3/bin"
        fi
    fi
fi
unset __conda_setup

# Anaconda (alternative location)
if [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [[ -d "$HOME/anaconda3/bin" ]]; then
    add_to_path "$HOME/anaconda3/bin"
fi

# SDKMAN!
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Aliases
alias nodeversions="nvm list"
alias pythonversions="pyenv versions"
alias rubyversions="rbenv versions"
alias javaversions="jenv versions"
