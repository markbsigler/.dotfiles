#!/usr/bin/env bash
# =============================================================================
# Update All - Cross-Platform System Update Script
# =============================================================================
# Updates package managers, development tools, and dotfiles
# Supports: macOS (Homebrew), Linux (apt/dnf/pacman/Homebrew)
# =============================================================================

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
readonly LOG_FILE="$DOTFILES_DIR/logs/update-$(date +%Y%m%d-%H%M%S).log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Flags
DRY_RUN=false
VERBOSE=false
SKIP_SYSTEM=false
SKIP_DOTFILES=false
SKIP_PLUGINS=false

# =============================================================================
# Logging Functions
# =============================================================================

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ️  $*${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $*${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ $*${NC}" | tee -a "$LOG_FILE"
}

section() {
    echo -e "\n${CYAN}▶ $*${NC}\n" | tee -a "$LOG_FILE"
}

# =============================================================================
# OS Detection
# =============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*) echo "linux" ;;
        *) echo "unknown" ;;
    esac
}

detect_linux_distro() {
    if [[ ! -f /etc/os-release ]]; then
        echo "unknown"
        return
    fi
    
    awk -F= '/^ID=/{gsub(/"/,"",$2); print $2}' /etc/os-release
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# System Package Manager Updates
# =============================================================================

update_homebrew_macos() {
    if ! command_exists brew; then
        warning "Homebrew not installed"
        return 0
    fi
    
    section "Updating Homebrew (macOS)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update Homebrew packages"
        return 0
    fi
    
    info "Updating Homebrew..."
    brew update
    
    info "Upgrading installed packages..."
    brew upgrade
    
    info "Upgrading casks..."
    brew upgrade --cask --greedy
    
    info "Cleaning up old versions..."
    brew cleanup
    
    info "Running brew doctor..."
    brew doctor || warning "Brew doctor found some issues"
    
    success "Homebrew updated successfully"
}

update_apt() {
    if ! command_exists apt; then
        warning "APT not available"
        return 0
    fi
    
    section "Updating APT (Debian/Ubuntu)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update APT packages"
        return 0
    fi
    
    info "Updating package lists..."
    sudo apt update
    
    info "Upgrading packages..."
    sudo apt upgrade -y
    
    info "Upgrading distribution..."
    sudo apt dist-upgrade -y
    
    info "Removing unused packages..."
    sudo apt autoremove -y
    
    info "Cleaning package cache..."
    sudo apt autoclean
    
    success "APT updated successfully"
}

update_dnf() {
    if ! command_exists dnf; then
        warning "DNF not available"
        return 0
    fi
    
    section "Updating DNF (Fedora/RHEL)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update DNF packages"
        return 0
    fi
    
    info "Updating packages..."
    sudo dnf upgrade -y
    
    info "Removing unused packages..."
    sudo dnf autoremove -y
    
    info "Cleaning cache..."
    sudo dnf clean all
    
    success "DNF updated successfully"
}

update_pacman() {
    if ! command_exists pacman; then
        warning "Pacman not available"
        return 0
    fi
    
    section "Updating Pacman (Arch Linux)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update Pacman packages"
        return 0
    fi
    
    info "Updating package databases and upgrading..."
    sudo pacman -Syu --noconfirm
    
    info "Removing orphaned packages..."
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
    
    info "Cleaning cache..."
    sudo pacman -Sc --noconfirm
    
    success "Pacman updated successfully"
}

update_homebrew_linux() {
    # Check for Homebrew on Linux
    local brew_path=""
    
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        brew_path="$HOME/.linuxbrew/bin/brew"
    fi
    
    if [[ -z "$brew_path" ]]; then
        return 0
    fi
    
    section "Updating Homebrew (Linux)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update Homebrew packages"
        return 0
    fi
    
    info "Updating Homebrew..."
    "$brew_path" update
    
    info "Upgrading installed packages..."
    "$brew_path" upgrade
    
    info "Cleaning up old versions..."
    "$brew_path" cleanup
    
    success "Homebrew (Linux) updated successfully"
}

# =============================================================================
# Version Manager Updates
# =============================================================================

update_nvm() {
    if [[ ! -d "$HOME/.nvm" ]]; then
        return 0
    fi
    
    section "Updating NVM (Node Version Manager)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update NVM"
        return 0
    fi
    
    info "Updating NVM..."
    (
        cd "$HOME/.nvm"
        git fetch --tags origin
        local latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
        git checkout "$latest_tag"
    )
    
    success "NVM updated to latest version"
}

update_pyenv() {
    if [[ ! -d "$HOME/.pyenv" ]]; then
        return 0
    fi
    
    section "Updating pyenv (Python Version Manager)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update pyenv"
        return 0
    fi
    
    info "Updating pyenv..."
    (cd "$HOME/.pyenv" && git pull)
    
    # Update pyenv plugins
    if [[ -d "$HOME/.pyenv/plugins" ]]; then
        for plugin in "$HOME/.pyenv/plugins"/*; do
            if [[ -d "$plugin/.git" ]]; then
                info "Updating $(basename "$plugin")..."
                (cd "$plugin" && git pull)
            fi
        done
    fi
    
    success "pyenv updated successfully"
}

update_rbenv() {
    if [[ ! -d "$HOME/.rbenv" ]]; then
        return 0
    fi
    
    section "Updating rbenv (Ruby Version Manager)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update rbenv"
        return 0
    fi
    
    info "Updating rbenv..."
    (cd "$HOME/.rbenv" && git pull)
    
    # Update ruby-build
    if [[ -d "$HOME/.rbenv/plugins/ruby-build" ]]; then
        info "Updating ruby-build..."
        (cd "$HOME/.rbenv/plugins/ruby-build" && git pull)
    fi
    
    success "rbenv updated successfully"
}

update_rustup() {
    if ! command_exists rustup; then
        return 0
    fi
    
    section "Updating Rust (rustup)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update Rust"
        return 0
    fi
    
    info "Updating rustup and Rust..."
    rustup update
    
    success "Rust updated successfully"
}

# =============================================================================
# Language Package Manager Updates
# =============================================================================

update_npm_global() {
    if ! command_exists npm; then
        return 0
    fi
    
    section "Updating NPM Global Packages"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update NPM global packages"
        return 0
    fi
    
    info "Updating npm itself..."
    npm install -g npm@latest
    
    info "Updating global packages..."
    npm update -g
    
    success "NPM global packages updated"
}

update_pip() {
    if ! command_exists pip3; then
        return 0
    fi
    
    section "Updating pip (Python)"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update pip"
        return 0
    fi
    
    info "Updating pip..."
    pip3 install --upgrade pip
    
    success "pip updated successfully"
}

update_gem() {
    if ! command_exists gem; then
        return 0
    fi
    
    section "Updating RubyGems"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update RubyGems"
        return 0
    fi
    
    info "Updating RubyGems..."
    gem update --system
    
    info "Updating installed gems..."
    gem update
    
    success "RubyGems updated successfully"
}

# =============================================================================
# Zsh Plugin Updates
# =============================================================================

update_zsh_plugins() {
    local plugin_dir="$HOME/.local/share/zsh/plugins"
    
    if [[ ! -d "$plugin_dir" ]]; then
        return 0
    fi
    
    section "Updating Zsh Plugins"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update Zsh plugins"
        return 0
    fi
    
    local updated=0
    local failed=0
    
    for plugin in "$plugin_dir"/*; do
        if [[ -d "$plugin/.git" ]]; then
            local plugin_name=$(basename "$plugin")
            info "Updating $plugin_name..."
            
            if (cd "$plugin" && git pull --quiet); then
                ((updated++))
            else
                error "Failed to update $plugin_name"
                ((failed++))
            fi
        fi
    done
    
    if [[ $updated -gt 0 ]]; then
        success "Updated $updated Zsh plugin(s)"
    fi
    
    if [[ $failed -gt 0 ]]; then
        warning "$failed plugin(s) failed to update"
    fi
}

# =============================================================================
# Dotfiles Update
# =============================================================================

update_dotfiles() {
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        warning "Dotfiles directory is not a git repository"
        return 0
    fi
    
    section "Updating Dotfiles"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would update dotfiles"
        return 0
    fi
    
    info "Checking for dotfiles updates..."
    (
        cd "$DOTFILES_DIR"
        
        # Check for uncommitted changes
        if [[ -n "$(git status --porcelain)" ]]; then
            warning "Dotfiles have uncommitted changes"
            git status --short
            return 0
        fi
        
        # Pull latest changes
        local current_branch=$(git branch --show-current)
        info "Pulling latest changes on branch: $current_branch"
        git pull
        
        success "Dotfiles updated successfully"
    )
}

# =============================================================================
# Cleanup Operations
# =============================================================================

cleanup_system() {
    section "Cleaning up system"
    
    # Remove old log files (older than 30 days)
    if [[ -d "$DOTFILES_DIR/logs" ]]; then
        info "Removing old log files..."
        find "$DOTFILES_DIR/logs" -name "*.log" -mtime +30 -delete 2>/dev/null || true
    fi
    
    # Remove old backup directories (older than 30 days)
    info "Removing old backup directories..."
    find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    
    success "Cleanup completed"
}

# =============================================================================
# Help Function
# =============================================================================

show_help() {
    cat << EOF
Update All - Cross-Platform System Update Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -d, --dry-run           Show what would be done without doing it
    -v, --verbose           Verbose output
    --skip-system           Skip system package manager updates
    --skip-dotfiles         Skip dotfiles update
    --skip-plugins          Skip plugin updates

EXAMPLES:
    $0                      # Update everything
    $0 --dry-run            # Preview updates
    $0 --skip-system        # Update only dotfiles and plugins

SUPPORTED PLATFORMS:
    - macOS (Homebrew)
    - Ubuntu/Debian (APT)
    - Fedora/RHEL (DNF)
    - Arch Linux (Pacman)
    - Linux with Homebrew

WHAT GETS UPDATED:
    - System package manager (brew/apt/dnf/pacman)
    - Homebrew packages and casks
    - Version managers (nvm, pyenv, rbenv, rustup)
    - Language package managers (npm, pip, gem)
    - Zsh plugins
    - Dotfiles repository

LOG FILE:
    $LOG_FILE

EOF
}

# =============================================================================
# Argument Parsing
# =============================================================================

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
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --skip-system)
                SKIP_SYSTEM=true
                shift
                ;;
            --skip-dotfiles)
                SKIP_DOTFILES=true
                shift
                ;;
            --skip-plugins)
                SKIP_PLUGINS=true
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

# =============================================================================
# Main Function
# =============================================================================

main() {
    parse_args "$@"
    
    # Print banner
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    UPDATE ALL SYSTEMS                        ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    local os=$(detect_os)
    info "Detected OS: $os"
    
    if [[ "$os" == "linux" ]]; then
        local distro=$(detect_linux_distro)
        info "Linux distribution: $distro"
    fi
    
    log "Update started at $(date)"
    
    # System updates
    if [[ "$SKIP_SYSTEM" == false ]]; then
        case "$os" in
            macos)
                update_homebrew_macos
                ;;
            linux)
                local distro=$(detect_linux_distro)
                case "$distro" in
                    ubuntu|debian)
                        update_apt
                        ;;
                    fedora|rhel|centos)
                        update_dnf
                        ;;
                    arch|manjaro)
                        update_pacman
                        ;;
                esac
                update_homebrew_linux
                ;;
        esac
    fi
    
    # Version managers
    update_nvm
    update_pyenv
    update_rbenv
    update_rustup
    
    # Language package managers
    update_npm_global
    update_pip
    update_gem
    
    # Plugins
    if [[ "$SKIP_PLUGINS" == false ]]; then
        update_zsh_plugins
    fi
    
    # Dotfiles
    if [[ "$SKIP_DOTFILES" == false ]]; then
        update_dotfiles
    fi
    
    # Cleanup
    cleanup_system
    
    # Summary
    echo ""
    success "All updates completed!"
    info "Log file: $LOG_FILE"
    
    log "Update completed at $(date)"
}

# Run main function
main "$@"

