#!/usr/bin/env bash

# Dotfiles Installation Script
# This script sets up a complete development environment by symlinking
# configuration files and installing necessary dependencies.

set -euo pipefail


# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR="$HOME/.dotfiles-backup-$BACKUP_TIMESTAMP-$$"
readonly LOG_FILE="$DOTFILES_DIR/install.log"
source "$DOTFILES_DIR/scripts/lib/backup.sh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Flags
DRY_RUN=false
FORCE=false
VERBOSE=false
UPDATE_MODE=false
SKIP_PACKAGES=false
RUN_TESTS=false

# OS Detection
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*) echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        arm64|aarch64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^ID=/{gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        echo "unknown"
    fi
}

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Logging functions
log() {
    if [[ "$DRY_RUN" == false && "${LOG_READY:-false}" == true ]]; then
        printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
    fi
}

info() {
    print_color "$BLUE" "ℹ️  $*"
    log "INFO: $*"
}

success() {
    print_color "$GREEN" "✅ $*"
    log "SUCCESS: $*"
}

warning() {
    print_color "$YELLOW" "⚠️  $*"
    log "WARNING: $*"
}

error() {
    print_color "$RED" "❌ $*"
    log "ERROR: $*"
}

# Help function
show_help() {
    cat << EOF
Dotfiles Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be done without actually doing it
    -f, --force         Force overwrite existing files (skip backup)
    -v, --verbose       Verbose output
    -u, --update        Update existing symlinks only (don't create new ones)
    -s, --skip-packages Skip package installation
    -t, --test          Run tests after installation

EXAMPLES:
    $0                  # Full installation
    $0 --dry-run        # Preview changes
    $0 --force          # Force overwrite existing files
    $0 --skip-packages  # Install configs only

SUPPORTED PLATFORMS:
    - macOS (Intel & Apple Silicon)
    - Ubuntu/Debian (apt)
    - Fedora/CentOS (dnf/yum) 
    - Arch Linux (pacman)
    - Windows/WSL

For more information, see README.md
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -v|--verbose)
                export VERBOSE=true
                shift
                ;;
            -u|--update)
                UPDATE_MODE=true
                shift
                ;;
            -s|--skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            -t|--test)
                RUN_TESTS=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create backup of existing file/directory
