# ~/.config/zsh/os-detection.zsh - OS detection and environment setup

# Detect OS
export DOTFILES_OS="unknown"
case "$(uname -s)" in
    Darwin*)
        export DOTFILES_OS="macos"
        export DOTFILES_ARCH="$(uname -m)"
        ;;
    Linux*)
        export DOTFILES_OS="linux"
        export DOTFILES_ARCH="$(uname -m)"
        # Detect Linux distribution
        if [[ -f /etc/os-release ]]; then
            export DOTFILES_DISTRO="$(awk -F= '/^ID=/{gsub(/"/,"",$2); print $2}' /etc/os-release)"
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        export DOTFILES_OS="windows"
        export DOTFILES_ARCH="$(uname -m)"
        ;;
esac

# OS-specific functions
is_macos() { [[ "$DOTFILES_OS" == "macos" ]]; }
is_linux() { [[ "$DOTFILES_OS" == "linux" ]]; }
is_windows() { [[ "$DOTFILES_OS" == "windows" ]]; }
is_ubuntu() { [[ "$DOTFILES_DISTRO" == "ubuntu" ]]; }
is_debian() { [[ "$DOTFILES_DISTRO" == "debian" ]]; }
is_fedora() { [[ "$DOTFILES_DISTRO" == "fedora" ]]; }
is_arch() { [[ "$DOTFILES_DISTRO" == "arch" ]]; }
is_arm64() { [[ "$DOTFILES_ARCH" == "arm64" ]] || [[ "$DOTFILES_ARCH" == "aarch64" ]]; }
is_x86_64() { [[ "$DOTFILES_ARCH" == "x86_64" ]] || [[ "$DOTFILES_ARCH" == "amd64" ]]; }

# Package manager detection
has_brew() { command -v brew &> /dev/null; }
has_apt() { command -v apt &> /dev/null; }
has_yum() { command -v yum &> /dev/null; }
has_dnf() { command -v dnf &> /dev/null; }
has_pacman() { command -v pacman &> /dev/null; }
has_snap() { command -v snap &> /dev/null; }
has_flatpak() { command -v flatpak &> /dev/null; }

# Debug function to show detected environment
show_env() {
    echo "Detected Environment:"
    echo "  OS: $DOTFILES_OS"
    echo "  Architecture: $DOTFILES_ARCH"
    [[ -n "$DOTFILES_DISTRO" ]] && echo "  Distribution: $DOTFILES_DISTRO"
    echo "  Terminal: ${TERM_PROGRAM:-${TERM:-unknown}}"
    echo "  Shell: $SHELL"
    echo "  Package Managers:"
    has_brew && echo "    ✅ Homebrew"
    has_apt && echo "    ✅ APT"
    has_dnf && echo "    ✅ DNF"
    has_yum && echo "    ✅ YUM" 
    has_pacman && echo "    ✅ Pacman"
    has_snap && echo "    ✅ Snap"
    has_flatpak && echo "    ✅ Flatpak"
}
