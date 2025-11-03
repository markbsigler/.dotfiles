# Dotfiles Documentation Hub

Welcome to the comprehensive documentation for this dotfiles repository. This page serves as a central hub for all documentation.

## 📚 Documentation Index

### Getting Started

- **[Main README](../README.md)** - Quick start, features overview, and installation
- **[Installation Guide](../README.md#-quick-start)** - Step-by-step setup instructions
- **[System Support](../README.md#-system-support)** - Supported platforms and architectures

### Configuration & Customization

- **[CUSTOMIZATION.md](CUSTOMIZATION.md)** - Complete guide to customizing your dotfiles
  - Local configuration (`~/.config/zsh/local.zsh`)
  - Adding aliases and functions
  - Platform-specific configuration
  - Best practices
- **[Zsh Configuration](../config/zsh/README.md)** - Zsh-specific documentation
  - Features overview
  - Available functions
  - Plugin management
  - Performance optimizations

### Security & Secrets

- **[SECRETS.md](SECRETS.md)** - Comprehensive secrets management guide
  - 5 different methods (Plain File, pass, 1Password, Keychain, Keyring)
  - Security best practices
  - Migration guides
  - Quick start examples

### Troubleshooting & Maintenance

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
  - Installation issues
  - Shell issues
  - Performance problems
  - Platform-specific issues
  - Diagnostic commands
- **[GitHub Authentication](../GITHUB_AUTH_SETUP.md)** - SSH and token setup for GitHub

### Additional Configuration

- **[tmux Configuration](../config/tmux/README.md)** - Terminal multiplexer setup
  - Modern tmux configuration
  - Key bindings reference
  - Customization options
- **[SSH Configuration](../config/ssh/README.md)** - SSH setup guide
  - Template configuration
  - Security best practices
  - Jump host setup

### Development & Roadmap

- **[IMPROVEMENTS_ROADMAP.md](../IMPROVEMENTS_ROADMAP.md)** - Future enhancements
  - 21 potential improvements
  - Priority matrix
  - Implementation guides
  - Time estimates
- **[CHANGELOG.md](../CHANGELOG.md)** - Version history and changes
  - Complete project history
  - Semantic versioning
  - Release notes

## 🚀 Quick Reference

### Essential Commands

```bash
# Installation
make install            # Full installation (creates backups)
make install-dry        # Preview changes without applying

# Maintenance
make update             # Update symlinks
make packages           # Install/update packages
make plugins            # Update Zsh plugins

# Diagnostics
make doctor             # System health check
make test               # Run comprehensive test suite
make lint               # Lint shell scripts with shellcheck
make security           # Run security audit (secrets, permissions)

# Utilities
make fonts              # Install Nerd Fonts
```

### Secrets Management

```bash
# Simple method (development)
secret_add GITHUB_TOKEN "ghp_xxxx"
secret_list
secret_remove GITHUB_TOKEN

# Show all available methods
secret_help

# Advanced methods
secret_from_1password GITHUB_TOKEN "op://Personal/GitHub/token"
secret_from_keychain GITHUB_TOKEN github_token
secret_from_pass GITHUB_TOKEN github/token
```

### Customization Quick Start

1. **Machine-specific settings**: Edit `~/.config/zsh/local.zsh`
   ```bash
   # Add custom aliases
   alias myserver="ssh user@server.com"
   
   # Set environment variables
   export CUSTOM_VAR="value"
   
   # Machine-specific PATH
   export PATH="/custom/path:$PATH"
   ```

2. **Temporary testing**: Edit `~/.dotfiles/local/local.zsh`

3. **Permanent changes**: Modify files in `~/.dotfiles/config/zsh/`

### Environment Variables

```bash
# OS Detection
$DOTFILES_OS           # macos, linux, windows
$DOTFILES_ARCH         # x86_64, arm64
$DOTFILES_DISTRO       # ubuntu, fedora, arch, etc.

# XDG Base Directories
$XDG_CONFIG_HOME       # ~/.config
$XDG_DATA_HOME         # ~/.local/share
$XDG_CACHE_HOME        # ~/.cache
$XDG_STATE_HOME        # ~/.local/state
$ZDOTDIR               # ~/.config/zsh
```

### Useful Functions

```bash
# Environment
show_env                # Display OS, architecture, distro

# Secrets
secret_add              # Add secret to plain file
secret_help             # Show all secrets management methods

# Development
init_project <type>     # Initialize project (node, python, rust, go)
serve_static [port]     # Quick static file server
port_kill <port>        # Kill process on port

# Git workflows
gwip                    # Quick WIP commit
gnb <branch>            # Create and push new branch
gdel <branch>           # Delete branch locally and remotely

# Directory management
mkcd <dir>              # Create and enter directory
book <n>                # Bookmark current directory
go <n>                  # Jump to bookmark

# Maintenance
update_plugins          # Update Zsh plugins
clean_path              # Remove duplicate PATH entries
```

## 📖 Documentation Structure

```
.dotfiles/
├── README.md                    # Main documentation
├── IMPROVEMENTS_ROADMAP.md      # Future enhancements
├── GITHUB_AUTH_SETUP.md         # GitHub auth guide
│
├── docs/
│   ├── README.md                # This file (documentation hub)
│   ├── CUSTOMIZATION.md         # Customization guide
│   ├── SECRETS.md               # Secrets management
│   └── TROUBLESHOOTING.md       # Problem solving
│
└── config/
    └── zsh/
        └── README.md            # Zsh-specific documentation
```

## 🎯 Common Tasks

### First-Time Setup

1. Clone repository: `git clone https://github.com/markbsigler/.dotfiles ~/.dotfiles`
2. Preview: `cd ~/.dotfiles && make install-dry`
3. Install: `make install`
4. Verify: `make doctor && make test`

### Adding Secrets

1. Simple: `secret_add API_KEY "value"`
2. Secure (macOS): `keychain_add api_key "value"`
3. Enterprise: Use 1Password CLI
4. See [SECRETS.md](SECRETS.md) for full guide

### Customizing for Your Machine

1. Edit: `~/.config/zsh/local.zsh`
2. Add your aliases, functions, and environment variables
3. Reload: `source ~/.zshrc`
4. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for examples

### Performance Tuning

1. Profile startup: `scripts/profile-startup.sh`
2. Detailed analysis: `scripts/profile-startup.sh --detailed`
3. Check plugin load times
4. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#performance-issues)

### Updating Everything

```bash
# Update dotfiles repository
cd ~/.dotfiles && git pull

# Update packages
make packages

# Update plugins
make plugins

# Or use automated script
scripts/update-all.sh
```

## 🆘 Getting Help

### Diagnostic Tools

```bash
make doctor         # Comprehensive health check
make test           # Run all tests
make lint           # Check shell scripts
make security       # Security audit (secrets, permissions)

# Profile performance
scripts/profile-startup.sh
scripts/profile-startup.sh --detailed

# Security audit
scripts/security-audit.sh
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Slow startup | `scripts/profile-startup.sh --detailed` |
| Command not found | `make doctor` then check PATH |
| Completion not working | Delete `~/.zcompdump*` and reload |
| Plugin issues | `update_plugins` or reinstall |

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for comprehensive solutions.

### Still Need Help?

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review [relevant documentation section](#documentation-index)
3. Run `make doctor` for diagnostics
4. Open an issue on GitHub with:
   - OS and version (`uname -a`)
   - Shell version (`zsh --version`)
   - Output of `make doctor`
   - Error messages

## 🌟 Features Highlights

### Cross-Platform Support
- macOS (Intel & Apple Silicon)
- Ubuntu/Debian
- Fedora/CentOS
- Arch/Manjaro

### Modern CLI Tools
- `bat` - Better cat with syntax highlighting
- `eza` - Modern ls replacement
- `fd` - Better find
- `ripgrep` - Fast grep
- `fzf` - Fuzzy finder

### Development Tools
- Version managers (nvm, pyenv, rbenv, rustup)
- Language support (Node, Python, Go, Rust, Ruby, Java)
- Git enhancements
- Docker shortcuts

### Security
- 5 secrets management methods
- XDG compliance
- Secure file permissions
- Best practices documented

### Quality Assurance
- ✅ All shell scripts pass shellcheck
- ✅ Comprehensive test suite
- ✅ Automated CI/CD ready
- ✅ Cross-platform tested
- ✅ Pre-commit hooks available (run `scripts/setup-pre-commit.sh`)
- 🔒 Security audit script for checking secrets and permissions

## 🤝 Contributing

This dotfiles repository is:
- **Modular** - Easy to modify individual components
- **Documented** - Clear comments and comprehensive guides
- **Tested** - Automated testing for reliability
- **Cross-platform** - Works on macOS and Linux

Contributions welcome! Please:
1. Test across platforms (`make test`)
2. Update relevant documentation
3. Follow existing code style
4. Run `make lint` before committing

## 📝 License

MIT License - see [LICENSE](../LICENSE) for details.

---

**Last Updated:** November 2025

**Documentation Version:** 2.1

**Repository:** [github.com/markbsigler/.dotfiles](https://github.com/markbsigler/.dotfiles)

---

*Made with ❤️ for developers who care about their environment*

