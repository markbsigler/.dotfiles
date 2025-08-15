# Detect if a Nerd Font is installed (checks for Agave Nerd Font by default)
has_nerd_font() {
    fc-list | grep -i "Nerd Font" | grep -q "FiraCode" && return 0
    return 1
}

# Install Nerd Font (Agave) on macOS using Homebrew
install_nerd_font_macos() {
    # Check if Agave Nerd Font is already installed
    if [[ $(brew list --cask 2>/dev/null | grep -c font-agave-nerd-font) -eq 1 ]]; then
        success "Nerd Font (Agave) is already installed."
        return 0
    fi
    info "Installing Agave Nerd Font via Homebrew..."
    brew tap homebrew/cask-fonts
    brew install --cask font-agave-nerd-font
    success "Agave Nerd Font installed! Please set it in your terminal preferences."
}

# Install Nerd Font (Agave) on Linux (downloads from GitHub)
install_nerd_font_linux() {
    if has_nerd_font; then
        success "Nerd Font (Agave) is already installed."
        return 0
    fi
    info "Installing Agave Nerd Font..."
    local version="3.1.1"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/Agave.zip"
    mkdir -p ~/.local/share/fonts
    wget -O /tmp/Agave.zip "$url"
    unzip -o /tmp/Agave.zip -d ~/.local/share/fonts/AgaveNerdFont
    fc-cache -fv
    rm /tmp/Agave.zip
    success "Agave Nerd Font installed! Please set it in your terminal preferences."
}
#!/usr/bin/env bash
# Cross-platform package installation script

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }

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
        armv7l) echo "arm" ;;
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install a package if it doesn't exist
install_if_missing() {
    local package="$1"
    local install_cmd="$2"
    local check_cmd="${3:-$package}"
    
    if command_exists "$check_cmd"; then
        info "$package is already installed"
        return 0
    fi
    
    info "Installing $package..."
    
    # Temporarily disable exit on error for the install command
    set +e
    local output
    output=$(eval "$install_cmd" 2>&1)
    local install_result=$?
    set -e
    
    # Check if the package is now available, regardless of install command exit code
    if command_exists "$check_cmd"; then
        success "$package is available"
        return 0
    else
        # If brew reports already installed, treat as success (broaden match)
        if [[ "$output" == *"already installed"* ]] || [[ "$output" == *"is already installed"* ]] || [[ "$output" == *"up-to-date"* ]] || [[ "$output" == *"Warning: "* && "$output" == *"is already installed"* ]]; then
            warning "$package was already installed (brew output)"
            return 0
        fi
        # If Homebrew output indicates a successful install (for plugins, fonts, etc.)
        if [[ "$output" == *"Pouring"* ]] || [[ "$output" == *"Caveats"* ]] || [[ "$output" == *"Summary"* ]]; then
            success "$package was installed (brew output)"
            return 0
        fi
        if [[ $install_result -eq 0 ]]; then
            error "Failed to install $package (exit code: 0). Output: $output"
        else
            error "Failed to install $package (exit code: $install_result). Output: $output"
        fi
        return 1
    fi
}

