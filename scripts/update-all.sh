#!/usr/bin/env bash
# Update all package managers and tools
# Cross-platform update script for macOS and Linux

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
VERBOSE=false
DRY_RUN=false

# Logging functions
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }
section() { echo -e "${CYAN}━━━ $* ━━━${NC}"; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Show help
show_help() {
    cat << EOF
Update All - Cross-Platform Package & Tool Updater

Updates system packages, language version managers, and development tools.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Verbose output
    -d, --dry-run       Show what would be updated without making changes
    --skip-system       Skip system package managers (brew/apt/etc)
    --skip-plugins      Skip zsh plugins update
    --skip-vim          Skip vim plugins update
    --skip-vms          Skip version managers update

WHAT GETS UPDATED:
    System:
      - Homebrew (macOS)
      - APT (Ubuntu/Debian)
      - DNF (Fedora/RHEL)
      - Pacman (Arch Linux)

    Development Tools:
      - ZSH plugins
      - Vim/Neovim plugins
      - Version managers (nvm, pyenv, rbenv, rustup)

    Dotfiles:
      - Git repository pull (if remote configured)

EXAMPLES:
    $0                      # Update everything
    $0 --verbose            # Show detailed output
    $0 --skip-system        # Update only plugins and VMs
    $0 --dry-run            # Preview updates without applying

EOF
}

# Parse arguments
SKIP_SYSTEM=false
SKIP_PLUGINS=false
SKIP_VIM=false
SKIP_VMS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-system)
            SKIP_SYSTEM=true
            shift
            ;;
        --skip-plugins)
            SKIP_PLUGINS=true
            shift
            ;;
        --skip-vim)
            SKIP_VIM=true
            shift
            ;;
        --skip-vms)
            SKIP_VMS=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*) echo "linux" ;;
        *) echo "unknown" ;;
    esac
}

# Update system packages
update_system() {
    if [[ "$SKIP_SYSTEM" == true ]]; then
        warning "Skipping system package updates"
        return 0
    fi
    
    section "System Package Updates"
    local os
    os=$(detect_os)
    
    case "$os" in
        macos)
            if command_exists brew; then
                info "Updating Homebrew..."
                [[ "$DRY_RUN" == false ]] && brew update || info "DRY RUN: Would run 'brew update'"
                
                info "Upgrading Homebrew packages..."
                if [[ "$DRY_RUN" == false ]]; then
                    brew upgrade
                    success "Homebrew packages upgraded"
                else
                    brew outdated
                    info "DRY RUN: Would run 'brew upgrade'"
                fi
                
                info "Cleaning up Homebrew..."
                [[ "$DRY_RUN" == false ]] && brew cleanup || info "DRY RUN: Would run 'brew cleanup'"
                
                success "Homebrew update complete"
            else
                warning "Homebrew not found"
            fi
            ;;
        linux)
            # Detect Linux distro
            if [[ -f /etc/os-release ]]; then
                local distro
                distro=$(awk -F= '/^ID=/{gsub(/"/,"",$2); print $2}' /etc/os-release)
                
                case "$distro" in
                    ubuntu|debian)
                        if command_exists apt; then
                            info "Updating APT..."
                            [[ "$DRY_RUN" == false ]] && sudo apt update || info "DRY RUN: Would run 'sudo apt update'"
                            
                            info "Upgrading APT packages..."
                            [[ "$DRY_RUN" == false ]] && sudo apt upgrade -y || info "DRY RUN: Would run 'sudo apt upgrade -y'"
                            
                            info "Cleaning up APT..."
                            [[ "$DRY_RUN" == false ]] && sudo apt autoremove -y || info "DRY RUN: Would run 'sudo apt autoremove -y'"
                            
                            success "APT update complete"
                        fi
                        ;;
                    fedora|rhel|centos)
                        if command_exists dnf; then
                            info "Updating DNF..."
                            [[ "$DRY_RUN" == false ]] && sudo dnf upgrade -y || info "DRY RUN: Would run 'sudo dnf upgrade -y'"
                            success "DNF update complete"
                        elif command_exists yum; then
                            info "Updating YUM..."
                            [[ "$DRY_RUN" == false ]] && sudo yum update -y || info "DRY RUN: Would run 'sudo yum update -y'"
                            success "YUM update complete"
                        fi
                        ;;
                    arch|manjaro)
                        if command_exists pacman; then
                            info "Updating Pacman..."
                            [[ "$DRY_RUN" == false ]] && sudo pacman -Syu --noconfirm || info "DRY RUN: Would run 'sudo pacman -Syu'"
                            success "Pacman update complete"
                        fi
                        ;;
                    *)
                        warning "Unknown Linux distro: $distro"
                        ;;
                esac
            fi
            ;;
        *)
            warning "Unknown OS: $os"
            ;;
    esac
    echo
}

