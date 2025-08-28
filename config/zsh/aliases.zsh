# ~/.config/zsh/aliases.zsh - Command aliases

# System
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# List files - conditional based on available tools
if command -v eza &> /dev/null; then
    alias ls="eza --color=auto --icons"
    alias l="eza -lahF --color=auto --icons"
    alias la="eza -la --color=auto --icons"
    alias ll="eza -l --color=auto --icons"
    alias lsd="eza -lD --color=auto --icons"  # List only directories
    alias laf="eza -laF --color=auto --icons"
    alias tree="eza --tree"
elif command -v exa &> /dev/null; then
    # Fallback to exa
    alias ls="exa --color=auto --icons"
    alias l="exa -lahF --color=auto --icons"
    alias la="exa -la --color=auto --icons"
    alias ll="exa -l --color=auto --icons"
    alias lsd="exa -lD --color=auto --icons"
    alias laf="exa -laF --color=auto --icons"
    alias tree="exa --tree"
else
    # Standard ls with platform-specific options
    if is_macos; then
        alias l="ls -lahG"
        alias la="ls -laG"
        alias ll="ls -lG"
    else
        alias l="ls -lah --color=auto"
        alias la="ls -la --color=auto"
        alias ll="ls -l --color=auto"
    fi
    alias lsd="ls -l | grep '^d'"  # List only directories
    alias laf="ls -aF"
fi

# Better cat with syntax highlighting
if command -v bat &> /dev/null; then
    alias cat="bat"
    alias ccat="bat --style=plain"  # Plain cat alternative
elif command -v batcat &> /dev/null; then
    alias cat="batcat"
    alias ccat="batcat --style=plain"
fi

# Better find
if command -v fd &> /dev/null; then
    alias find="fd"
elif command -v fdfind &> /dev/null; then
    # Ubuntu package name
    alias find="fdfind"
    alias fd="fdfind"
fi

# Better du
if command -v dust &> /dev/null; then
    alias du="dust"
fi

# Better grep
if command -v rg &> /dev/null; then
    alias grep="rg"
    alias rgrep="rg"
else
    alias grep="grep --color=auto"
    alias fgrep="fgrep --color=auto"
    alias egrep="egrep --color=auto"
fi

# Common commands
alias h="history"
alias c="clear"
alias q="exit"

# Git shortcuts
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline"
alias glog="git log --oneline --graph --decorate --all"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gstash="git stash"
alias gpop="git stash pop"
alias greset="git reset --hard HEAD"
alias gundo="git reset --soft HEAD~1"
alias gclean="git clean -fd"

# Python
alias python="python3"
alias pip="pip3"
alias venv="python3 -m venv"
alias activate="source venv/bin/activate"

# Node.js/npm
alias ni="npm install"
alias nid="npm install --save-dev"
alias nig="npm install -g"
alias nru="npm run"
alias dev="npm run dev"
alias build="npm run build"
alias test="npm test"
alias lint="npm run lint"

# TypeScript
alias tsc="npx tsc"
alias ts-node="npx ts-node"
alias jest="npx jest"

# Docker
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"
alias dimg="docker images"

# Network
alias myip="curl -s https://ipinfo.io/ip"
alias ping="ping -c 5"
alias ports="netstat -tuln"

# File operations
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias mkdir="mkdir -p"

# Directory stack navigation
alias dirs='dirs -v'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'

# Quick project navigation
alias ..2="cd ../.."
alias ..3="cd ../../.."
alias ..4="cd ../../../.."

# JSON/YAML processing
if command -v jq &> /dev/null; then
    alias jq="jq -C"  # Colorized JSON
fi
alias yaml2json="python3 -c 'import sys, yaml, json; json.dump(yaml.safe_load(sys.stdin), sys.stdout, indent=2)'"

# Quick file editing
alias vimrc="$EDITOR ~/.config/zsh/"
alias reload="source ~/.zshrc && echo 'Zsh reloaded'"

