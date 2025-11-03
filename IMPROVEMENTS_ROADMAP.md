# Dotfiles Improvements Roadmap

## Executive Summary

Your dotfiles are **already excellent** with enterprise-grade features. This roadmap outlines 26 potential enhancements organized by priority.

**Current Score: 8.5/10** - Production-ready with room for perfection.

---

## 🏆 Top 10 Quick Wins (Implement These First)

### 1. Add GitHub Actions CI/CD
**Effort:** Low | **Impact:** High | **Time:** 30 min

```yaml
# .github/workflows/test.yml
name: Test Dotfiles

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install zsh
        run: |
          if [ "$RUNNER_OS" == "Linux" ]; then
            sudo apt-get update && sudo apt-get install -y zsh
          fi
      
      - name: Run tests
        run: ./scripts/test-dotfiles.sh
      
      - name: Lint shell scripts
        run: |
          sudo apt-get install -y shellcheck || brew install shellcheck
          make lint
```

**Benefits:**
- Automatic testing on every push
- Catches errors before merging
- Tests on both macOS and Linux

---

### 2. Add Pre-commit Hooks
**Effort:** Low | **Impact:** Medium | **Time:** 20 min

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
  
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck
        args: [--severity=warning]
  
  - repo: local
    hooks:
      - id: test-dotfiles
        name: Test dotfiles
        entry: ./scripts/test-dotfiles.sh --quick
        language: system
        pass_filenames: false
```

```bash
# Install
pip install pre-commit
pre-commit install

# Run manually
pre-commit run --all-files
```

---

### 3. Add tmux Configuration
**Effort:** Medium | **Impact:** High | **Time:** 45 min

```bash
# config/tmux/tmux.conf
# Modern tmux configuration with sensible defaults

# Set prefix to Ctrl-Space
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix

# Use 256 colors
set -g default-terminal "screen-256color"

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Mouse support
set -g mouse on

# Vi mode
setw -g mode-keys vi

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Status bar
set -g status-style 'bg=#333333 fg=#5eacd3'
set -g status-left-length 40
set -g status-right '#[fg=yellow]#(whoami)@#h #[fg=white]%H:%M'

# Pane border
set -g pane-border-style 'fg=#444444'
set -g pane-active-border-style 'fg=#5eacd3'

# Plugins (optional - using TPM)
# set -g @plugin 'tmux-plugins/tpm'
# set -g @plugin 'tmux-plugins/tmux-sensible'
# set -g @plugin 'tmux-plugins/tmux-yank'
```

---

### 4. Add Restore Script
**Effort:** Low | **Impact:** Medium | **Time:** 30 min

```bash
# scripts/restore-dotfiles.sh
#!/usr/bin/env bash
# Restore dotfiles from backup

BACKUP_DIR="${1:-$(ls -dt ~/.dotfiles-backup-* | head -1)}"

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "❌ No backup found"
    exit 1
fi

echo "📦 Restoring from: $BACKUP_DIR"

# Remove current symlinks
rm -f ~/.zshrc ~/.zshenv ~/.zprofile ~/.gitconfig

