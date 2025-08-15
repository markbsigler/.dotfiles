# ~/.config/zsh/functions.zsh - Custom functions

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats (improved)
extract() {
    if [ ! -f "$1" ]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi
    
    case "$1" in
        *.tar.bz2)   tar xjf "$1"   ;;
        *.tar.gz)    tar xzf "$1"   ;;
        *.bz2)       bunzip2 "$1"   ;;
        *.rar)       unrar x "$1"   ;;
        *.gz)        gunzip "$1"    ;;
        *.tar)       tar xf "$1"    ;;
        *.tbz2)      tar xjf "$1"   ;;
        *.tgz)       tar xzf "$1"   ;;
        *.zip)       unzip "$1"     ;;
        *.Z)         uncompress "$1";;
        *.7z)        7z x "$1"      ;;
        *.xz)        unxz "$1"      ;;
        *.lzma)      unlzma "$1"    ;;
        *)           echo "Error: '$1' cannot be extracted via extract()"
                     return 1 ;;
    esac
}

# Find process by name
psgrep() {
    ps aux | grep -v grep | grep "$1"
}

# Quick server
unalias serve 2>/dev/null
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# Weather
weather() {
    local city="${1:-}"
    curl -s "wttr.in/${city}?format=3"
}

# JSON pretty print
json() {
    if [ -t 0 ]; then
        python3 -m json.tool <<< "$*"
    else
        python3 -m json.tool
    fi
}

# Reload zsh config
reload_zshrc() {
    source ~/.zshrc
    echo "Zsh config reloaded"
}

# Smart git status with clean output
gstatus() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git status --short --branch
    else
        echo "Not in a git repository"
        return 1
    fi
}

# Quick commit with message
gcm() {
    if [ -z "$1" ]; then
        echo "Usage: gcm <commit-message>"
        return 1
    fi
    git add -A && git commit -m "$1"
}

# Zsh startup time profiling
zsh_bench() {
    echo "Running zsh startup benchmark..."
    for i in {1..10}; do
        /usr/bin/time -p zsh -i -c exit 2>&1 | grep real
    done
}

# Create and switch to a new git branch
gcb() {
    if [ -z "$1" ]; then
        echo "Usage: gcb <branch-name>"
        return 1
    fi
    git checkout -b "$1"
}

# Performance monitoring
zsh_load_time() {
    for i in {1..5}; do
        time ( zsh -i -c exit )
    done
}

# Profile zsh startup
zprof_start() {
    zmodload zsh/zprof
    source ~/.zshrc
    zprof
}

# Plugin update checker
check_plugin_updates() {
    local days_old=7
    echo "Checking for plugin updates older than $days_old days..."
    for plugin in "$PLUGIN_DIR"/*; do
        if [[ -d "$plugin/.git" ]]; then
            local last_update=$(stat -f "%Sm" -t "%s" "$plugin/.git/FETCH_HEAD" 2>/dev/null || echo 0)
            local now=$(date +%s)
            if (( (now - last_update) / 86400 > days_old )); then
                echo "Plugin $(basename "$plugin") is $((($now - $last_update) / 86400)) days old - consider updating"
            fi
        fi
    done
}

# Better zsh startup time profiling
zsh_startup_time() {
    shell=${1-$SHELL}
    echo "Measuring startup time for $shell (10 runs):"
    for i in $(seq 1 10); do
        /usr/bin/time -p $shell -i -c exit 2>&1 | grep real | awk '{print "Run " NR ": " $2 "s"}'
    done
}

# Find and kill processes
killp() {
    if [ -z "$1" ]; then
        echo "Usage: killp <process-name-pattern>"
        return 1
    fi
    ps aux | grep -i "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Quick directory bookmark system
book() {
    if [ -z "$1" ]; then
        # List bookmarks
        if [ -f "$HOME/.bookmarks" ]; then
            cat "$HOME/.bookmarks"
        else
            echo "No bookmarks found"
        fi
    else
        # Add bookmark
        echo "$1:$(pwd)" >> "$HOME/.bookmarks"
        echo "Bookmarked $(pwd) as '$1'"
    fi
}

# Jump to bookmark
go() {
    if [ -z "$1" ]; then
        echo "Usage: go <bookmark-name>"
        return 1
    fi
    
    if [ -f "$HOME/.bookmarks" ]; then
        local path=$(grep "^$1:" "$HOME/.bookmarks" | cut -d: -f2)
        if [ -n "$path" ] && [ -d "$path" ]; then
            cd "$path"
        else
            echo "Bookmark '$1' not found or directory doesn't exist"
        fi
    else
        echo "No bookmarks file found"
    fi
}

# Clean up bookmark file
clean_bookmarks() {
    if [ -f "$HOME/.bookmarks" ]; then
        local temp_file=$(mktemp)
        while IFS=: read -r name path; do
            if [ -d "$path" ]; then
                echo "$name:$path" >> "$temp_file"
            fi
        done < "$HOME/.bookmarks"
        mv "$temp_file" "$HOME/.bookmarks"
        echo "Cleaned up invalid bookmarks"
    fi
}

# Quick project setup with common files
mkproject() {
    if [ -z "$1" ]; then
        echo "Usage: mkproject <project-name>"
        return 1
    fi
    
    mkdir -p "$1" && cd "$1"
    
    # Create common files
    echo "# $1" > README.md
    echo "node_modules/\n.DS_Store\n.env" > .gitignore
    
    # Initialize git
    git init
    git add .
    git commit -m "Initial commit"
    
    echo "Project '$1' created and initialized!"
}
