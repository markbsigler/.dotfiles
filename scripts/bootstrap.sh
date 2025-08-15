#!/usr/bin/env bash

# Bootstrap Script for Dotfiles
# This script sets up a new machine with dotfiles from scratch
# Usage: curl -fsSL https://raw.githubusercontent.com/username/dotfiles/main/scripts/bootstrap.sh | bash

set -euo pipefail

# Configuration
readonly REPO_URL="https://github.com/markbsigler/dotfiles.git"
readonly DOTFILES_DIR="$HOME/.dotfiles"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

info() { print_color "$BLUE" "ℹ️  $*"; }
success() { print_color "$GREEN" "✅ $*"; }
warning() { print_color "$YELLOW" "⚠️  $*"; }
error() { print_color "$RED" "❌ $*"; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux*) echo "linux" ;;
        *) echo "unknown" ;;
    esac
}

# Install prerequisites based on OS
install_prerequisites() {
    local os
    os=$(detect_os)
    
    info "Installing prerequisites for $os..."
    
    case "$os" in
        macos)
            # Install Xcode Command Line Tools
            if ! xcode-select -p >/dev/null 2>&1; then
                info "Installing Xcode Command Line Tools..."
                xcode-select --install
                
                # Wait for installation to complete
                until xcode-select -p >/dev/null 2>&1; do
                    sleep 5
                done
                success "Xcode Command Line Tools installed"
            fi
            
            # Install Homebrew
            if ! command_exists brew; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add Homebrew to PATH
                if [[ -f "/opt/homebrew/bin/brew" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -f "/usr/local/bin/brew" ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
                
                success "Homebrew installed"
            fi
            
            # Install essential tools via Homebrew
            brew install git curl zsh
            ;;
            
        linux)
            # Detect package manager and install prerequisites
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y git curl zsh build-essential
            elif command_exists yum; then
                sudo yum install -y git curl zsh gcc gcc-c++ make
            elif command_exists pacman; then
                sudo pacman -S --noconfirm git curl zsh base-devel
            else
                error "Unsupported Linux distribution"
                exit 1
            fi
            ;;
            
        *)
            error "Unsupported operating system: $os"
            exit 1
            ;;
    esac
    
    success "Prerequisites installed"
}

# Setup SSH key for GitHub (optional)
setup_ssh_key() {
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
        read -p "Would you like to generate an SSH key for GitHub? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter your email address: " email
            
            if [[ -n "$email" ]]; then
                info "Generating SSH key..."
                ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
                
                # Start ssh-agent and add key
                eval "$(ssh-agent -s)"
                ssh-add "$HOME/.ssh/id_ed25519"
                
                success "SSH key generated"
                warning "Please add the following public key to your GitHub account:"
                echo
                cat "$HOME/.ssh/id_ed25519.pub"
                echo
                read -p "Press Enter after adding the key to GitHub..."
            fi
        fi
    fi
}

# Clone dotfiles repository
clone_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        warning "Dotfiles directory already exists at $DOTFILES_DIR"
        read -p "Remove existing directory and re-clone? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$DOTFILES_DIR"
        else
            info "Using existing dotfiles directory"
            return 0
        fi
    fi
    
    info "Cloning dotfiles repository..."
    
    # Try SSH first, fall back to HTTPS
    if ssh -T git@github.com >/dev/null 2>&1; then
        git clone "git@github.com:$(echo "$REPO_URL" | sed 's|https://github.com/||').git" "$DOTFILES_DIR"
    else
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
    
    success "Dotfiles cloned to $DOTFILES_DIR"
}

# Run dotfiles installation
install_dotfiles() {
    info "Installing dotfiles..."
    
    cd "$DOTFILES_DIR"
    
    # Make install script executable
    chmod +x install.sh
    
    # Run installation
    ./install.sh
    
    success "Dotfiles installation completed"
}

# Configure git (if not already configured)
configure_git() {
    if ! git config --global user.name >/dev/null 2>&1; then
        read -p "Enter your Git username: " git_name
        git config --global user.name "$git_name"
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi
    
    success "Git configured"
}

# Final setup and recommendations
final_setup() {
    info "Running final setup..."
    
    # Set ZSH as default shell if it isn't already
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Setting ZSH as default shell..."
        if command_exists chsh; then
            chsh -s "$(which zsh)"
            success "ZSH set as default shell"
        else
            warning "Could not change default shell. Please run: chsh -s $(which zsh)"
        fi
    fi
    
    # Source the new configuration
    if [[ -f "$HOME/.zshrc" ]]; then
        info "Sourcing new ZSH configuration..."
        # Note: We can't actually source in this script due to shell differences
        success "ZSH configuration ready"
    fi
}

# Print final instructions
print_final_instructions() {
    success "🎉 Bootstrap completed successfully!"
    echo
    info "Next steps:"
    echo "  1. Restart your terminal or run 'exec zsh'"
    echo "  2. Verify everything works: cd ~/.dotfiles && make doctor"
    echo "  3. Customize local settings in ~/.config/zsh/local.zsh"
    echo "  4. Review and update configurations as needed"
    echo
    warning "If you encounter any issues:"
    echo "  - Check the installation log: cat ~/.dotfiles/install.log"
    echo "  - Run health check: cd ~/.dotfiles && make doctor"
    echo "  - Review the README: https://github.com/$(echo "$REPO_URL" | sed 's|https://github.com/||' | sed 's|\.git||')"
}

# Error handling
trap 'error "Bootstrap failed at line $LINENO"' ERR

# Main bootstrap function
main() {
    # Print banner
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    DOTFILES BOOTSTRAP                        ║
║                                                              ║
║  This script will set up your development environment       ║
║  with a complete dotfiles configuration.                    ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo
    
    # Confirmation
    read -p "Do you want to continue with the bootstrap process? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Bootstrap cancelled"
        exit 0
    fi
    
    # Check if we're running in a supported environment
    if [[ ! -t 0 ]] && [[ -z "${CI:-}" ]]; then
        warning "Running in non-interactive mode"
    fi
    
    # Run bootstrap steps
    info "Starting bootstrap process..."
    
    install_prerequisites
    configure_git
    setup_ssh_key
    clone_dotfiles
    install_dotfiles
    final_setup
    
    print_final_instructions
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
else
    # Script is being sourced
    warning "This script should be executed, not sourced"
fi
