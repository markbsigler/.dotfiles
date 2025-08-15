
# ~/.zprofile - Login shell initialization

# Load OS detection first (needed for package manager setup)
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/os-detection.zsh" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/os-detection.zsh"
fi

# Package manager environment setup
if is_macos; then
    # macOS - Homebrew is the standard package manager
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon macOS
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        # Intel macOS
        eval "$(/usr/local/bin/brew shellenv)"
    fi
elif is_linux; then
    # Linux - Use native package manager first, Homebrew as optional supplement
    # Native package managers (apt, dnf, pacman) don't need shellenv setup
    
    # Only set up Homebrew if explicitly installed by user
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
    
    # Ensure ~/.local/bin is in PATH for user-installed tools
    if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi
