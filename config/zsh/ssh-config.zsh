# Cross-platform SSH configuration function
configure_ssh() {
    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"
    
    # Create SSH directory if it doesn't exist
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi
    
    # Create basic SSH config if it doesn't exist
    if [[ ! -f "$ssh_config" ]]; then
        cat > "$ssh_config" << 'EOF'
# SSH Configuration
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
    IdentityFile ~/.ssh/id_rsa
    
# Platform-specific settings
Host *
    # macOS
    UseKeychain yes
    # Linux - comment out UseKeychain if not on macOS
    # UseKeychain no

# Example host configuration
# Host myserver
#     HostName example.com
#     User myuser
#     Port 22
#     IdentityFile ~/.ssh/id_rsa_myserver
EOF
        chmod 600 "$ssh_config"
        info "Created basic SSH config at $ssh_config"
    fi
}
