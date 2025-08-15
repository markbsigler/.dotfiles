
# ~/.zprofile - Login shell initialization

# Homebrew setup (if installed)
if [[ "$OSTYPE" == darwin* ]]; then
    # macOS - Homebrew is the standard package manager
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon macOS
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        # Intel macOS
        eval "$(/usr/local/bin/brew shellenv)"
    fi
elif [[ "$OSTYPE" == linux* ]]; then
    # Linux - Homebrew is optional (native package managers: apt, dnf, pacman, etc.)
    # Only set up if user has explicitly installed Homebrew/Linuxbrew
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
fi