# Package installation functions
install_packages_macos() {
    info "Installing macOS packages..."
    
    # Install Homebrew if not present
    if ! command_exists brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ "$(uname -m)" == "arm64" ]]; then
            export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        else
            export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
        fi
    fi
    
    # Update Homebrew
    brew update
    
    # Core utilities
    local core_packages=(
        "coreutils"
        "findutils" 
        "gnu-tar"
        "gnu-which"
        "gnu-sed"
        "gawk"
        "grep"
    )
    
    # Development tools
    local dev_packages=(
        "git"
        "git-lfs"
        "gh"
        "vim"
        "neovim"
        "curl"
        "wget"
        "httpie"
        "shellcheck"
    )
    
    # Shell enhancements
    local shell_packages=(
        "zsh"
        "zsh-completions"
        "zsh-syntax-highlighting"
        "zsh-autosuggestions"
    )
    
    # Modern CLI tools
    local modern_packages=(
        "bat"
        "eza"
        "fd"
        "fzf"
        "ripgrep"
        "tree"
        "jq"
        "htop"
        "ncdu"
        "tldr"
        "thefuck"
    )
    
    # Development languages and tools
    local lang_packages=(
        "node"
        "python@3.11"
        "go"
        "rust"
        "ruby"
        "openjdk"
    )
    
    # Optional packages
    local optional_packages=(
        "docker"
        "docker-compose"
        "tmux"
        "screen"
        "ansible"
        "terraform"
    )
    
    # Install package groups
    for package in "${core_packages[@]}"; do
        install_if_missing "$package" "brew install $package"
    done
    
    for package in "${dev_packages[@]}"; do
        install_if_missing "$package" "brew install $package"
    done
    
    for package in "${shell_packages[@]}"; do
        install_if_missing "$package" "brew install $package"
    done
    
    for package in "${modern_packages[@]}"; do
        install_if_missing "$package" "brew install $package"
    done
    
    for package in "${lang_packages[@]}"; do
        install_if_missing "$package" "brew install $package"
    done

    # Install Nerd Font
    install_nerd_font_macos
    
    # Ask about optional packages
    info "Optional packages available:"
    for package in "${optional_packages[@]}"; do
        if ! command_exists "$package"; then
            read -p "Install $package? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                brew install "$package"
            fi
        fi
    done
    
    success "macOS package installation completed!"
}

install_packages_ubuntu() {
    info "Installing Ubuntu/Debian packages..."
    
    # Update package list
    sudo apt update
    
    # Core packages
    local core_packages=(
        "git"
        "curl"
        "wget"
        "vim"
        "neovim"
        "zsh"
        "build-essential"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )
    
    # Development tools
    local dev_packages=(
        "python3"
        "python3-pip"
        "python3-venv"
        "nodejs"
        "npm"
        "ruby"
        "ruby-dev"
        "openjdk-11-jdk"
        "golang-go"
        "shellcheck"
    )
    
    # CLI tools available in apt
    local cli_packages=(
        "tree"
        "htop"
        "ncdu"
        "jq"
        "unzip"
        "zip"
        "p7zip-full"
        "tmux"
        "screen"
        "silversearcher-ag"
    )
    
    # Install core packages
    info "Installing core packages..."
    sudo apt install -y "${core_packages[@]}"
    
    # Install development packages
    info "Installing development packages..."
    sudo apt install -y "${dev_packages[@]}"
    
    # Install CLI tools
    info "Installing CLI tools..."
    sudo apt install -y "${cli_packages[@]}"
    
    # Install modern CLI tools (may require manual installation)
    install_modern_tools_ubuntu
    
    # Install zsh plugins
    install_zsh_plugins_ubuntu

    # Install Nerd Font
    install_nerd_font_linux
    
    success "Ubuntu package installation completed!"
install_nerd_font_windows() {
    warning "Please manually install a Nerd Font (e.g., Agave Nerd Font) from https://www.nerdfonts.com/font-downloads and set it in your terminal preferences."
}
}

