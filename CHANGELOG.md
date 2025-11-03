# Changelog

All notable changes to this dotfiles project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- GitHub Actions CI/CD pipeline
- Environment profile switcher (work/personal)
- Enhanced Makefile with more targets
- FAQ documentation

## [2.1.1] - 2025-11-03

### Changed
- Consolidated test scripts into single comprehensive script
  - All test functionality now in `scripts/test-dotfiles.sh`
  - Single entry point reduces confusion and maintenance burden
- Updated Makefile with new security target
  - Added `make security` to run security audit

### Removed
- `test_install.sh` - Consolidated into `scripts/test-dotfiles.sh`
- `verify_install.sh` - Consolidated into `scripts/test-dotfiles.sh`
- `debug_os.sh` - Debugging covered by test-dotfiles.sh
- `simple_integration_test.sh` - Empty placeholder, no longer needed

### Documentation
- Updated `IMPROVEMENTS_ROADMAP.md` with recently completed items
  - Added sections 6-11 documenting new features
  - Updated project score: 8.7/10 → 9.0/10
  - Marked completed items (#2, #3, #6, #7, #8) in roadmap
- Updated `README.md` with new features
  - Added `make security` command
  - Enhanced Quality Assurance section
  - Added Configuration Guides section
  - Updated Documentation links
- Updated `docs/README.md` with quick references for new features

### Benefits
- Cleaner repository structure
- Single test entry point for users
- Easier to maintain and enhance
- Better organization of scripts

## [2.1.0] - 2025-11-03

### Added
- **Pre-commit Hooks**: Automated code quality checks before commits
  - Trailing whitespace removal
  - YAML syntax validation
  - ShellCheck linting
  - Automated testing
- **tmux Configuration**: Modern terminal multiplexer setup
  - Ctrl-Space prefix
  - Vi-mode support
  - Mouse support
  - Intuitive split keys (| and -)
  - Custom status bar
- **SSH Config Template**: Comprehensive SSH configuration examples
  - GitHub/GitLab pre-configured
  - Jump host examples
  - Connection multiplexing
  - Security best practices
- **Security Audit Script**: Automated security checks
  - Hard-coded secrets detection
  - File permission validation
  - .gitignore coverage check
  - SSH configuration audit
- **CHANGELOG.md**: This file for tracking changes

### Documentation
- Created comprehensive `docs/README.md` as central documentation hub
- Updated main `README.md` with:
  - Secrets management documentation
  - Quality assurance metrics
  - XDG Base Directory compliance explanation
  - Complete documentation index
- Updated `config/zsh/README.md` with clearer scope and navigation
- Updated `IMPROVEMENTS_ROADMAP.md` with "Recently Completed" section

### Quality
- Fixed all 27 ShellCheck issues (1 warning, 26 info)
- All tests passing (`make test`)
- All scripts pass linting (`make lint`)
- Documentation accuracy verified (100% aligned)

## [2.0.0] - 2025-11-03

### Added
- **XDG Base Directory Compliance**
  - `~/.zshenv` for XDG variable initialization
  - `~/.zprofile` for login shell setup
  - All configs moved to `~/.config/zsh/`
  - Data in `~/.local/share/`
  - Cache in `~/.cache/zsh/`
- **Cross-Platform Support**
  - macOS (Intel & Apple Silicon)
  - Ubuntu/Debian
  - Fedora/CentOS
  - Arch/Manjaro
- **Comprehensive Secrets Management** (5 methods)
  - Plain file (development)
  - Password Store (pass) with GPG
  - 1Password CLI integration
  - macOS Keychain support
  - Linux Secret Service (Keyring)
- **Enhanced Git Configuration**
  - 25+ git aliases
  - Better log visualization
  - Platform-specific includes
  - Delta integration for diffs
- **Cross-Platform Completion System**
  - Platform-specific fpath management
  - Smart completion caching
  - kubectl, gh, helm, terraform, aws, gcloud completions
- **Utility Scripts**
  - `scripts/backup-dotfiles.sh` - Backup current configs
  - `scripts/update-all.sh` - Update packages and plugins
  - `scripts/profile-startup.sh` - Performance profiling
  - `scripts/test-dotfiles.sh` - Comprehensive testing
- **Documentation**
  - `docs/CUSTOMIZATION.md` - Customization guide
  - `docs/TROUBLESHOOTING.md` - Problem solving
  - `docs/SECRETS.md` - Secrets management guide
  - `GITHUB_AUTH_SETUP.md` - GitHub authentication

### Fixed
- Eliminated duplicate config loading in `.zshrc`
- Fixed `HISTFILE` location to be XDG compliant
- Package manager setup moved to `.zprofile`
- Improved cross-platform PATH management

### Changed
- Migrated from HTTPS to SSH for GitHub authentication
- Improved shell startup performance with lazy loading
- Enhanced completion system with better caching
- Restructured configuration for better modularity

### Performance
- Lazy loading for version managers (nvm, pyenv, rbenv)
- Efficient completion caching (rebuild only once per day)
- Optimized plugin loading
- Smart compinit initialization

## [1.5.0] - 2025-11-02

### Added
- OS detection framework (`config/zsh/os-detection.zsh`)
- Package manager abstraction layer
- Comprehensive function library
- FZF integration with custom functions
- Version manager integration (lazy loading)

### Improved
- Better error handling in scripts
- Enhanced prompt with git information
- Improved vi-mode configuration

## [1.0.0] - 2025-11-01 (Initial Public Release)

### Added
- Basic dotfiles structure
- Makefile for installation and maintenance
- ZSH configuration with plugins
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - fzf-tab
- Vim/Neovim configuration
- Git configuration
- Basic shell scripts
- Installation automation

### Platforms
- macOS support (Intel & Apple Silicon)
- Linux support (Ubuntu, Fedora, Arch)

## [0.1.0] - Prior to Public Release

### Initial Development
- Personal dotfiles collection
- Manual installation process
- Basic shell configuration
- Initial git setup

---

## Version Numbering

This project uses [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible changes (may require manual intervention)
- **MINOR** version: New features (backwards compatible)
- **PATCH** version: Bug fixes (backwards compatible)

## Categories

Changes are grouped into these categories:

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
- **Documentation**: Documentation changes
- **Performance**: Performance improvements
- **Quality**: Code quality improvements (linting, testing)

## See Also

- [IMPROVEMENTS_ROADMAP.md](IMPROVEMENTS_ROADMAP.md) - Planned improvements
- [docs/](docs/) - Complete documentation
- [GitHub Releases](https://github.com/markbsigler/.dotfiles/releases) - Tagged releases

