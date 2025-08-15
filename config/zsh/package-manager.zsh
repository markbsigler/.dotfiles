# Cross-platform package manager wrapper functions

# Universal package install function
pkg_install() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "Usage: pkg_install <package1> [package2] ..."
        return 1
    fi
    
    info "Installing packages: ${packages[*]}"
    
    if is_macos && has_brew; then
        brew install "${packages[@]}"
    elif is_linux; then
        if has_apt; then
            sudo apt update && sudo apt install -y "${packages[@]}"
        elif has_dnf; then
            sudo dnf install -y "${packages[@]}"
        elif has_yum; then
            sudo yum install -y "${packages[@]}"
        elif has_pacman; then
            sudo pacman -S --needed "${packages[@]}"
        else
            error "No supported package manager found"
            return 1
        fi
    else
        error "Unsupported platform or no package manager found"
        return 1
    fi
}

# Universal package search function
pkg_search() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo "Usage: pkg_search <package_name>"
        return 1
    fi
    
    if is_macos && has_brew; then
        brew search "$query"
    elif is_linux; then
        if has_apt; then
            apt search "$query"
        elif has_dnf; then
            dnf search "$query"
        elif has_yum; then
            yum search "$query"
        elif has_pacman; then
            pacman -Ss "$query"
        else
            error "No supported package manager found"
            return 1
        fi
    else
        error "Unsupported platform"
        return 1
    fi
}

# Universal package update function
pkg_update() {
    info "Updating packages..."
    
    if is_macos && has_brew; then
        brew update && brew upgrade
    elif is_linux; then
        if has_apt; then
            sudo apt update && sudo apt upgrade -y
        elif has_dnf; then
            sudo dnf upgrade -y
        elif has_yum; then
            sudo yum update -y
        elif has_pacman; then
            sudo pacman -Syu --noconfirm
        else
            error "No supported package manager found"
            return 1
        fi
    else
        error "Unsupported platform"
        return 1
    fi
}

# Universal package cleanup function
pkg_cleanup() {
    info "Cleaning up packages..."
    
    if is_macos && has_brew; then
        brew cleanup
        brew autoremove
    elif is_linux; then
        if has_apt; then
            sudo apt autoremove -y && sudo apt autoclean
        elif has_dnf; then
            sudo dnf autoremove -y && sudo dnf clean all
        elif has_yum; then
            sudo yum autoremove -y && sudo yum clean all
        elif has_pacman; then
            sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || true
            sudo pacman -Sc --noconfirm
        else
            warning "No cleanup method for current package manager"
        fi
    else
        warning "Cleanup not supported on current platform"
    fi
}
