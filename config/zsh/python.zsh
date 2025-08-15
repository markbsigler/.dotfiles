# Python Development Configuration

# Pyenv configuration
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Poetry configuration
if command -v poetry >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Pipenv configuration
export PIPENV_VENV_IN_PROJECT=1  # Create .venv in project directory
export PIPENV_VERBOSITY=-1       # Reduce pipenv output

# Python aliases
alias py="python"
alias py3="python3"
alias pip="python -m pip"
alias venv="python -m venv"

# Virtual environment helpers
alias activate="source .venv/bin/activate"
alias deactivate="deactivate"

# Quick project setup
mkpyproject() {
    mkdir -p "$1" && cd "$1"
    if command -v poetry >/dev/null 2>&1; then
        poetry init
    else
        python -m venv .venv
        source .venv/bin/activate
        pip install --upgrade pip
    fi
}

# Show current Python version and virtual env in prompt
python_info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "🐍 $(basename $VIRTUAL_ENV)"
    elif command -v pyenv >/dev/null 2>&1; then
        echo "🐍 $(pyenv version-name)"
    fi
}
