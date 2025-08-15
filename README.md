
# .dotfiles

---

## 🖼️ Nerd Fonts Required for Icons

To see all prompt and file icons correctly, you must use a [Nerd Font](https://www.nerdfonts.com/). The default installed by this setup is **Agave Nerd Font**.

- Run `make fonts` to install Agave Nerd Font on macOS and Linux (downloads directly from the Nerd Fonts GitHub releases).

- After installation, set your terminal font to **Agave Nerd Font** in your terminal preferences.

- If you are on Windows/WSL, download and install Agave Nerd Font manually from the [Nerd Fonts website](https://www.nerdfonts.com/font-downloads).

- If the font does not appear in your terminal settings, try logging out and back in, or restarting your computer.

- If you see `?` instead of icons, double-check your terminal font setting.

## Cross-Platform .dotfiles

A comprehensive, portable .dotfiles setup that works seamlessly across macOS and Linux systems. Features intelligent platform detection, modern shell enhancements, developer tools, and cross-platform compatibility.

## ✨ Features

- **🌐 Cross-Platform**: Supports macOS, Ubuntu, Debian, Fedora, and Arch Linux with automatic OS detection
- **🚀 Modern Shell**: Enhanced Zsh with intelligent completions, syntax highlighting, and fuzzy finding
- **📦 Smart Package Management**: Universal package manager wrapper with automatic tool detection
- **🛤️ Intelligent PATH Management**: Automatically detects and configures paths for different architectures and package managers
- **⚡ Lazy Loading**: Fast startup times with lazy-loaded version managers and plugins  
- **🎨 Rich Prompt**: Git-aware prompt with system information, architecture, and context indicators
- **👩‍💻 Development Ready**: Pre-configured for multiple programming languages with version management
- **🔧 Easy Maintenance**: Automated installation, updates, health checks, and cross-platform testing
- **🔒 Secure Defaults**: Platform-specific credential helpers and SSH configuration

## 🚀 Quick Start

### One-Line Installation

```bash
# Clone and install
git clone https://github.com/yourusername/.dotfiles ~/.dotfiles
cd ~/.dotfiles && make install
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/.dotfiles ~/.dotfiles
cd ~/.dotfiles

# Preview what will be installed (dry run)
make install-dry

# Install everything
make install

# Or install without packages
make install --skip-packages
```

## 📋 System Support

### Supported Operating Systems

| OS | Status | Package Manager | Notes |
|---|---|---|---|
| **macOS** | ✅ Full Support | Homebrew | Intel & Apple Silicon |
| **Ubuntu** | ✅ Full Support | APT | 20.04+ recommended |
| **Debian** | ✅ Full Support | APT | 11+ recommended |
| **Fedora** | ✅ Full Support | DNF | 35+ recommended |
| **Arch Linux** | ✅ Full Support | Pacman | Including Manjaro |
| **Pop!_OS** | ✅ Full Support | APT | Ubuntu-based |
| **Linux Mint** | ✅ Full Support | APT | Ubuntu-based |

### Architecture Support

- **x86_64 (amd64)**: Full support
- **ARM64 (aarch64)**: Full support (including Apple Silicon)
- **ARM**: Basic support

## 🌟 Platform-Specific Features

### macOS

- **Homebrew Integration**: Automatic detection of Apple Silicon (`/opt/homebrew`) vs Intel (`/usr/local`) paths
- **macOS-Specific Tools**: GNU tools (`coreutils`, `findutils`, `gnu-tar`) with proper PATH precedence
- **Keychain Integration**: SSH and Git credential helper using macOS Keychain
- **App Store CLI**: Integration with `mas` for App Store app management
- **Development Tools**: Native support for Xcode command line tools
- **Font Management**: Automatic installation of developer fonts via Homebrew Cask

```bash
# macOS-specific aliases and functions automatically available:
alias reveal="open -R"                    # Reveal in Finder
alias spotlight="mdfind"                  # Spotlight search from terminal
brew_update_all() { brew update && brew upgrade && brew cleanup; }
```

### Linux (Ubuntu/Debian)

- **APT Package Management**: Full integration with Ubuntu/Debian package ecosystem
- **Snap & Flatpak**: Automatic PATH detection for Snap and Flatpak applications
- **Modern CLI Tools**: Automated installation from GitHub releases when not in repos
- **Development PPAs**: Automatic setup of common development package repositories
- **AppImage Support**: PATH integration for `~/Applications` directory
- **Linux-Specific Paths**: `/usr/local/bin`, flatpak exports, and snap bins

```bash
# Ubuntu/Debian-specific functions:
alias apt-update="sudo apt update && sudo apt upgrade"
alias apt-search="apt search"
alias apt-install="sudo apt install"
```

### Linux (Fedora/CentOS)

- **DNF/YUM Integration**: Native support for Red Hat package managers
- **Copr Repositories**: Easy management of community repositories
- **SELinux Awareness**: Proper handling of security contexts
- **Enterprise Features**: Support for RHEL-specific development tools

```bash
# Fedora-specific functions:
alias dnf-update="sudo dnf upgrade --refresh"
alias dnf-search="dnf search"
alias copr-enable="sudo dnf copr enable"
```

### Linux (Arch Linux)

- **Pacman Integration**: Full support for Arch package management
- **AUR Support**: Functions to work with AUR helpers (yay, paru)
- **Rolling Release**: Optimized for frequent system updates
- **Minimal Dependencies**: Lightweight installation for Arch philosophy

```bash
# Arch-specific functions:
alias pac-update="sudo pacman -Syu"
alias pac-search="pacman -Ss"
alias pac-info="pacman -Si"
```

### Windows Subsystem for Linux (WSL)

- **WSL Detection**: Automatic detection of WSL1 vs WSL2 environments
- **Windows PATH Integration**: Selective inclusion of Windows executables
- **Cross-System Clipboard**: Clipboard sharing between WSL and Windows
- **File System Handling**: Proper handling of Windows vs Linux file systems

```bash
# WSL-specific features:
alias explorer="explorer.exe"             # Open Windows Explorer
alias notepad="notepad.exe"               # Open Windows Notepad
wsl_update() { wsl.exe --update; }        # Update WSL kernel
```

## 🔧 Universal Package Management

The .dotfiles include cross-platform package management functions that work the same way regardless of your operating system:

```bash
# Universal commands that work on all platforms:
pkg_install git vim nodejs              # Install packages
pkg_search python                       # Search for packages
pkg_update                              # Update all packages
pkg_cleanup                             # Clean package cache
```

### Package Manager Detection

The system automatically detects and uses the appropriate package manager:

| Platform | Primary | Alternatives | Modern Tools |
|----------|---------|--------------|--------------|
| macOS | Homebrew | MacPorts | brew |
| Ubuntu/Debian | APT | snap, flatpak | apt, snap |
| Fedora/CentOS | DNF/YUM | copr | dnf, yum |
| Arch Linux | Pacman | AUR helpers | pacman, yay |

## 🛤️ Intelligent PATH Management

### Automatic Path Detection


The .dotfiles automatically detect and configure paths for:

**macOS Paths:**

- `/opt/homebrew/bin` (Apple Silicon)
- `/usr/local/bin` (Intel Mac)
- GNU tool alternatives
- Xcode command line tools

**Linux Paths:**

- Distribution-specific package paths
- Snap packages (`/snap/bin`)
- Flatpak exports (`/var/lib/flatpak/exports/bin`)
- User-installed applications (`~/.local/bin`)
- AppImage directory (`~/Applications`)

**Universal Paths:**

- `~/.local/bin` - User-installed binaries
- `~/.cargo/bin` - Rust tools
- `~/.npm-global/bin` - Global npm packages
- Version manager paths (nvm, pyenv, rbenv, etc.)


### PATH Cleanup

Automatic duplicate removal while preserving order:

```bash
# PATH cleanup happens automatically on shell startup
clean_path()  # Available as a manual function
```

## 🛠️ What Gets Installed

### Core Tools

- **Git** with enhanced configuration
- **Zsh** with completions and plugins
- **Vim/Neovim** with plugin management
- **Modern CLI tools**: bat, eza, fd, fzf, ripgrep, jq

### Development Tools

- **Version Managers**: nvm, pyenv, rbenv, rustup
- **Languages**: Node.js, Python, Go, Rust, Ruby, Java
- **Package Managers**: npm, pip, cargo, gem

### Shell Enhancements

- **Syntax highlighting** and autosuggestions
- **Fuzzy completion** with fzf-tab
- **Smart aliases** for common operations
- **Git-aware prompt** with status indicators

## ⚙️ Configuration Structure

```text
.dotfiles/
├── config/
│   ├── zsh/                    # Zsh configuration
│   │   ├── os-detection.zsh    # Platform detection
│   │   ├── exports.zsh         # Environment variables
│   │   ├── aliases.zsh         # Command aliases
│   │   ├── functions.zsh       # Custom functions
│   │   ├── plugins.zsh         # Plugin management
│   │   ├── package-manager.zsh # Universal package functions
│   │   ├── ssh-config.zsh      # SSH configuration
│   │   ├── prompt.zsh          # Prompt configuration
│   │   └── local.zsh           # Local customizations
│   ├── git/
│   │   ├── gitconfig           # Main Git configuration
│   │   ├── gitconfig-macos     # macOS-specific settings
│   │   └── gitconfig-linux     # Linux-specific settings
│   ├── vim/
│   │   └── vimrc              # Vim configuration
│   └── nvim/                  # Neovim configuration
├── scripts/
│   ├── install-packages.sh    # Cross-platform package installer
│   └── test-dotfiles.sh       # Cross-platform testing
└── Makefile                   # Build automation
```

## 🔍 OS Detection and Environment

The .dotfiles automatically detect your system and configure accordingly:

```bash
# Check your detected environment
show_env

# Example output:
# Detected Environment:
#   OS: macos
#   Architecture: arm64
#   Terminal: vscode
#   Shell: /bin/zsh
#   Package Managers:
#     ✅ Homebrew
```

### Environment Variables

Key environment variables set by the .dotfiles:

```bash
$DOTFILES_OS        # macos, linux, windows
$DOTFILES_ARCH      # arm64, amd64, x86_64
$DOTFILES_DISTRO    # ubuntu, fedora, arch, etc.
```

## 🎨 Cross-Platform Git Configuration

### Credential Management

The Git configuration automatically uses the appropriate credential helper:

**macOS**: Uses Keychain for secure credential storage
```bash
[credential]
    helper = osxkeychain
```

**Linux**: Uses cache or libsecret based on availability
```bash
[credential]
    helper = cache --timeout=3600
```

### Platform-Specific Includes

Git configuration includes platform-specific settings:

```bash
# Automatically includes based on your home directory
[includeIf "gitdir:/Users/"]        # macOS
    path = ~/.config/git/gitconfig-macos

[includeIf "gitdir:/home/"]         # Linux  
    path = ~/.config/git/gitconfig-linux
```

## 🔧 Tool Detection and Fallbacks

The .dotfiles include intelligent fallbacks for cross-platform compatibility:

### Editor Selection


Automatically selects the best available editor:

1. `code --wait` (VS Code)
2. `nvim` (Neovim)
3. `vim` (Vim)
4. `nano` (fallback)


### File Listing (ls replacement)


Priority order for better file listing:

1. `eza` (modern, feature-rich)
2. `exa` (fallback)
3. Platform-specific `ls` with colors


### File Finding


Smart detection for file search tools:

1. `fd` (fast, user-friendly)
2. `fdfind` (Ubuntu package name)
3. Platform-optimized `find` commands


### Text Search


Grep replacement priority:

1. `ripgrep` (`rg`) - fastest
2. Standard `grep` with color


## 🧪 Testing and Validation

### Cross-Platform Testing

Run tests to validate your configuration:

```bash
make test                    # Run all tests
./scripts/test-dotfiles.sh   # Direct script execution
```

Tests include:
- OS detection accuracy
- PATH configuration
- Tool availability  
- Configuration file validity
- Shell startup performance

### Health Check

Verify your system health:

```bash
make doctor                  # System health check
show_env                     # Show detected environment
```

## 🔄 Maintenance Commands

### Universal Package Management

These commands work the same way across all platforms:

```bash
pkg_install <package>        # Install packages
pkg_search <query>           # Search for packages  
pkg_update                   # Update all packages
pkg_cleanup                  # Clean package cache
```

### System Updates

Platform-aware update commands:

```bash
# macOS
brew_update_all             # Update Homebrew packages

# Linux (Ubuntu/Debian)
apt-update                  # Update APT packages

# Linux (Fedora)  
dnf-update                  # Update DNF packages

# Linux (Arch)
pac-update                  # Update Pacman packages
```
├── local/                  # Machine-specific configs (not tracked)
├── install.sh             # Main installation script
└── Makefile              # Management commands
```

## 🖥️ Platform-Specific Features


### macOS

- Homebrew package management (Apple Silicon & Intel)
- macOS-specific aliases (`showfiles`, `flushdns`)
- Finder and system integration
- Quick Look integration (`ql` command)



### Linux

- Distribution-specific package managers
- Systemd service management
- Desktop environment integration (GNOME, KDE)
- Snap and Flatpak support



### Cross-Platform

- Automatic tool detection and fallbacks
- Conditional PATH management
- Platform-specific prompt elements
- Smart clipboard integration


## 📚 Usage


### Management Commands

```bash
# Installation and updates
make install        # Full installation
make update         # Update existing symlinks
make packages       # Install packages only
make install-dry    # Preview changes

# Maintenance
make doctor         # Health check
make backup         # Create backup
make restore        # Restore from backup
make clean          # Clean old backups

# Development
make test           # Test configurations
make lint           # Lint shell scripts
make plugins        # Update ZSH plugins

# Information
make status         # Show current status
make deps           # Show dependencies
make help           # Show all commands
```


### Plugin Management

```bash
# Update all plugins (recommended)
make plugins

# Alternate: make plugins (does the same thing)

# List installed plugins (if function available)
plugin-list

# Remove a plugin (if function available)
plugin-remove <plugin-name>

# Clean plugin caches (if function available)
plugin-clean
```

> **Note:** The `update_plugins` function and plugins directory must exist for plugin updates to work. See `config/zsh/plugins.zsh` for details.


## 🔑 GitHub Authentication: SSH and Tokens

### SSH (Recommended for Developers)

1. Generate a key (if you don't have one):

    ```sh
    ssh-keygen -t ed25519 -C "your_email@example.com"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    cat ~/.ssh/id_ed25519.pub
    # Add the output to GitHub → Settings → SSH and GPG keys
    ```

2. Change your repo remote to SSH:

    ```sh
    git remote set-url origin git@github.com:yourusername/reponame.git
    ```

3. Test:

    ```sh
    ssh -T git@github.com
    ```

### Personal Access Token (PAT, for automation/CI)

1. Generate a token at GitHub → Settings → Developer settings → Personal access tokens.

2. Use the token as your password when prompted for HTTPS git operations.

3. You can use a credential manager to avoid entering the token every time.

> **Tip:** You only need to add your SSH key to GitHub once per user account. For each repo, make sure the remote URL uses SSH (git@github.com:...) to use your key.

## 🎯 Customization

### Local Configuration

Create machine-specific configurations that won't be tracked in git:

- `~/.config/zsh/local.zsh` - ZSH customizations
- `local/local.zsh` - Project-local settings

### Environment Variables

```bash
# Example local.zsh
export WORK_EMAIL="you@company.com"
export GITHUB_TOKEN="your-token"
export CUSTOM_PATH="/opt/custom/bin"
alias work-ssh="ssh user@work-server"
```

### Custom Functions

Add your functions to `config/zsh/functions.zsh`:

```bash
# Custom function example
my_project() {
    cd ~/Projects/$1 && code .
}

deploy_app() {
    git push && ssh server "cd /app && ./deploy.sh"
}
```

## 🔧 Advanced Configuration

### Adding New Platforms

1. Update `config/zsh/os-detection.zsh` with detection logic
2. Add platform-specific aliases in `config/zsh/aliases.zsh`  
3. Update `scripts/install-packages.sh` with package installation
4. Add platform-specific paths in `config/zsh/exports.zsh`
5. Test with `make test`

### Performance Optimization

For slower systems, you can disable certain features:

```bash
# In your local.zsh
export DOTFILES_DISABLE_PLUGINS=true    # Disable heavy plugins
export DOTFILES_MINIMAL_PROMPT=true     # Use minimal prompt
export DOTFILES_LAZY_LOAD=false         # Disable lazy loading
```

## 🚨 Troubleshooting

### Common Issues


#### Slow Shell Startup

```bash
# Profile your shell startup
zsh -x -c exit 2>&1 | ts -i "%.s"

# Disable expensive features temporarily
export DOTFILES_MINIMAL_PROMPT=true
```


#### Missing Tools

```bash
# Check what's missing
make doctor

# Install packages manually
./scripts/install-packages.sh
```


#### PATH Issues

```bash
# Debug PATH
echo $PATH | tr ':' '\n' | nl

# Clean PATH
clean_path
```


#### Git Credentials

```bash
# Reset git credentials (macOS)
git config --global --unset credential.helper
git config --global credential.helper osxkeychain

# Reset git credentials (Linux)
git config --global credential.helper cache
```

## 📚 Resources

### Documentation

- [Zsh Manual](http://zsh.sourceforge.net/Doc/)
- [Oh My Zsh Wiki](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Homebrew Documentation](https://docs.brew.sh/)

### Related Projects

- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - Zsh framework
- [Prezto](https://github.com/sorin-ionescu/prezto) - Zsh configuration framework  
- [Dotbot](https://github.com/anishathalye/dotbot) - Dotfiles management

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes across platforms (`make test`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Development

```bash
# Run tests
make test

# Check style
make lint

# Clean up
make clean

# Generate docs
make docs
```

---


**Made with ❤️ for developers who work across multiple platforms**

    echo "Hello from $(is_macos && echo macOS || echo Linux)"
}

```


### Version Managers

Configure version managers in `config/zsh/version-managers.zsh`:

```bash
# Auto-switch Node versions
auto-switch-node    # Enable in version-managers.zsh
```


## 🐛 Troubleshooting

### Common Issues

#### ZSH not loading correctly

```bash
# Test configuration
zsh -n ~/.zshrc

# Check for errors
zsh -x ~/.zshrc
```

#### Missing packages

```bash
# Check what's available
make doctor

# Install missing packages
make packages

# Platform-specific install
./scripts/install-packages.sh
```

#### Slow startup

```bash
# Profile startup time
make perf

# Disable heavy plugins in config/zsh/plugins.zsh
# Comment out fzf-tab or syntax highlighting
```

#### Permission issues

```bash
# Fix permissions
sudo chown -R $(whoami) ~/.local
chmod -R 755 ~/.local/bin
```

### Platform-Specific Issues

#### macOS

- **Command Line Tools**: `xcode-select --install`
- **Homebrew ARM64**: Install to `/opt/homebrew`
- **PATH Issues**: Restart terminal after installation

#### Linux

- **Package repositories**: Update with `sudo apt update`
- **Missing dependencies**: Install `build-essential`
- **Shell change**: May require logout/login

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test on multiple platforms
4. Submit a pull request

### Testing
```bash
# Test all configurations
make test

# Lint shell scripts
make lint

# Test installation
make install-dry
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) for inspiration
- [Homebrew](https://brew.sh/) for macOS package management
- [Modern Unix tools](https://github.com/ibraheemdev/modern-unix) for CLI tool recommendations
- Community dotfiles for best practices

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/.dotfiles/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/.dotfiles/discussions)
- **Documentation**: Run `make docs` to generate detailed docs

---

**Happy coding!** 🚀