install_modern_tools_ubuntu() {
    info "Installing modern CLI tools..."
    
    # Create local bin directory
    mkdir -p "$HOME/.local/bin"
    
    # Install bat (better cat)
    if ! command_exists bat && ! command_exists batcat; then
        if command_exists batcat; then
            ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        else
            local bat_version="0.24.0"
            local bat_url="https://github.com/sharkdp/bat/releases/download/v${bat_version}/bat_${bat_version}_amd64.deb"
            wget -O /tmp/bat.deb "$bat_url"
            sudo dpkg -i /tmp/bat.deb
            rm /tmp/bat.deb
        fi
    fi
    
    # Install fd (better find)
    if ! command_exists fd && ! command_exists fdfind; then
        local fd_version="8.7.1"
        local fd_url="https://github.com/sharkdp/fd/releases/download/v${fd_version}/fd_${fd_version}_amd64.deb"
        wget -O /tmp/fd.deb "$fd_url"
        sudo dpkg -i /tmp/fd.deb
        rm /tmp/fd.deb
        # Create fd symlink if only fdfind exists
    elif command_exists fdfind && ! command_exists fd; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
    
    # Install ripgrep (better grep)
    if ! command_exists rg; then
        local rg_version="13.0.0"
        local rg_url="https://github.com/BurntSushi/ripgrep/releases/download/${rg_version}/ripgrep_${rg_version}_amd64.deb"
        wget -O /tmp/ripgrep.deb "$rg_url"
        sudo dpkg -i /tmp/ripgrep.deb
        rm /tmp/ripgrep.deb
    fi
    
    # Install eza (better ls) - from GitHub releases
    if ! command_exists eza; then
        local eza_version="0.18.2"
        local arch="$(detect_arch)"
        [[ "$arch" == "amd64" ]] && arch="x86_64"
        local eza_url="https://github.com/eza-community/eza/releases/download/v${eza_version}/eza_${arch}-unknown-linux-gnu.tar.gz"
        wget -O /tmp/eza.tar.gz "$eza_url"
        tar -xzf /tmp/eza.tar.gz -C /tmp
        mv /tmp/eza "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/eza"
        rm /tmp/eza.tar.gz
    fi
    
    # Install fzf (fuzzy finder)
    if ! command_exists fzf; then
        if [[ -d "$HOME/.fzf" ]]; then
            warning "fzf directory already exists, updating..."
            cd "$HOME/.fzf" && git pull
        else
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        fi
        "$HOME/.fzf/install" --all --no-bash --no-fish
    fi
    
    # Install GitHub CLI
    if ! command_exists gh; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
    fi
    
    success "Modern CLI tools installed!"
}

install_zsh_plugins_ubuntu() {
    info "Installing ZSH plugins..."
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting" ]]; then
        mkdir -p "$HOME/.local/share/zsh/plugins"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting"
    fi
    
    # Install zsh-autosuggestions
    if [[ ! -d "$HOME/.local/share/zsh/plugins/zsh-autosuggestions" ]]; then
        mkdir -p "$HOME/.local/share/zsh/plugins"
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "$HOME/.local/share/zsh/plugins/zsh-autosuggestions"
    fi
    
    # Install fzf-tab
    if [[ ! -d "$HOME/.local/share/zsh/plugins/fzf-tab" ]]; then
        mkdir -p "$HOME/.local/share/zsh/plugins"
        git clone https://github.com/Aloxaf/fzf-tab.git \
            "$HOME/.local/share/zsh/plugins/fzf-tab"
    fi
    
    success "ZSH plugins installed!"
}

install_packages_fedora() {
    info "Installing Fedora packages..."
    
    # Update package list
    sudo dnf update -y
    
    # Core packages
    local packages=(
        "git"
        "curl"
        "wget"
        "vim"
        "neovim"
        "zsh"
        "gcc"
        "gcc-c++"
        "make"
        "python3"
        "python3-pip"
        "nodejs"
        "npm"
        "ruby"
        "ruby-devel"
        "java-11-openjdk-devel"
        "golang"
        "tree"
        "htop"
        "ncdu"
        "jq"
        "unzip"
        "p7zip"
        "tmux"
        "screen"
        "the_silver_searcher"
        "bat"
        "fd-find"
        "ripgrep"
        "fzf"
    )
    
    sudo dnf install -y "${packages[@]}"
    
    success "Fedora package installation completed!"
}

install_packages_arch() {
    info "Installing Arch Linux packages..."
    
    # Update package database
    sudo pacman -Sy
    
    # Core packages
    local packages=(
        "git"
        "curl"
        "wget"
        "vim"
        "neovim"
        "zsh"
        "base-devel"
        "python"
        "python-pip"
        "nodejs"
        "npm"
        "ruby"
        "jdk11-openjdk"
        "go"
        "tree"
        "htop"
        "ncdu"
        "jq"
        "unzip"
        "p7zip"
        "tmux"
        "screen"
        "the_silver_searcher"
        "bat"
        "fd"
        "ripgrep"
        "fzf"
        "eza"
    )
    
    sudo pacman -S --needed "${packages[@]}"
    
    success "Arch Linux package installation completed!"
}

