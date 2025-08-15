#!/bin/bash
# ~/.config/zsh/setup-tools.sh - Setup script for development tools

set -e

echo "🌊 Zsh Development Environment Setup"
echo "===================================="

# Colors for output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_warning "This setup script is optimized for macOS. Some features may not work on other systems."
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create necessary directories
log_info "Creating necessary directories..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$XDG_DATA_HOME/zsh"
mkdir -p "$XDG_CACHE_HOME/zsh"
mkdir -p "$HOME/.vim/backup"
mkdir -p "$HOME/.vim/swap"
mkdir -p "$HOME/.vim/undo"
log_success "Directories created"

# Install Homebrew if not present
if ! command_exists brew; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log_success "Homebrew installed"
else
    log_success "Homebrew already installed"
fi

# Install essential tools
log_info "Installing/updating essential tools..."

# Core utilities
brew_tools=(
    "git"
    "curl"
    "wget"
    "jq"
    "tree"
    "htop"
    "bat"         # Better cat
    "eza"         # Better ls
    "fd"          # Better find
    "ripgrep"     # Better grep
    "fzf"         # Fuzzy finder
    "dust"        # Better du
    "delta"       # Better git diff
    "gh"          # GitHub CLI
)

for tool in "${brew_tools[@]}"; do
    if ! command_exists "$tool"; then
        log_info "Installing $tool..."
        brew install "$tool"
        log_success "$tool installed"
    else
        log_success "$tool already installed"
    fi
done

# Development tools
dev_tools=(
    "node"
    "python@3.11"
    "go"
    "rust"
    "docker"
    "docker-compose"
)

for tool in "${dev_tools[@]}"; do
    if ! brew list "$tool" >/dev/null 2>&1; then
        log_info "Installing $tool..."
        brew install "$tool"
        log_success "$tool installed"
    else
        log_success "$tool already installed"
    fi
done

# Install vim-plug for Vim
if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    log_info "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    log_success "vim-plug installed"
else
    log_success "vim-plug already installed"
fi

# Install Vim plugins
log_info "Installing Vim plugins..."
vim +PlugInstall +qall
log_success "Vim plugins installed"

# Setup FZF key bindings
if command_exists fzf; then
    log_info "Setting up FZF key bindings..."
    $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
    log_success "FZF key bindings configured"
fi

# Install additional useful tools
log_info "Installing additional development tools..."
additional_tools=(
    "tldr"        # Better man pages
    "httpie"      # Better curl for APIs
    "direnv"      # Environment variable management
    "neovim"      # Modern Vim
    "tmux"        # Terminal multiplexer
)

for tool in "${additional_tools[@]}"; do
    if ! command_exists "$tool"; then
        log_info "Installing $tool..."
        brew install "$tool"
        log_success "$tool installed"
    else
        log_success "$tool already installed"
    fi
done

# Setup Git configuration (if not already configured)
if [[ -z "$(git config --global user.name)" ]]; then
    log_info "Git user.name not configured. Please set it up:"
    echo -n "Enter your name: "
    read -r git_name
    git config --global user.name "$git_name"
    log_success "Git user.name configured"
fi

if [[ -z "$(git config --global user.email)" ]]; then
    log_info "Git user.email not configured. Please set it up:"
    echo -n "Enter your email: "
    read -r git_email
    git config --global user.email "$git_email"
    log_success "Git user.email configured"
fi

# Configure Git with better defaults
log_info "Configuring Git with better defaults..."
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf input
git config --global core.editor "vim"
git config --global diff.tool "vimdiff"
git config --global merge.tool "vimdiff"
log_success "Git configured with better defaults"

# Setup Python environment
if command_exists python3; then
    log_info "Setting up Python environment..."
    python3 -m pip install --user --upgrade pip
    python3 -m pip install --user pipenv black flake8 pytest ipython jupyterlab
    log_success "Python environment configured"
fi

# Setup Node.js environment
if command_exists npm; then
    log_info "Setting up Node.js environment..."
    npm install -g yarn typescript eslint prettier nodemon
    log_success "Node.js environment configured"
fi

# Install fonts for better terminal experience
log_info "Installing fonts..."
brew tap homebrew/cask-fonts
fonts=(
    "font-fira-code-nerd-font"
    "font-hack-nerd-font"
    "font-meslo-lg-nerd-font"
)

for font in "${fonts[@]}"; do
    if ! brew list --cask "$font" >/dev/null 2>&1; then
        log_info "Installing $font..."
        brew install --cask "$font"
        log_success "$font installed"
    else
        log_success "$font already installed"
    fi
done

# Create a sample local configuration
if [[ ! -f "$ZDOTDIR/local.zsh" ]]; then
    log_info "Creating local configuration template..."
    cat > "$ZDOTDIR/local.zsh" << 'EOF'
# ~/.config/zsh/local.zsh - Machine-specific configuration
# This file is for local customizations and won't be overwritten by updates

# Example: Add local PATH modifications
# export PATH="$HOME/custom/bin:$PATH"

# Example: Set machine-specific aliases
# alias work_server="ssh user@work-server.com"

# Example: Environment variables for this machine
# export API_KEY="your-api-key-here"

# Example: Custom functions for this machine
# work_deploy() {
#     echo "Deploying to work environment..."
#     # Your deployment commands here
# }
EOF
    log_success "Local configuration template created at $ZDOTDIR/local.zsh"
fi

# Final setup messages
echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Your zsh environment has been configured with:"
echo "• Modern command-line tools (bat, eza, fd, ripgrep, fzf)"
echo "• Enhanced Vim configuration with plugins"
echo "• Git with sensible defaults"
echo "• Development tools for Python, Node.js, Go, and Rust"
echo "• Comprehensive zsh configuration with modules"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Edit $ZDOTDIR/local.zsh for machine-specific settings"
echo "3. Run 'check_plugin_updates' periodically to keep plugins updated"
echo "4. Use 'zsh_startup_time' to monitor shell performance"
echo ""
echo "Useful commands to try:"
echo "• 'ff' - Interactive file finder with preview"
echo "• 'fbr' - Interactive git branch switcher"
echo "• 'fkill' - Interactive process killer"
echo "• 'hist_top' - Show most used commands"
echo "• 'init_project <type>' - Initialize a new project"
echo ""
log_success "Enjoy your enhanced shell experience! 🌊"