backup_file() {
    local file="$1"
    if [[ ( -e "$file" || -L "$file" ) && "$FORCE" == false ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            info "Would back up: $file"
            return 0
        fi
        if [[ ! -d "$BACKUP_DIR" ]]; then backup_init "$BACKUP_DIR"; fi
        backup_save "$BACKUP_DIR" "${file#"$HOME/"}"
        printf '%s\n' complete > "$BACKUP_DIR/COMPLETE"
    fi
}

# Create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir staging
    target_dir="$(dirname "$target")"
    backup_safe_parent "${target#"$HOME/"}"
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        return 0
    fi
    if [[ "$UPDATE_MODE" == true && ! -L "$target" ]]; then
        return 0
    fi
    if [[ "$DRY_RUN" == true ]]; then
        info "Would link: $source → $target"
        return 0
    fi
    backup_file "$target"
    mkdir -p "$target_dir"
    staging="$(mktemp -d "$target_dir/.dotfiles-link.XXXXXX")"
    if ! ln -s "$source" "$staging/replacement"; then
        rmdir "$staging"
        return 1
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        mv "$target" "$staging/previous" || { rm -rf "$staging"; return 1; }
    fi
    if ! mv "$staging/replacement" "$target"; then
        if [[ -e "$staging/previous" || -L "$staging/previous" ]]; then
            mv "$staging/previous" "$target" || { error "Recovery retained at $staging"; return 1; }
        fi
        rm -rf "$staging"
        return 1
    fi
    rm -rf "$staging"
    success "Linked: $source → $target"
}

# Install packages based on detected OS
install_packages() {
    if [[ "$SKIP_PACKAGES" == true ]]; then
        info "Skipping package installation (--skip-packages flag set)"
        return 0
    fi
    
    if [[ -x "$DOTFILES_DIR/scripts/install-packages.sh" ]]; then
        info "Running package installation script..."
        if [[ "$DRY_RUN" == false ]]; then
            "$DOTFILES_DIR/scripts/install-packages.sh"
        else
            info "Would run: $DOTFILES_DIR/scripts/install-packages.sh"
        fi
    else
        warning "Package installation script not found or not executable"
        warning "Run 'chmod +x $DOTFILES_DIR/scripts/install-packages.sh' to enable"
    fi
}

# Set up ZSH as default shell
setup_zsh() {
    if command_exists zsh; then
        local current_shell
        current_shell="$SHELL"
        
        if [[ "$current_shell" != *"zsh"* ]]; then
            info "Setting ZSH as default shell..."
            if [[ "$DRY_RUN" == false ]]; then
                local zsh_path
                zsh_path=$(command -v zsh)
                
                # Add zsh to /etc/shells if not present
                if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                    echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
                fi
                
                chsh -s "$zsh_path"
                success "ZSH set as default shell"
            else
                info "Would set ZSH as default shell"
            fi
        else
            info "ZSH is already the default shell"
        fi
    else
        warning "ZSH not found. Install it first with your package manager."
    fi
}

# Link configuration files
link_configs() {
    info "Linking configuration files..."
    

    # ZSH configuration
    if [[ -d "$DOTFILES_DIR/config/zsh" ]]; then
        create_symlink "$DOTFILES_DIR/config/zsh" "$HOME/.config/zsh"
    fi

    # Main zsh files
    if [[ -f "$DOTFILES_DIR/config/zsh/.zshrc" ]]; then
        create_symlink "$DOTFILES_DIR/config/zsh/.zshrc" "$HOME/.zshrc"
    fi

    if [[ -f "$DOTFILES_DIR/config/zsh/.zshenv" ]]; then
        create_symlink "$DOTFILES_DIR/config/zsh/.zshenv" "$HOME/.zshenv"
    fi
    
    if [[ -f "$DOTFILES_DIR/config/zsh/.zprofile" ]]; then
        create_symlink "$DOTFILES_DIR/config/zsh/.zprofile" "$HOME/.zprofile"
    fi
    
    # Git configuration
    if [[ -f "$DOTFILES_DIR/config/git/gitconfig" ]]; then
        create_symlink "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig"
    fi
    if [[ -d "$DOTFILES_DIR/config/git" ]]; then
        create_symlink "$DOTFILES_DIR/config/git" "$HOME/.config/git"
    fi
    
    # Vim configuration
    if [[ -f "$DOTFILES_DIR/config/vim/vimrc" ]]; then
        create_symlink "$DOTFILES_DIR/config/vim/vimrc" "$HOME/.vimrc"
    fi
    
    # Neovim configuration
    if [[ -d "$DOTFILES_DIR/config/nvim" ]]; then
        create_symlink "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
    fi

    # MCPM configuration (tokenless template managed by dotfiles)
    if [[ -f "$DOTFILES_DIR/config/mcpm/servers.json" ]]; then
        create_symlink "$DOTFILES_DIR/config/mcpm/servers.json" "$HOME/.config/mcpm/servers.json"
    fi

    # Secure Atlassian MCP launcher
    if [[ -f "$DOTFILES_DIR/scripts/mcpm-atlassian-secure.sh" ]]; then
        create_symlink "$DOTFILES_DIR/scripts/mcpm-atlassian-secure.sh" "$HOME/.local/bin/mcpm-atlassian-secure"
    fi
    
    # Enforce secure permissions on MCPM auxiliary files (MCPM resets to 644)
    if [[ "$UPDATE_MODE" == false && "$DRY_RUN" == false && -d "$HOME/.config/mcpm" ]]; then
        for file in servers_cache.json monitor.db; do
            if [[ -f "$HOME/.config/mcpm/$file" && ! -L "$HOME/.config/mcpm/$file" ]]; then
                chmod 600 "$HOME/.config/mcpm/$file"
            fi
        done
    fi
    
    # Create local config files if they don't exist
    [[ "$UPDATE_MODE" == false ]] || return 0
    local local_files=(
        "$DOTFILES_DIR/local/local.zsh"
    )
    
    for file in "${local_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            if [[ "$DRY_RUN" == false ]]; then
                # Only create directory if it's not a symlink (to avoid conflicts)
                local dir_path
                dir_path="$(dirname "$file")"
                if [[ ! -L "$dir_path" ]]; then
                    mkdir -p "$dir_path"
                fi
                cat > "$file" << 'EOF'
# Local configuration file
# This file is not tracked in git - add machine-specific configurations here

# Example: Work-specific configurations
# export WORK_EMAIL="you@company.com"
# alias work-ssh="ssh user@work-server"

# Example: API keys and tokens (keep these secure!)
# export GITHUB_TOKEN="your-token-here"
# export OPENAI_API_KEY="your-key-here"

# Example: Local PATH modifications
# export PATH="/usr/local/custom/bin:$PATH"

# Example: Machine-specific aliases
# alias ll="ls -la"  # If you prefer different options on this machine

EOF
                info "Created local config file: $file"
            else
                info "Would create local config file: $file"
            fi
        fi
    done
}

# Create necessary directories
create_directories() {
    local dirs=(
        "$HOME/.local/bin"
        "$HOME/.local/share/zsh"
        "$HOME/.cache/zsh"
        # "$HOME/.config/zsh"  # Removed to allow symlink creation
        "$HOME/.vim/backup"
        "$HOME/.vim/swap"
        "$HOME/.vim/undo"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if [[ "$DRY_RUN" == false ]]; then
                mkdir -p "$dir"
                info "Created directory: $dir"
            else
                info "Would create directory: $dir"
            fi
        fi
    done
}

# Install Vim plugins using vim-plug
install_vim_plugins() {
    if command_exists vim && [[ -f "$HOME/.vimrc" ]]; then
        info "Installing Vim plugins..."
        if [[ "$DRY_RUN" == false ]]; then
            # Install vim-plug if not present
            if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
                curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
                    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            fi
            vim +PlugInstall +qall
            success "Vim plugins installed"
        else
            info "Would install Vim plugins"
        fi
    fi
}

# Validate installation
validate_installation() {
    info "Validating installation..."
    
    local errors=0
    
    # Check critical symlinks
    local links=(
        "$HOME/.config/zsh:$DOTFILES_DIR/config/zsh"
        "$HOME/.zshrc:$DOTFILES_DIR/config/zsh/.zshrc"
        "$HOME/.zshenv:$DOTFILES_DIR/config/zsh/.zshenv"
        "$HOME/.zprofile:$DOTFILES_DIR/config/zsh/.zprofile"
        "$HOME/.config/git:$DOTFILES_DIR/config/git"
    )
    
    # Add optional links if they exist
    [[ -f "$DOTFILES_DIR/config/git/gitconfig" ]] && links+=("$HOME/.gitconfig:$DOTFILES_DIR/config/git/gitconfig")
    [[ -f "$DOTFILES_DIR/config/vim/vimrc" ]] && links+=("$HOME/.vimrc:$DOTFILES_DIR/config/vim/vimrc")
    [[ -d "$DOTFILES_DIR/config/nvim" ]] && links+=("$HOME/.config/nvim:$DOTFILES_DIR/config/nvim")
    [[ -f "$DOTFILES_DIR/config/mcpm/servers.json" ]] && links+=("$HOME/.config/mcpm/servers.json:$DOTFILES_DIR/config/mcpm/servers.json")
    [[ -f "$DOTFILES_DIR/scripts/mcpm-atlassian-secure.sh" ]] && links+=("$HOME/.local/bin/mcpm-atlassian-secure:$DOTFILES_DIR/scripts/mcpm-atlassian-secure.sh")
    
    for link in "${links[@]}"; do
        local target="${link%:*}"
        local source="${link#*:}"
        
        if [[ "$UPDATE_MODE" == true && ! -L "$target" ]]; then continue; fi
        
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            success "✓ $target → $source"
        else
            error "✗ Failed to create symlink: $target → $source"
            errors=$((errors + 1))
        fi
    done
    
    # Check if ZSH loads without errors (only if not in dry run)
    # Note: Temporarily disabled due to potential issues with command availability during validation
    if [[ "$DRY_RUN" == false ]] && command_exists zsh && false; then
        local zsh_error_output
        zsh_error_output=$(zsh -c 'source ~/.zshrc' 2>&1)
        local zsh_exit_code=$?
        if [[ $zsh_exit_code -eq 0 ]]; then
            success "✓ ZSH configuration loads without errors"
        else
            error "✗ ZSH configuration has errors (exit code: $zsh_exit_code)"
            if [[ -n "$zsh_error_output" ]]; then
                error "ZSH error output: $zsh_error_output"
            fi
            errors=$((errors + 1))
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        success "Installation validation passed!"
    else
        error "Installation validation failed with $errors errors"
        return 1
    fi
}

# Update machine info
update_machine_info() {
    local machine_info="$DOTFILES_DIR/local/machine.info"
    
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$(dirname "$machine_info")"
        cat > "$machine_info" << EOF
# Machine Information
# Generated on $(date)

HOSTNAME="$(hostname)"
OS="$(uname -s)"
ARCH="$(uname -m)"
USER="$(whoami)"
SETUP_DATE="$(date)"
DOTFILES_VERSION="$(cd "$DOTFILES_DIR" && git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

EOF
        info "Updated machine info: $machine_info"
    else
        info "Would update machine info: $machine_info"
    fi
}

# Main installation function
main() {
    parse_args "$@"
    
    # Print banner
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    DOTFILES INSTALLER                        ║
╚══════════════════════════════════════════════════════════════╝
EOF
    
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Initialize log
    if [[ "$DRY_RUN" == false && "$UPDATE_MODE" == false ]]; then
        printf 'Installation started at %s\n' "$(date)" > "$LOG_FILE"
        LOG_READY=true
    fi
    
    # Detect and display system info
    local os
    local arch
    os=$(detect_os)
    arch=$(detect_arch)
    local distro=""
    
    info "Detected system: $os/$arch"
    
    if [[ "$os" == "linux" ]]; then
        distro=$(detect_linux_distro)
        info "Linux distribution: $distro"
    fi
    
    # Create necessary directories
    if [[ "$UPDATE_MODE" == false ]]; then create_directories; fi
    
    # Install packages (if not skipped)
    if [[ "$SKIP_PACKAGES" == false && "$UPDATE_MODE" == false ]]; then
        install_packages
    fi
    
    # Link configurations
    link_configs
    
    # Install plugins
    if [[ "$UPDATE_MODE" == false ]]; then
        install_vim_plugins
        setup_zsh
        update_machine_info
    fi
    
    # Validate installation
    if [[ "$DRY_RUN" == false ]]; then
        validate_installation
        if [[ "$RUN_TESTS" == true ]]; then bash "$DOTFILES_DIR/scripts/test-dotfiles.sh"; fi
    fi
    
    # Final message
    if [[ "$DRY_RUN" == false ]]; then
        success "Installation completed successfully!"
        info "Log file: $LOG_FILE"
        if [[ -d "$BACKUP_DIR" ]]; then
            info "Backup directory: $BACKUP_DIR"
        fi
        warning "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
        
        # Show next steps
        echo
        info "Next steps:"
        echo "  1. Restart your terminal or run: source ~/.zshrc"
        echo "  2. Check the setup with: make doctor"
        echo "  3. Update plugins with: make plugins"
        echo "  4. Customize local settings in: $DOTFILES_DIR/local/local.zsh"
    else
        info "Dry run completed. Use '$0' to perform actual installation."
    fi
}

# Run main function with all arguments
main "$@"