# Update ZSH plugins
update_zsh_plugins() {
    if [[ "$SKIP_PLUGINS" == true ]]; then
        warning "Skipping ZSH plugins update"
        return 0
    fi
    
    section "ZSH Plugins Update"
    local plugin_dir="$HOME/.local/share/zsh/plugins"
    
    if [[ ! -d "$plugin_dir" ]]; then
        warning "ZSH plugins directory not found: $plugin_dir"
        return 0
    fi
    
    local updated=0
    local failed=0
    
    for plugin in "$plugin_dir"/*; do
        if [[ -d "$plugin/.git" ]]; then
            local plugin_name
            plugin_name=$(basename "$plugin")
            info "Updating $plugin_name..."
            
            if [[ "$DRY_RUN" == false ]]; then
                if (cd "$plugin" && git pull --quiet); then
                    success "$plugin_name updated"
                    ((updated++))
                else
                    error "$plugin_name failed to update"
                    ((failed++))
                fi
            else
                info "DRY RUN: Would update $plugin_name"
                ((updated++))
            fi
        fi
    done
    
    if [[ $updated -gt 0 ]]; then
        success "Updated $updated ZSH plugin(s)"
    fi
    if [[ $failed -gt 0 ]]; then
        warning "$failed ZSH plugin(s) failed to update"
    fi
    echo
}

# Update Vim/Neovim plugins
update_vim_plugins() {
    if [[ "$SKIP_VIM" == true ]]; then
        warning "Skipping Vim plugins update"
        return 0
    fi
    
    section "Vim/Neovim Plugins Update"
    
    if command_exists nvim && [[ -f "$HOME/.config/nvim/init.vim" ]]; then
        info "Updating Neovim plugins..."
        if [[ "$DRY_RUN" == false ]]; then
            nvim +PlugUpdate +qall 2>/dev/null || warning "Neovim plugin update failed"
            success "Neovim plugins updated"
        else
            info "DRY RUN: Would run 'nvim +PlugUpdate +qall'"
        fi
    elif command_exists vim && [[ -f "$HOME/.vimrc" ]]; then
        info "Updating Vim plugins..."
        if [[ "$DRY_RUN" == false ]]; then
            vim +PlugUpdate +qall 2>/dev/null || warning "Vim plugin update failed"
            success "Vim plugins updated"
        else
            info "DRY RUN: Would run 'vim +PlugUpdate +qall'"
        fi
    else
        warning "Vim/Neovim not configured"
    fi
    echo
}

# Update version managers
update_version_managers() {
    if [[ "$SKIP_VMS" == true ]]; then
        warning "Skipping version managers update"
        return 0
    fi
    
    section "Version Managers Update"
    
    # Update NVM
    if [[ -d "$HOME/.nvm" ]]; then
        info "Updating NVM..."
        if [[ "$DRY_RUN" == false ]]; then
            (cd "$HOME/.nvm" && git pull --quiet) && success "NVM updated" || warning "NVM update failed"
        else
            info "DRY RUN: Would update NVM"
        fi
    fi
    
    # Update pyenv
    if [[ -d "$HOME/.pyenv" ]]; then
        info "Updating pyenv..."
        if [[ "$DRY_RUN" == false ]]; then
            (cd "$HOME/.pyenv" && git pull --quiet) && success "pyenv updated" || warning "pyenv update failed"
        else
            info "DRY RUN: Would update pyenv"
        fi
    fi
    
    # Update rbenv
    if [[ -d "$HOME/.rbenv" ]]; then
        info "Updating rbenv..."
        if [[ "$DRY_RUN" == false ]]; then
            (cd "$HOME/.rbenv" && git pull --quiet) && success "rbenv updated" || warning "rbenv update failed"
            if [[ -d "$HOME/.rbenv/plugins/ruby-build" ]]; then
                (cd "$HOME/.rbenv/plugins/ruby-build" && git pull --quiet) && success "ruby-build updated" || warning "ruby-build update failed"
            fi
        else
            info "DRY RUN: Would update rbenv"
        fi
    fi
    
    # Update rustup
    if command_exists rustup; then
        info "Updating Rust toolchain..."
        [[ "$DRY_RUN" == false ]] && rustup update && success "Rust updated" || info "DRY RUN: Would run 'rustup update'"
    fi
    echo
}

# Update dotfiles repository
update_dotfiles() {
    section "Dotfiles Repository"
    
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        info "Checking dotfiles repository..."
        
        if git -C "$DOTFILES_DIR" remote | grep -q origin; then
            if [[ "$DRY_RUN" == false ]]; then
                info "Pulling latest changes..."
                git -C "$DOTFILES_DIR" pull && success "Dotfiles updated" || warning "Dotfiles update failed"
            else
                info "DRY RUN: Would run 'git pull' in $DOTFILES_DIR"
            fi
        else
            warning "No remote configured for dotfiles repository"
        fi
        
        # Show status
        if [[ "$VERBOSE" == true ]]; then
            info "Dotfiles status:"
            git -C "$DOTFILES_DIR" status --short
        fi
    else
        warning "Dotfiles directory is not a git repository"
    fi
    echo
}

# Main function
main() {
    echo
    info "🔄 Starting system update..."
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    echo
    
    update_system
    update_zsh_plugins
    update_vim_plugins
    update_version_managers
    update_dotfiles
    
    section "Update Complete!"
    success "All updates finished"
    echo
    info "To apply shell changes, run: source ~/.zshrc"
    echo
}

# Run main function
main

exit 0

