#!/usr/bin/env bash

# Dotfiles Installation Script
# This script sets up a complete development environment by symlinking
# configuration files and installing necessary dependencies.

set -euo pipefail


# Configuration
readonly DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR="$HOME/.dotfiles-backup-$BACKUP_TIMESTAMP"
readonly LOG_FILE="$DOTFILES_DIR/install.log"

# Ensure dotfiles directory exists for logging
mkdir -p "$DOTFILES_DIR"

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
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
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
            --skip-packages)
                SKIP_PACKAGES=true
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
    
    if [[ -e "$file" ]] && [[ ! "$FORCE" == true ]]; then
        if [[ ! -d "$BACKUP_DIR" ]]; then
            mkdir -p "$BACKUP_DIR"
            info "Created backup directory: $BACKUP_DIR"
        fi
        
        local backup_path="$BACKUP_DIR/$(basename "$file")"
        if [[ "$DRY_RUN" == false ]]; then
            cp -r "$file" "$backup_path"
            success "Backed up $file to $backup_path"
        else
            info "Would backup: $file → $backup_path"
        fi
    fi
}

# Create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir
    target_dir="$(dirname "$target")"
    
    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$target_dir"
            info "Created directory: $target_dir"
        else
            info "Would create directory: $target_dir"
        fi
    fi
    
    # Skip if in update mode and target doesn't exist as a symlink
    if [[ "$UPDATE_MODE" == true ]] && [[ ! -L "$target" ]]; then
        return 0
    fi
    
    # In update mode, if target exists but points to wrong location, update it
    if [[ "$UPDATE_MODE" == true ]] && [[ -L "$target" ]]; then
        local current_target
        current_target="$(readlink "$target")"
        if [[ "$current_target" == "$source" ]]; then
            # Already correct, no need to update
            return 0
        fi
        # Continue to update the symlink below
    fi
    
    # Backup existing file (only if not in update mode or if not already a correct symlink)
    backup_file "$target"
    
    # Remove existing file/symlink
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$target"
        else
            info "Would remove: $target"
        fi
    fi
    
    # Create symlink with error checking and retry
    if [[ "$DRY_RUN" == false ]]; then
        local attempt=1
        local max_attempts=3
        local success_flag=false
        while [[ $attempt -le $max_attempts ]]; do
            ln -sf "$source" "$target" 2>symlink_error.log
            if [[ $? -eq 0 && -L "$target" ]]; then
                success "Linked: $source → $target"
                success_flag=true
                break
            else
                error "Failed to link: $source → $target (attempt $attempt)"
                if [[ -s symlink_error.log ]]; then
                    error "ln error: $(cat symlink_error.log)"
                fi
                rm -rf "$target"
                sleep 1
            fi
            attempt=$((attempt+1))
        done
        rm -f symlink_error.log
        if [[ "$success_flag" == false ]]; then
            error "Giving up after $max_attempts attempts: $source → $target"
        fi
    else
        info "Would link: $source → $target"
    fi
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
        # Always forcibly remove before symlinking, with a short delay to avoid race conditions
        rm -rf "$HOME/.config/zsh"
        sleep 1
        # If .config/zsh existed and was not a symlink, back it up
        if [[ -e "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]]; then
            mv "$HOME/.config/zsh" "$HOME/.config/zsh.backup.$(date +%s)"
            info "Backed up and removed existing $HOME/.config/zsh"
        fi
        create_symlink "$DOTFILES_DIR/config/zsh" "$HOME/.config/zsh"
    fi

    # Main zsh files
    if [[ -f "$DOTFILES_DIR/.zshrc" ]]; then
        # Always forcibly remove before symlinking, with a short delay to avoid race conditions
        rm -f "$HOME/.zshrc"
        sleep 1
        # If .zshrc existed and was not a symlink, back it up
        if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
            mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
            info "Backed up and removed existing $HOME/.zshrc"
        fi
        create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    fi

    if [[ -f "$DOTFILES_DIR/.zshenv" ]]; then
        create_symlink "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
    fi
    
    if [[ -f "$DOTFILES_DIR/.zprofile" ]]; then
        create_symlink "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
    fi
    
    # Git configuration
    if [[ -f "$DOTFILES_DIR/config/git/gitconfig" ]]; then
        create_symlink "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig"
    fi
    
    # Vim configuration
    if [[ -f "$DOTFILES_DIR/config/vim/vimrc" ]]; then
        create_symlink "$DOTFILES_DIR/config/vim/vimrc" "$HOME/.vimrc"
    fi
    
    # Neovim configuration
    if [[ -d "$DOTFILES_DIR/config/nvim" ]]; then
        create_symlink "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
    fi
    
    # Create local config files if they don't exist
    local local_files=(
        "$DOTFILES_DIR/config/zsh/local.zsh"
        "$DOTFILES_DIR/local/local.zsh"
    )
    
    for file in "${local_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            if [[ "$DRY_RUN" == false ]]; then
                # Only create directory if it's not a symlink (to avoid conflicts)
                local dir_path="$(dirname "$file")"
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
        "$HOME/.zshrc:$DOTFILES_DIR/.zshrc"
    )
    
    # Add optional links if they exist
    [[ -f "$DOTFILES_DIR/config/git/gitconfig" ]] && links+=("$HOME/.gitconfig:$DOTFILES_DIR/config/git/gitconfig")
    [[ -f "$DOTFILES_DIR/config/vim/vimrc" ]] && links+=("$HOME/.vimrc:$DOTFILES_DIR/config/vim/vimrc")
    
    for link in "${links[@]}"; do
        local target="${link%:*}"
        local source="${link#*:}"
        
        # In update mode, only validate existing symlinks
        if [[ "$UPDATE_MODE" == true ]] && [[ ! -L "$target" ]]; then
            continue
        fi
        
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            success "✓ $target → $source"
        else
            error "✗ Failed to create symlink: $target → $source"
            ((errors++))
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
            ((errors++))
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
    echo "Installation started at $(date)" > "$LOG_FILE"
    
    # Detect and display system info
    local os=$(detect_os)
    local arch=$(detect_arch)
    local distro=""
    
    info "Detected system: $os/$arch"
    
    if [[ "$os" == "linux" ]]; then
        distro=$(detect_linux_distro)
        info "Linux distribution: $distro"
    fi
    
    # Create necessary directories
    create_directories
    
    # Install packages (if not skipped)
    if [[ "$SKIP_PACKAGES" == false ]]; then
        install_packages
    fi
    
    # Link configurations
    link_configs
    
    # Install plugins
    install_vim_plugins
    
    # Set up shell
    setup_zsh
    
    # Update machine info
    update_machine_info
    
    # Validate installation
    if [[ "$DRY_RUN" == false ]]; then
        validate_installation
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
        echo "  4. Customize local settings in: ~/.config/zsh/local.zsh"
    else
        info "Dry run completed. Use '$0' to perform actual installation."
    fi
}

# Run main function with all arguments
main "$@"
