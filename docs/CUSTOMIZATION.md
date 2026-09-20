# Dotfiles Customization Guide

This guide explains how to customize your dotfiles for personal or machine-specific needs.

## Table of Contents

- [Local Configuration](#local-configuration)
- [Adding Custom Aliases](#adding-custom-aliases)
- [Adding Custom Functions](#adding-custom-functions)
- [Managing Secrets](#managing-secrets)
- [Platform-Specific Configuration](#platform-specific-configuration)
- [Adding Plugins](#adding-plugins)
- [Customizing the Prompt](#customizing-the-prompt)
- [Best Practices](#best-practices)

## Local Configuration

Use one ignored file for machine-specific shell configuration.

### Private Local Config

**Location:** `~/.dotfiles/local/local.zsh`

Full installation creates this file; startup sources it once after the shared
configuration. For a checkout elsewhere, use its `local/local.zsh`. The tracked
`config/zsh/local.zsh` placeholder is no longer sourced. Review and move old
personal settings manually, without putting secrets into tracked files.

```bash
# Example: ~/.dotfiles/local/local.zsh

# Work-specific configurations
export WORK_EMAIL="you@company.com"
alias work-ssh="ssh user@work-server"

# Explicit credential loading when needed
github_credentials() {
    secret_from_keychain GITHUB_TOKEN github_token
}

# Machine-specific PATH modifications
export PATH="/custom/path:$PATH"

# Machine-specific aliases
alias vpn="sudo openvpn --config ~/vpn/config.ovpn"
```

### Private Git Config

**Location:** `~/.gitconfig.local`

The shared Git config includes this optional file for machine-specific credential
helpers or tracing settings. It is separate from shell configuration.

## Adding Custom Aliases

### Method 1: Use local.zsh (Recommended for personal aliases)

```bash
# ~/.dotfiles/local/local.zsh
alias update="~/scripts/update.sh"
alias notes="vim ~/Documents/notes.md"
```

### Method 2: Add to aliases.zsh (For permanent additions)

```bash
# ~/.dotfiles/config/zsh/aliases.zsh
alias myproject="cd ~/dev/important-project"
```

### Common Alias Patterns

```bash
# Navigation shortcuts
alias projects="cd ~/Projects"
alias dotfiles="cd ~/.dotfiles"

# Application shortcuts
alias python="python3"
alias pip="pip3"

# Git aliases (if not already defined)
alias gpo="git push origin"
alias gpl="git pull"

# Docker shortcuts
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dcu="docker-compose up -d"

# System maintenance
alias update-all="~/.dotfiles/scripts/update-all.sh"
alias backup="~/.dotfiles/scripts/backup-dotfiles.sh"
```

## Adding Custom Functions

### Method 1: Use local.zsh

```bash
# ~/.dotfiles/local/local.zsh

# Quick project initializer
myproject() {
    mkdir -p ~/Projects/"$1"
    cd ~/Projects/"$1"
    git init
    echo "# $1" > README.md
}

# Find and kill process by name
killbyname() {
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}
```

### Method 2: Add to functions.zsh

```bash
# ~/.dotfiles/config/zsh/functions.zsh

# Add your function here for permanent inclusion
my_function() {
    # Your code
}
```

### Useful Function Examples

```bash
# Create directory and cd into it
mkcdir() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive format
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.rar)       unrar x "$1"   ;;
            *)           echo "Unknown format" ;;
        esac
    fi
}

# Quick HTTP server
serve() {
    python3 -m http.server "${1:-8000}"
}

# Search history
h() {
    history | grep "$1"
}
```

## Managing Secrets

See [SECRETS.md](./SECRETS.md) for detailed information.

### Quick Start

```bash
# Method 1: Plaintext JSON; jq required, enter value at prompt
secret_add GITHUB_TOKEN
secret_list
secret_load GITHUB_TOKEN
unset GITHUB_TOKEN

# Method 2: macOS Keychain
keychain_add github_token
secret_from_keychain GITHUB_TOKEN github_token

# Method 3: 1Password CLI
secret_from_1password GITHUB_TOKEN "op://Personal/GitHub/token"
```

## Platform-Specific Configuration

### Detecting the Platform

```bash
# Use built-in detection functions
if is_macos; then
    # macOS-specific config
    export BROWSER="open"
elif is_linux; then
    # Linux-specific config
    export BROWSER="firefox"
fi

# Architecture detection
if is_arm64; then
    echo "Running on ARM64 (Apple Silicon or ARM Linux)"
fi
```

### Platform-Specific Files

```bash
# Check OS type with $OSTYPE
if [[ "$OSTYPE" == darwin* ]]; then
    # macOS specific
elif [[ "$OSTYPE" == linux* ]]; then
    # Linux specific
fi
```

## Adding Plugins

### ZSH Plugins

1. **Clone the plugin:**

```bash
git clone https://github.com/user/plugin-name \
    ~/.local/share/zsh/plugins/plugin-name
```

2. **Load it in your config:**

Add to `~/.dotfiles/local/local.zsh`:

```bash
# Load custom plugin
if [[ -d "$HOME/.local/share/zsh/plugins/plugin-name" ]]; then
    source "$HOME/.local/share/zsh/plugins/plugin-name/plugin-name.plugin.zsh"
fi
```

### Recommended Plugins

Already included:
- `zsh-autosuggestions` - Fish-like suggestions
- `zsh-syntax-highlighting` - Syntax highlighting
- `fzf-tab` - FZF-powered tab completion

Additional suggestions:
- `zsh-history-substring-search` - Better history search
- `zsh-completions` - More completions

### Vim/Neovim Plugins

Add to your `~/.vimrc` or `~/.config/nvim/init.vim`:

```vim
" Add plugin with vim-plug
Plug 'user/plugin-name'

" Then run :PlugInstall
```

## Customizing the Prompt

### Simple Prompt Changes

Add to `~/.dotfiles/local/local.zsh`:

```bash
# Minimal prompt
PROMPT='%~ $ '

# Two-line prompt
PROMPT='%F{blue}%~%f
%F{green}❯%f '

# With git branch
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'
PROMPT='%~ ${vcs_info_msg_0_} $ '
```

### Using Prompt Themes

```bash
# Starship prompt (install separately)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Pure prompt
if [[ -f ~/.zsh/pure/pure.zsh ]]; then
    autoload -U promptinit; promptinit
    prompt pure
fi
```

## Best Practices

### 1. Use local.zsh for Personal Changes

✅ **Do:**
```bash
# ~/.dotfiles/local/local.zsh
alias myserver="ssh user@myserver.com"
export WORK_PROJECT_DIR="$HOME/work/projects"
```

❌ **Don't:**
```bash
# ~/.dotfiles/config/zsh/aliases.zsh (tracked in git)
alias myserver="ssh user@myserver.com"
```

### 2. Keep Secrets Out of Git

✅ **Do:**
```bash
# Use secret_add or keychain
secret_add API_KEY
```

❌ **Don't:**
```bash
# Hard-code in tracked files
export API_KEY="your-api-key"
```

### 3. Document Your Changes

```bash
# ~/.dotfiles/local/local.zsh

# ==========================================================
# Work Configuration
# ==========================================================
export WORK_PROJECT_DIR="~/work/projects"
alias work="cd $WORK_PROJECT_DIR"

# ==========================================================
# Personal Scripts
# ==========================================================
alias backup-photos="rsync -av ~/Pictures /backup/photos"
```

### 4. Test Before Committing

```bash
# Test in local.zsh first
source ~/.dotfiles/local/local.zsh

# If it works, move to main config and commit
git add config/zsh/aliases.zsh
git commit -m "Add useful alias"
```

### 5. Use Functions for Complex Logic

✅ **Do:**
```bash
deploy_app() {
    cd "$PROJECT_DIR" || return
    git pull
    docker-compose up -d
}
```

❌ **Don't:**
```bash
alias deploy="cd $PROJECT_DIR && git pull && docker-compose up -d"
```

### 6. Keep It Organized

```bash
# Group related configurations
# ==========================================================
# Docker Shortcuts
# ==========================================================
alias dps="docker ps"
alias dcu="docker-compose up -d"
alias dcd="docker-compose down"

# ==========================================================
# Development Environments
# ==========================================================
alias dev-python="cd ~/dev/python-project && source venv/bin/activate"
alias dev-node="cd ~/dev/node-project && nvm use"
```

## Testing Your Changes

```bash
# Test configuration syntax
zsh -n ~/.dotfiles/local/local.zsh

# Reload configuration
source ~/.zshrc

# Profile startup time (if changes are slow)
~/.dotfiles/scripts/profile-startup.sh

# Run tests
make test
```

## Getting Help

```bash
# Show all available functions
typeset -f | grep '^[a-zA-Z_-]* ()' | sed 's/ ()//'

# Show aliases
alias

# Show secrets management help
secret_help

# Check doctor
make doctor
```

## Examples

### Work Profile

```bash
# ~/.dotfiles/local/local.zsh

# Work environment setup
work_setup() {
    export GIT_AUTHOR_EMAIL="me@work.com"
    export GIT_COMMITTER_EMAIL="me@work.com"
    echo "✅ Work environment activated"
}

# Personal environment setup
personal_setup() {
    export GIT_AUTHOR_EMAIL="me@personal.com"
    export GIT_COMMITTER_EMAIL="me@personal.com"
    echo "✅ Personal environment activated"
}

# Auto-detect and set environment
if [[ "$PWD" =~ "/work/" ]]; then
    work_setup
fi
```

### Project Shortcuts

```bash
# ~/.dotfiles/local/local.zsh

# Quick project access
alias p1="cd ~/Projects/project1"
alias p2="cd ~/Projects/project2"
alias p3="cd ~/Projects/project3"

# Project-specific commands
p1_deploy() {
    cd ~/Projects/project1 && ./deploy.sh
}
```

### Development Environment

```bash
# ~/.dotfiles/local/local.zsh

# Python development
alias venv="python3 -m venv venv && source venv/bin/activate"
alias activate="source venv/bin/activate"

# Node development
alias ni="npm install"
alias ns="npm start"
alias nt="npm test"

# Docker development
alias dev-up="docker-compose -f docker-compose.dev.yml up -d"
alias dev-down="docker-compose -f docker-compose.dev.yml down"
```

## Need More Help?

- Read [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- Check [SECRETS.md](./SECRETS.md) for secrets management
- Run `make doctor` to check your setup
- Open an issue on GitHub