# Restore files
cp -r "$BACKUP_DIR"/* ~/

echo "✅ Restored successfully"
echo "⚠️  Restart your shell: exec zsh"
```

---

### 5. Add Environment Profiles
**Effort:** Medium | **Impact:** High | **Time:** 40 min

```bash
# config/zsh/profiles.zsh
# Environment profile switcher

# Profile directory
PROFILE_DIR="$HOME/.config/zsh/profiles"
mkdir -p "$PROFILE_DIR"

# Switch to work profile
work() {
    export GIT_AUTHOR_EMAIL="mark.sigler@work.com"
    export GIT_COMMITTER_EMAIL="mark.sigler@work.com"
    export PROFILE="work"
    
    # Load work-specific config
    [[ -f "$PROFILE_DIR/work.zsh" ]] && source "$PROFILE_DIR/work.zsh"
    
    echo "✅ Switched to WORK profile"
}

# Switch to personal profile
personal() {
    export GIT_AUTHOR_EMAIL="markbsigler@gmail.com"
    export GIT_COMMITTER_EMAIL="markbsigler@gmail.com"
    export PROFILE="personal"
    
    # Load personal-specific config
    [[ -f "$PROFILE_DIR/personal.zsh" ]] && source "$PROFILE_DIR/personal.zsh"
    
    echo "✅ Switched to PERSONAL profile"
}

# Auto-detect profile based on directory
auto_profile() {
    if [[ "$PWD" =~ "/work/" ]] || [[ "$PWD" =~ "/Work/" ]]; then
        [[ "$PROFILE" != "work" ]] && work
    elif [[ "$PWD" =~ "/personal/" ]] || [[ "$PWD" =~ "/Personal/" ]]; then
        [[ "$PROFILE" != "personal" ]] && personal
    fi
}

# Hook to run on directory change
chpwd_functions+=(auto_profile)

# Set default profile on startup
[[ -z "$PROFILE" ]] && personal
```

---

### 6. Add SSH Config Template
**Effort:** Low | **Impact:** Medium | **Time:** 20 min

```bash
# config/ssh/config.template
# SSH Configuration Template

# Default settings
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    
# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519

# Work servers (examples)
# Host work-server
#     HostName server.company.com
#     User myusername
#     Port 2222
#     IdentityFile ~/.ssh/work_id_rsa

# Jump host example
# Host internal-server
#     HostName 192.168.1.100
#     ProxyJump bastion.company.com
#     User myusername
```

---

### 7. Add Security Audit Script
**Effort:** Medium | **Impact:** High | **Time:** 45 min

```bash
# scripts/security-audit.sh
#!/usr/bin/env bash
# Audit dotfiles for potential security issues

echo "🔒 Security Audit"
echo "================="

# Check for hard-coded secrets
echo -e "\n1. Checking for potential secrets..."
if rg -i '(password|secret|api_key|token|credentials).*=.*["\x27][^"\x27]+["\x27]' . \
   --glob '!*.md' --glob '!*audit*' --glob '!SECRETS.md' 2>/dev/null; then
    echo "⚠️  Found potential hard-coded secrets"
else
    echo "✅ No hard-coded secrets found"
fi

# Check file permissions
echo -e "\n2. Checking file permissions..."
if find . -type f -perm -002 2>/dev/null | grep -v ".git"; then
    echo "⚠️  Found world-writable files"
else
    echo "✅ No world-writable files"
fi

# Check for .env files
echo -e "\n3. Checking for .env files..."
if find . -name ".env*" -type f 2>/dev/null | grep -v ".gitignore"; then
    echo "⚠️  Found .env files (ensure they're in .gitignore)"
else
    echo "✅ No .env files found"
fi

# Check .gitignore coverage
echo -e "\n4. Checking .gitignore coverage..."
sensitive=("*.key" "*.pem" "*.p12" "*secret*" "*.env")
missing=()
for pattern in "${sensitive[@]}"; do
    if ! grep -q "$pattern" .gitignore 2>/dev/null; then
        missing+=("$pattern")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "⚠️  Missing patterns in .gitignore: ${missing[*]}"
else
    echo "✅ .gitignore covers sensitive patterns"
fi

# Check SSH permissions
echo -e "\n5. Checking SSH configuration..."
if [[ -d ~/.ssh ]]; then
    if [[ $(stat -f %A ~/.ssh 2>/dev/null || stat -c %a ~/.ssh 2>/dev/null) == "700" ]]; then
        echo "✅ ~/.ssh has correct permissions"
    else
        echo "⚠️  ~/.ssh should have 700 permissions"
    fi
fi

echo -e "\n✅ Security audit complete"
```

---

### 8. Add CHANGELOG.md
**Effort:** Low | **Impact:** Medium | **Time:** 15 min

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI/CD pipeline
- Pre-commit hooks configuration
- Security audit script
- Environment profile switcher

## [2.0.0] - 2025-11-03

### Added
- XDG Base Directory compliance with .zshenv
- Cross-platform login shell initialization with .zprofile
- Comprehensive secrets management (5 methods)
- Enhanced git configuration with 25+ aliases
- Cross-platform completion system
- Utility scripts (backup, update, profile)
- Documentation (CUSTOMIZATION, TROUBLESHOOTING, SECRETS)

### Fixed
- Eliminated duplicate config loading in .zshrc
- Performance improvements (smart caching)

### Changed
- Migrated from HTTPS to SSH for GitHub
- Improved cross-platform compatibility

## [1.0.0] - Initial Release

### Added
- Basic dotfiles structure
- macOS and Linux support
- Vim and Neovim configuration
- Git configuration
- ZSH configuration with plugins
```

---

### 9. Enhance Makefile
**Effort:** Low | **Impact:** Medium | **Time:** 20 min

```makefile
# Add these targets to existing Makefile

## Security audit
security:
	@echo "$(GREEN)Running security audit...$(NC)"
	@./scripts/security-audit.sh

## Sync with remote
sync:
	@echo "$(GREEN)Syncing with remote...$(NC)"
	@git pull --rebase
	@./scripts/update-all.sh
	@git push

## Restore from backup
restore:
	@echo "$(GREEN)Restoring from backup...$(NC)"
	@./scripts/restore-dotfiles.sh

## List all Make targets
list-all:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Check for updates
check-updates:
	@echo "$(GREEN)Checking for updates...$(NC)"
	@./scripts/check-outdated.sh

## Profile performance
profile:
	@./scripts/profile-startup.sh --detailed
```

---

### 10. Add FAQ Documentation
**Effort:** Low | **Impact:** Medium | **Time:** 30 min

```markdown
# docs/FAQ.md
# Frequently Asked Questions

## Installation

### Q: How do I install on a fresh system?
```bash
git clone git@github.com:markbsigler/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && make install
```

### Q: Can I preview changes before installing?
```bash
make install-dry
```

### Q: How do I restore if something breaks?
```bash
# Backups are automatically created
ls -lt ~/ | grep dotfiles-backup
./scripts/restore-dotfiles.sh
```

## Usage

### Q: How do I add custom aliases?
Edit `~/.config/zsh/local.zsh` (not tracked in git)

### Q: How do I switch between work and personal environments?
```bash
work      # Switch to work profile
personal  # Switch to personal profile
```

### Q: How do I add secrets securely?
```bash
secret_help  # Show all methods
secret_add KEY "value"  # Simple method
# Or use Keychain, 1Password, etc.
```

## Troubleshooting

### Q: Shell is slow to start
```bash
./scripts/profile-startup.sh --detailed
# Look for slow functions and optimize
```

### Q: Completions not working
```bash
rm -f ~/.zcompdump*
autoload -U compinit && compinit
```

### Q: Git push asks for password
GitHub disabled password auth. Use SSH or PAT.
See: `GITHUB_AUTH_SETUP.md`

## Customization

### Q: How do I add a new plugin?
```bash
git clone <plugin-url> ~/.local/share/zsh/plugins/plugin-name
# Then add to ~/.config/zsh/local.zsh:
source ~/.local/share/zsh/plugins/plugin-name/plugin-name.zsh
```

### Q: How do I customize the prompt?
Edit `~/.config/zsh/local.zsh`:
```bash
PROMPT='%~ $ '
```

## Cross-Platform

### Q: Does this work on Linux?
Yes! Supports Ubuntu, Debian, Fedora, and Arch Linux.

### Q: Does this work on WSL2?
Partial support. See TROUBLESHOOTING.md for Windows-specific issues.

### Q: How do I use on multiple machines?
```bash
# On each machine:
git clone git@github.com:markbsigler/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && make install
```
```

---

## 📊 Implementation Priority Matrix

| Priority | Effort | Impact | Recommendation |
|----------|--------|--------|----------------|
| 1. GitHub Actions | Low | High | ⭐⭐⭐ Do First |
| 2. Pre-commit Hooks | Low | Med | ⭐⭐⭐ Do First |
| 3. tmux Config | Med | High | ⭐⭐⭐ Do First |
| 4. Restore Script | Low | Med | ⭐⭐ Do Next |
| 5. Profiles | Med | High | ⭐⭐ Do Next |
| 6. SSH Template | Low | Med | ⭐⭐ Do Next |
| 7. Security Audit | Med | High | ⭐⭐ Do Next |
| 8. CHANGELOG | Low | Med | ⭐ Nice to Have |
| 9. Makefile++ | Low | Med | ⭐ Nice to Have |
| 10. FAQ | Low | Med | ⭐ Nice to Have |

---

## 🚀 Quick Start (Next 2 Hours)

```bash
# 1. Add GitHub Actions (30 min)
mkdir -p .github/workflows
# Create .github/workflows/test.yml

# 2. Add Pre-commit (20 min)
pip install pre-commit
# Create .pre-commit-config.yaml
pre-commit install

# 3. Add tmux config (45 min)
# Create config/tmux/tmux.conf

# 4. Add Restore script (15 min)
# Create scripts/restore-dotfiles.sh

# 5. Test everything (10 min)
make test
pre-commit run --all-files

# 6. Commit and push
git add .
git commit -m "feat: add CI/CD, pre-commit, tmux, restore script"
git push
```

---

## 🎯 Long-term Roadmap

### Phase 1 (This Week): Quick Wins 1-10
- CI/CD, pre-commit, tmux, restore, profiles
- Estimated: 4-6 hours total

### Phase 2 (This Month): Documentation
- FAQ, ARCHITECTURE, CONTRIBUTING
- Estimated: 2-3 hours total

### Phase 3 (Next Month): Advanced Features
- Plugin manager, Docker testing, package sync
- Estimated: 6-8 hours total

### Phase 4 (Future): Nice-to-Haves
- WSL2 enhancement, FreeBSD support, Dotbot
- As needed

---

## ✅ Current Status

**Your dotfiles are already production-ready!**

These improvements are **enhancements**, not fixes. You have:
- ✅ Excellent cross-platform support
- ✅ Comprehensive documentation
- ✅ Security best practices
- ✅ Performance optimizations
- ✅ Modern tooling integration

Focus on the "Quick Wins" if you want to reach 10/10 perfection!