# Platform-specific aliases
if is_macos; then
    # macOS specific
    alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    alias flushdns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
    alias brewup="brew update && brew upgrade && brew cleanup"
    alias brewinfo="brew leaves | xargs brew desc --eval-all"
    alias localip="ipconfig getifaddr en0"
    alias publicip="curl -s https://ipinfo.io/ip"
    # Quick Look
    alias ql="qlmanage -p"
    # Copy to clipboard
    alias copy="pbcopy"
    alias paste="pbpaste"
    
elif is_linux; then
    # Linux specific
    if command -v systemctl &> /dev/null; then
        alias flushdns="sudo systemctl restart systemd-resolved"
    fi
    
    # Network IP
    if command -v ip &> /dev/null; then
        alias localip="ip route get 8.8.8.8 | awk 'NR==1 {print \$7}'"
    elif command -v hostname &> /dev/null; then
        alias localip="hostname -I | awk '{print \$1}'"
    fi
    alias publicip="curl -s https://ipinfo.io/ip"
    
    # Package management aliases
    if is_ubuntu || is_debian; then
        alias aptup="sudo apt update && sudo apt upgrade"
        alias aptinstall="sudo apt install"
        alias aptsearch="apt search"
        alias aptshow="apt show"
        alias aptlist="apt list --installed"
    elif is_fedora; then
        alias dnfup="sudo dnf update"
        alias dnfinstall="sudo dnf install"
        alias dnfsearch="dnf search"
    elif is_arch; then
        alias pacup="sudo pacman -Syu"
        alias pacinstall="sudo pacman -S"
        alias pacsearch="pacman -Ss"
    fi
    
    # Snap aliases
    if has_snap; then
        alias snaplist="snap list"
        alias snapinstall="sudo snap install"
        alias snapupdate="sudo snap refresh"
    fi
    
    # Flatpak aliases
    if has_flatpak; then
        alias flatlist="flatpak list"
        alias flatinstall="flatpak install"
        alias flatupdate="flatpak update"
    fi
    
    # Clipboard (if available)
    if command -v xclip &> /dev/null; then
        alias copy="xclip -selection clipboard"
        alias paste="xclip -selection clipboard -o"
    elif command -v xsel &> /dev/null; then
        alias copy="xsel --clipboard --input"
        alias paste="xsel --clipboard --output"
    fi
    
    # Desktop environment specific
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        alias extensions="gnome-extensions list"
        alias settings="gnome-control-center"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        alias settings="systemsettings5"
    fi
    
elif is_windows; then
    # Windows/WSL specific
    alias explorer="explorer.exe"
    alias notepad="notepad.exe"
    # WSL specific
    if grep -qi microsoft /proc/version 2>/dev/null; then
        alias open="explorer.exe"
        alias copy="clip.exe"
    fi
fi

# Development workflow aliases
alias npmls='npm list --depth=0'
alias npmg='npm list -g --depth=0'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'
alias vact='source venv/bin/activate'
alias vdeact='deactivate'
alias gd='git diff --name-only'
alias gdc='git diff --cached'
alias gl='git log --oneline -10'
alias gla='git log --oneline --all --graph -10'

# Docker pretty formatting
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# System monitoring
if command -v htop &> /dev/null; then
    alias top="htop"
fi

if command -v ncdu &> /dev/null; then
    alias ncdu="ncdu --color dark"
fi

# GitHub CLI (if available)
if command -v gh &> /dev/null; then
    # Only setup copilot aliases if the extension is installed
    if gh extension list 2>/dev/null | grep -q "github/gh-copilot"; then
        eval "$(gh copilot alias -- zsh)"
    fi
fi

# Quick server
alias serve8080="python3 -m http.server 8080"

# Process management
alias psg="ps aux | grep"
alias killall="killall -v"

# Disk usage
if is_macos; then
    alias diskusage="du -sh * | sort -hr"
else
    alias diskusage="du -sh * | sort -hr"
fi

# Brew update
alias brewup='brew update && brew upgrade --greedy && brew cleanup && brew autoremove && brew doctor'
