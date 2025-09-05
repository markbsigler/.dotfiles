# ~/.config/zsh/prompt.zsh - Enhanced cross-platform prompt with git info

# Source only in interactive Zsh shells
if [ -n "${BASH_VERSION-}" ] || [ -z "${ZSH_VERSION-}" ]; then
    return 0
fi
case $- in
    *i*) ;; # interactive
    *) return 0 ;;
esac

# CRITICAL: Ensure prompt expansion is enabled (Terminal.app compatibility)
setopt PROMPT_SUBST
setopt PROMPT_PERCENT
setopt PROMPT_BANG

# Ensure OS detection functions are available (fallback for non-interactive shells)
if ! command -v is_macos >/dev/null 2>&1; then
    ZSH_OS_DETECT_PATH="$HOME/.config/zsh/os-detection.zsh"
    [ -f "$ZSH_OS_DETECT_PATH" ] && source "$ZSH_OS_DETECT_PATH"
    [ -f "${ZDOTDIR:-$HOME/.config/zsh}/os-detection.zsh" ] && source "${ZDOTDIR:-$HOME/.config/zsh}/os-detection.zsh"
    [ -f "$(dirname ${(%):-%N})/os-detection.zsh" ] && source "$(dirname ${(%):-%N})/os-detection.zsh"
fi

# Git prompt function
git_prompt_info() {
    local branch
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        if [[ -n $branch ]]; then
            local git_status=""
            # Check if repo is dirty
            if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
                git_status="%F{red}✗%f"
            else
                git_status="%F{green}✓%f"
            fi
            
            # Check for staged changes
            if git diff --cached --quiet 2>/dev/null; then
                : # no staged changes
            else
                git_status="${git_status}%F{yellow}●%f"
            fi
            
            # Check for stashed changes
            if git rev-parse --verify refs/stash >/dev/null 2>&1; then
                git_status="${git_status}%F{blue}⚑%f"
            fi
            
            # Check for unpushed commits
            local unpushed=""
            if git status --porcelain=v1 2>/dev/null | grep -q "^##.*ahead"; then
                unpushed="%F{magenta}↑%f"
            fi
            
            echo " (%F{cyan}$branch%f $git_status$unpushed)"
        fi
    fi
}

# Python virtual environment info
python_prompt_info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "%F{blue}($(basename $VIRTUAL_ENV))%f "
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        echo "%F{blue}(conda:$CONDA_DEFAULT_ENV)%f "
    fi
}

# Node version info (if nvm is loaded)
node_prompt_info() {
    if command -v node &> /dev/null; then
        local node_version=$(node --version 2>/dev/null)
        if [[ -n $node_version && $node_version != "system" ]]; then
            # Only show if we're in a Node.js project
            if [[ -f package.json ]] || [[ -f .nvmrc ]]; then
                echo "%F{green}⬢ ${node_version#v}%f "
            fi
        fi
    fi
}

# Docker context info (if in project with docker)
docker_prompt_info() {
    if [[ -f docker-compose.yml ]] || [[ -f Dockerfile ]]; then
        if command -v docker &> /dev/null; then
            local context=$(docker context show 2>/dev/null || echo "default")
            if [[ "$context" != "default" ]]; then
                echo "%F{cyan}🐳 $context%f "
            fi
        fi
    fi
}

# Kubernetes context (if kubectl available and in k8s project)
k8s_prompt_info() {
    if [[ -f k8s ]] || [[ -f kustomization.yaml ]] || [[ -d .k8s ]]; then
        if command -v kubectl &> /dev/null; then
            local context=$(kubectl config current-context 2>/dev/null)
            if [[ -n "$context" ]]; then
                echo "%F{blue}⎈ ${context}%f "
            fi
        fi
    fi
}

# Show last command execution time if > 3 seconds
cmd_exec_time=""

preexec() {
    cmd_start_time=$(date +%s)
}

precmd() {
    if [[ -n $cmd_start_time ]]; then
        local cmd_end_time=$(date +%s)
        local cmd_elapsed_time=$((cmd_end_time - cmd_start_time))
        if [[ $cmd_elapsed_time -gt 3 ]]; then
            cmd_exec_time="%F{yellow}⏱ ${cmd_elapsed_time}s%f "
        else
            cmd_exec_time=""
        fi
        unset cmd_start_time
    else
        cmd_exec_time=""
    fi
}

