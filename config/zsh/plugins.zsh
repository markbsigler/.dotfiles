# ~/.config/zsh/plugins.zsh - Plugin management

# Simple plugin manager using git
PLUGIN_DIR="$XDG_DATA_HOME/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

# Plugin loader function
load_plugin() {
    local plugin_name="$1"
    local plugin_url="$2"
    local plugin_path="$PLUGIN_DIR/$plugin_name"
    
    # Clone if doesn't exist
    if [[ ! -d "$plugin_path" ]]; then
        echo "Installing plugin: $plugin_name"
        git clone --depth 1 "$plugin_url" "$plugin_path" 2>/dev/null
    fi
    
    # Load plugin - try multiple possible entry points
    local loaded=false
    for entry in "$plugin_name.plugin.zsh" "$plugin_name.zsh" "init.zsh" "$plugin_name.sh"; do
        if [[ -f "$plugin_path/$entry" ]]; then
            source "$plugin_path/$entry"
            loaded=true
            break
        fi
    done
    
    # If no standard entry point found, look for any .zsh file
    if [[ "$loaded" == false ]]; then
        local zsh_files=("$plugin_path"/*.zsh)
        if [[ -f "${zsh_files[0]}" ]]; then
            source "${zsh_files[0]}"
        fi
    fi
}

# Essential plugins (loaded by default)
load_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
load_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

# Advanced plugins (comment out if you experience slowdowns)
load_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab"

# Platform-specific plugin loading
if is_macos; then
    # macOS specific plugins
    # load_plugin "macos-utilities" "https://github.com/example/macos-utilities"
    :
elif is_linux; then
    # Linux specific plugins
    # load_plugin "linux-utilities" "https://github.com/example/linux-utilities"
    :
fi

# FZF integration (cross-platform)
setup_fzf() {
    if ! command -v fzf &> /dev/null; then
        return 1
    fi
    
    # Platform-specific FZF installation paths
    local fzf_completion=""
    local fzf_keybindings=""
    
    if is_macos; then
        # Homebrew FZF paths
        if [[ -f "/opt/homebrew/opt/fzf/shell/completion.zsh" ]]; then
            fzf_completion="/opt/homebrew/opt/fzf/shell/completion.zsh"
            fzf_keybindings="/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
        elif [[ -f "/usr/local/opt/fzf/shell/completion.zsh" ]]; then
            fzf_completion="/usr/local/opt/fzf/shell/completion.zsh"
            fzf_keybindings="/usr/local/opt/fzf/shell/key-bindings.zsh"
        fi
    elif is_linux; then
        # Linux FZF paths
        if [[ -f "/usr/share/fzf/completion.zsh" ]]; then
            fzf_completion="/usr/share/fzf/completion.zsh"
            fzf_keybindings="/usr/share/fzf/key-bindings.zsh"
        elif [[ -f "/usr/share/doc/fzf/examples/completion.zsh" ]]; then
            fzf_completion="/usr/share/doc/fzf/examples/completion.zsh"
            fzf_keybindings="/usr/share/doc/fzf/examples/key-bindings.zsh"
        fi
    fi
    
    # User installation (all platforms)
    if [[ -z "$fzf_completion" && -f "$HOME/.fzf.zsh" ]]; then
        source "$HOME/.fzf.zsh"
        return 0
    fi
    
    # Manual installation directory
    if [[ -z "$fzf_completion" && -d "$HOME/.fzf" ]]; then
        fzf_completion="$HOME/.fzf/shell/completion.zsh"
        fzf_keybindings="$HOME/.fzf/shell/key-bindings.zsh"
    fi
    
    # Load FZF components
    [[ -f "$fzf_completion" ]] && source "$fzf_completion"
    [[ -f "$fzf_keybindings" ]] && source "$fzf_keybindings"
}

# Load FZF
setup_fzf

# Plugin management functions
update_plugins() {
    echo "Updating zsh plugins..."
    local updated=0
    local failed=0
    
    for plugin in "$PLUGIN_DIR"/*; do
        if [[ -d "$plugin/.git" ]]; then
            local plugin_name=$(basename "$plugin")
            echo -n "Updating $plugin_name... "
            if (cd "$plugin" && git pull --quiet); then
                echo "✅"
                ((updated++))
            else
                echo "❌"
                ((failed++))
            fi
        fi
    done
    
    echo "Plugin update complete! Updated: $updated, Failed: $failed"
}

clean_plugins() {
    echo "Cleaning plugin caches..."
    # Remove compilation files
    find "$PLUGIN_DIR" -name "*.zwc" -delete
    # Remove git garbage
    for plugin in "$PLUGIN_DIR"/*; do
        if [[ -d "$plugin/.git" ]]; then
            (cd "$plugin" && git gc --quiet)
        fi
    done
    echo "Plugin cleanup complete!"
}

list_plugins() {
    echo "Installed plugins:"
    for plugin in "$PLUGIN_DIR"/*; do
        if [[ -d "$plugin" ]]; then
            local plugin_name=$(basename "$plugin")
            local plugin_path="$plugin"
            if [[ -d "$plugin/.git" ]]; then
                local last_update=$(cd "$plugin" && git log -1 --format="%cr" 2>/dev/null || echo "unknown")
                echo "  📦 $plugin_name (updated $last_update)"
            else
                echo "  📦 $plugin_name (no git info)"
            fi
        fi
    done
}

remove_plugin() {
    local plugin_name="$1"
    local plugin_path="$PLUGIN_DIR/$plugin_name"
    
    if [[ -z "$plugin_name" ]]; then
        echo "Usage: remove_plugin <plugin_name>"
        return 1
    fi
    
    if [[ -d "$plugin_path" ]]; then
        read -q "REPLY?Remove plugin '$plugin_name'? (y/N): "
        echo
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            rm -rf "$plugin_path"
            echo "Plugin '$plugin_name' removed."
        fi
    else
        echo "Plugin '$plugin_name' not found."
    fi
}

# Benchmark plugin loading times
benchmark_plugins() {
    echo "Benchmarking plugin loading times..."
    
    for plugin in "$PLUGIN_DIR"/*; do
        if [[ -d "$plugin" ]]; then
            local plugin_name=$(basename "$plugin")
            local start_time=$(date +%s.%N)
            
            # Find and source plugin file
            for entry in "$plugin_name.plugin.zsh" "$plugin_name.zsh" "init.zsh" "$plugin_name.sh"; do
                if [[ -f "$plugin/$entry" ]]; then
                    source "$plugin/$entry"
                    break
                fi
            done
            
            local end_time=$(date +%s.%N)
            local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
            
            printf "  %-25s %s\n" "$plugin_name" "${duration}s"
        fi
    done
}

# Auto-update plugins (run weekly)
auto_update_plugins() {
    local update_file="$XDG_CACHE_HOME/zsh_plugin_last_update"
    local current_time=$(date +%s)
    local week_seconds=604800  # 7 days in seconds
    
    if [[ -f "$update_file" ]]; then
        local last_update=$(cat "$update_file")
        local time_diff=$((current_time - last_update))
        
        if [[ $time_diff -gt $week_seconds ]]; then
            echo "Auto-updating plugins (weekly update)..."
            update_plugins
            echo "$current_time" > "$update_file"
        fi
    else
        echo "$current_time" > "$update_file"
    fi
}

# Platform-specific plugin configurations
configure_platform_plugins() {
    if is_macos; then
        # macOS specific plugin configurations
        if [[ -d "$PLUGIN_DIR/zsh-autosuggestions" ]]; then
            # Faster autosuggestions on macOS
            export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
            export ZSH_AUTOSUGGEST_USE_ASYNC=1
        fi
    elif is_linux; then
        # Linux specific plugin configurations
        if [[ -d "$PLUGIN_DIR/fzf-tab" ]]; then
            # Enable fzf-tab for systemd commands on Linux
            zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
        fi
    fi
}

# Apply platform-specific configurations
configure_platform_plugins

# Uncomment to enable auto-update (checks weekly)
# auto_update_plugins

# Plugin aliases for easy management
alias plugin-update="update_plugins"
alias plugin-clean="clean_plugins"
alias plugin-list="list_plugins"
alias plugin-remove="remove_plugin"
alias plugin-bench="benchmark_plugins"