# Version manager installation
install_version_managers() {
    info "Installing version managers..."
    
    # Install NVM (Node Version Manager)
    if [[ ! -d "$HOME/.nvm" ]]; then
        info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    fi
    
    # Install pyenv (Python Version Manager)
    if ! command_exists pyenv; then
        if [[ -d "$HOME/.pyenv" ]]; then
            warning "pyenv directory already exists, updating..."
            cd "$HOME/.pyenv" && git pull
            # Add pyenv to PATH for current session if not already there
            if [[ ":$PATH:" != *":$HOME/.pyenv/bin:"* ]]; then
                export PATH="$HOME/.pyenv/bin:$PATH"
            fi
        else
            info "Installing pyenv..."
            curl https://pyenv.run | bash
        fi
    fi
    
    # Install rbenv (Ruby Version Manager)
    if ! command_exists rbenv; then
        info "Installing rbenv..."
        if [[ "$(detect_os)" == "macos" ]]; then
            brew install rbenv
        else
            if [[ -d "$HOME/.rbenv" ]]; then
                warning "rbenv directory already exists, updating..."
                cd "$HOME/.rbenv" && git pull
                if [[ -d "$HOME/.rbenv/plugins/ruby-build" ]]; then
                    cd "$HOME/.rbenv/plugins/ruby-build" && git pull
                else
                    git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
                fi
            else
                git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
                git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
            fi
        fi
    fi
    
    # Install rustup (Rust toolchain)
    if ! command_exists rustup; then
        info "Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    
    success "Version managers installed!"
}

# Development tools
install_dev_tools() {
    info "Installing additional development tools..."
    
    # Install Docker (if requested)
    read -p "Install Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$(detect_os)" == "macos" ]]; then
            info "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
        elif [[ "$(detect_linux_distro)" == "ubuntu" ]]; then
            # Install Docker on Ubuntu
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker "$USER"
            rm get-docker.sh
            success "Docker installed! Please log out and back in to use Docker without sudo."
        fi
    fi
    
    # Install Vim-Plug
    if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
        info "Installing Vim-Plug..."
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    success "Development tools installed!"
}

# Main installation function
main() {
    local os
    local distro
    
    os=$(detect_os)
    
    info "Detected OS: $os"
    info "Architecture: $(detect_arch)"
    
    case "$os" in
        "macos")
            install_packages_macos
            ;;
        "linux")
            distro=$(detect_linux_distro)
            info "Detected Linux distribution: $distro"
            
            case "$os" in
                macos)
                    install_packages_macos
                    ;;
                linux)
                    install_packages_ubuntu
                    ;;
                windows)
                    install_nerd_font_windows
                    warning "Windows/WSL detected. Please install packages manually."
                    ;;
                *)
                    error "Unsupported OS: $os"
                    exit 1
                    ;;
            esac
            ;;
        *)
            error "Unsupported operating system: $os"
            exit 1
            ;;
    esac
    
    # Install version managers
    install_version_managers
    
    # Install additional development tools
    install_dev_tools
    
    success "Package installation completed!"
    warning "Please restart your terminal or source your shell configuration to use the new tools."
}

# Show help
show_help() {
    cat << EOF
Cross-Platform Package Installation Script

This script installs essential development tools and utilities for macOS and Linux.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    --dry-run       Show what would be installed (not implemented yet)

SUPPORTED SYSTEMS:
    - macOS (Intel & Apple Silicon)
    - Ubuntu/Debian
    - Fedora/CentOS/RHEL
    - Arch Linux/Manjaro

INSTALLED PACKAGES:
    Core Tools:     git, curl, wget, vim, neovim, zsh
    Modern CLI:     bat, eza, fd, fzf, ripgrep, tree, jq
    Languages:      Python, Node.js, Go, Rust, Ruby, Java
    Version Mgrs:   nvm, pyenv, rbenv, rustup
    Optional:       Docker, tmux, screen

EOF
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --dry-run)
        warning "Dry run mode not implemented yet"
        exit 1
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