# Vi mode indicator
vi_mode_prompt_info() {
    case $KEYMAP in
        vicmd) echo "%F{yellow}[N]%f ";;  # Normal mode
        *) echo "%F{green}[I]%f ";;      # Insert mode
    esac
}

# OS/Platform indicator (subtle) with proper Unicode support
os_prompt_info() {
    # Skip if OS detection functions aren't available
    if ! command -v is_macos >/dev/null 2>&1; then
        return
    fi
    
    if is_macos; then
        echo "%F{240}🍎%f"  # Apple emoji - more compatible than  symbol
    elif is_linux; then
        if command -v is_ubuntu >/dev/null 2>&1 && is_ubuntu; then
            echo "%F{240}🐧%f"  # Penguin for Ubuntu
        else
            echo "%F{240}🐧%f"  # Penguin for Linux
        fi
    elif command -v is_windows >/dev/null 2>&1 && is_windows; then
        echo "%F{240}🪟%f"  # Window emoji for Windows
    fi
}

# SSH connection indicator
ssh_prompt_info() {
    if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
        echo "%F{yellow}🔗%f "  # Link icon for SSH
    fi
}

# Battery status (for laptops) - cross-platform
battery_prompt_info() {
    local battery_level=""
    
    # Check if OS detection functions are loaded
    if ! command -v is_macos >/dev/null 2>&1; then
        return 0
    fi
    
    if is_macos; then
        if command -v pmset &> /dev/null; then
            local battery_info=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1)
            if [[ -n "$battery_info" ]]; then
                local level=${battery_info%\%}
                if [[ $level -lt 20 ]]; then
                    battery_level="%F{red}🔋 $battery_info%f "
                elif [[ $level -lt 50 ]]; then
                    battery_level="%F{yellow}🔋 $battery_info%f "
                fi
            fi
        fi
    elif command -v is_linux >/dev/null 2>&1 && is_linux; then
        if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
            local level=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
            if [[ -n "$level" ]]; then
                if [[ $level -lt 20 ]]; then
                    battery_level="%F{red}🔋 ${level}%%f "
                elif [[ $level -lt 50 ]]; then
                    battery_level="%F{yellow}🔋 ${level}%%f "
                fi
            fi
        fi
    fi
    
    echo "$battery_level"
}

# Load average (Linux/macOS)
load_prompt_info() {
    # Skip if OS detection functions aren't available
    if ! command -v is_macos >/dev/null 2>&1; then
        return
    fi
    
    if command -v uptime &> /dev/null; then
        local load=""
        if is_macos; then
            load=$(uptime 2>/dev/null | sed 's/.*load averages: \([0-9.]*\).*/\1/')
        elif command -v is_linux >/dev/null 2>&1 && is_linux; then
            load=$(uptime 2>/dev/null | sed 's/.*load average: \([0-9.]*\),.*/\1/')
        fi
        
        if [[ -n "$load" ]]; then
            # Only show if load is high (> number of CPUs)
            local cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
            if command -v bc &> /dev/null && (( $(echo "$load > $cpu_count" | bc -l 2>/dev/null || echo 0) )); then
                echo "%F{red}📈 $load%f "
            fi
        fi
    fi
}

# Directory info with truncation
dir_prompt_info() {
    local pwd_info="%~"
    
    # If path is too long, truncate middle parts
    local current_path="${(%):-%~}"
    if [[ ${#current_path} -gt 50 ]]; then
        # Show first and last 2 directories
        local path_parts=(${(s:/:)current_path})
        if [[ ${#path_parts} -gt 4 ]]; then
            local first="${path_parts[1]}"
            local second="${path_parts[2]}"
            local second_last="${path_parts[-2]}"
            local last="${path_parts[-1]}"
            pwd_info="$first/$second/…/$second_last/$last"
        fi
    fi
    
    echo "%F{yellow}$pwd_info%f"
}

# Custom prompt with multiple lines for readability
# Different styles based on whether we're in SSH or local
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    # SSH prompt (more compact)
    export PROMPT='$(ssh_prompt_info)%F{cyan}%n@%m%f:$(dir_prompt_info)$(git_prompt_info)
$(vi_mode_prompt_info)%# '
else
    # Local prompt (more detailed) - FIXED: Added missing newline in PROMPT
    export PROMPT='🌊 ╭─$(python_prompt_info)$(node_prompt_info)$(docker_prompt_info)$(k8s_prompt_info)%F{cyan}%n@%m%f:$(dir_prompt_info)$(git_prompt_info)
🌊 ╰─$(battery_prompt_info)${cmd_exec_time}$(vi_mode_prompt_info)$(os_prompt_info) %# '
fi

# Right-side prompt with time and system info
export RPS1='$(load_prompt_info)%F{240}%D{%H:%M:%S}%f'

# Secondary prompt
export PS2='%F{240}🌊 %f'

# Prompt for spelling correction
export SPROMPT='%F{red}Correct %F{yellow}%R%f %F{red}to %F{green}%r%f? [nyae] '

# Vi mode key bindings (if vi-mode is enabled)
function zle-keymap-select {
    zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-init {
    zle reset-prompt
}
zle -N zle-line-init

# Prompt themes - can be switched with prompt_theme function
prompt_theme() {
    local theme="${1:-default}"
    
    case "$theme" in
        "minimal")
            export PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f$(git_prompt_info)
%# '
            export RPS1='%F{240}%D{%H:%M}%f'
            ;;
        "powerline")
            # Requires a Powerline font
            export PROMPT='%K{blue}%F{white} %n@%m %k%F{blue}%K{yellow}%F{black} %~ %k%F{yellow}%f$(git_prompt_info)
%# '
            export RPS1='%F{240}%D{%H:%M:%S}%f'
            ;;
        "classic")
            export PROMPT='[%n@%m %~]$ '
            export RPS1=''
            ;;
        "wave")
            # Wave-themed prompt with extra wave icons
            if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
                export PROMPT='🌊$(ssh_prompt_info)%F{cyan}%n@%m%f:$(dir_prompt_info)$(git_prompt_info)
🌊 $(vi_mode_prompt_info)%# '
            else
                export PROMPT='🌊 ╭─$(python_prompt_info)$(node_prompt_info)$(docker_prompt_info)$(k8s_prompt_info)%F{cyan}%n@%m%f:$(dir_prompt_info)$(git_prompt_info)
🌊 ╰─$(battery_prompt_info)${cmd_exec_time}$(vi_mode_prompt_info)$(os_prompt_info) %# '
            fi
            export RPS1='🌊 $(load_prompt_info)%F{240}%D{%H:%M:%S}%f'
            export PS2='🌊 %F{240}>%f '
            ;;
        *)
            # Reset to default (wave theme)
            if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
                export PROMPT='$(ssh_prompt_info)%F{cyan}%n@%m%f:$(dir_prompt_info)$(git_prompt_info)
$(vi_mode_prompt_info)%# '
            else
                export PROMPT='🌊 ╭─$(python_prompt_info)$(node_prompt_info)$(docker_prompt_info)$(k8s_prompt_info)%F{cyan}%n@%m%f:$(dir_prompt_info)$(git_prompt_info)
🌊 ╰─$(battery_prompt_info)${cmd_exec_time}$(vi_mode_prompt_info)$(os_prompt_info) %# '
            fi
            export RPS1='$(load_prompt_info)%F{240}%D{%H:%M:%S}%f'
            ;;
    esac
}

# Prompt debugging
prompt_debug() {
    echo "Current prompt components:"
    echo "  OS: $(os_prompt_info)"
    echo "  SSH: $(ssh_prompt_info)"
    echo "  Python: $(python_prompt_info)"
    echo "  Node: $(node_prompt_info)"
    echo "  Docker: $(docker_prompt_info)"
    echo "  K8s: $(k8s_prompt_info)"
    echo "  Git: $(git_prompt_info)"
    echo "  Battery: $(battery_prompt_info)"
    echo "  Load: $(load_prompt_info)"
    echo "  Vi mode: $(vi_mode_prompt_info)"
    echo "  Current PROMPT: $PROMPT"
    echo "  Current RPS1: $RPS1"
    echo "  Current PS2: $PS2"
}

# Function to test prompt display
prompt_test() {
    echo "Testing prompt appearance..."
    echo "Wave icon: 🌊"
    echo "Apple icon: 🍎"
    echo "Current prompt will look like:"
    # Simulate a prompt line
    local test_prompt=$(echo "$PROMPT" | sed 's/%F{[^}]*}//g; s/%f//g; s/%[a-zA-Z#~]//g; s/\$([^)]*)//g')
    echo "$test_prompt"
}
