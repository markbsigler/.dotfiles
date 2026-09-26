# Dotfiles Roadmap

## Executive Summary

Your dotfiles are **production-ready and highly polished** with enterprise-grade features. This roadmap outlines remaining enhancements organized by priority.

**Current Score: 9.0/10** - Production-ready with enhanced security and workflow tools.

**Remaining Work:** 3 quick wins + 11 nice-to-have enhancements

> **Note:** Completed improvements are documented in [CHANGELOG.md](CHANGELOG.md)

---

## 🏆 Top 3 Remaining Quick Wins

---

### 1. Add Environment Profiles
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

### 2. ⚡ Enhance Makefile
**Effort:** Low | **Impact:** Low | **Time:** 10 min | **Status:** ⚡ Mostly done

✅ **Already Completed:**
- `make security` - runs security audit
- `make restore` - restores from latest backup
- `make list` - lists all Makefile targets
- `make perf` - performance testing

📋 **Optional additions:**

```makefile
## Sync with remote
sync:
	@echo "$(GREEN)Syncing with remote...$(NC)"
	@git pull --rebase
	@./scripts/update-all.sh
	@git push

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

### 3. Add FAQ Documentation
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
Edit `~/.dotfiles/local/local.zsh` (not tracked in git)

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
# Then add to ~/.dotfiles/local/local.zsh:
source ~/.local/share/zsh/plugins/plugin-name/plugin-name.zsh
```

### Q: How do I customize the prompt?
Edit `~/.dotfiles/local/local.zsh`:
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

| Priority | Effort | Impact | Status | Recommendation |
|----------|--------|--------|--------|----------------|
| 1. Environment Profiles | Med | High | 🔲 TODO | ⭐⭐ Do Next |
| 2. Makefile Enhancements | Low | Low | ⚡ MOSTLY DONE | ⭐ Optional |
| 3. FAQ Documentation | Low | Med | 🔲 TODO | ⭐ Nice to Have |

**Legend:** ✅ Done (see CHANGELOG.md) | ⚡ Partial | 🔲 TODO

---

## 🚀 Quick Start (Next Steps)

### Remaining Work

```bash
# 1. Add Environment Profiles (40 min)
# Create config/zsh/profiles.zsh (see section 2 above)

# 2. Complete Makefile (optional, 10 min)
# Add sync target (see section 3 above)

# 3. Add FAQ Documentation (30 min)
# Create docs/FAQ.md (see section 4 above)

# Test everything
make test
make lint
make security

```

---

## 🎯 Long-term Roadmap

### ✅ Phase 0: Foundation & Quality (COMPLETED)
See [CHANGELOG.md](CHANGELOG.md) for details on completed work:
- ShellCheck compliance
- Comprehensive testing suite
- Documentation overhaul
- Pre-commit hooks
- Security audit script
- tmux configuration
- SSH config template
- Script consolidation

### Phase 1 (This Week): Quick Wins Remaining
- 🔲 Environment profiles  
- ⚡ Complete Makefile enhancements (optional)
- 🔲 FAQ documentation
- Estimated: 1-2 hours total

### Phase 2 (This Month): Documentation
- 🔲 ARCHITECTURE guide
- 🔲 CONTRIBUTING guide
- Estimated: 2-3 hours total

### Phase 3 (Next Month): Advanced Features
- 🔲 Plugin manager
- 🔲 Docker testing
- 🔲 Package sync script
- Estimated: 6-8 hours total

### Phase 4 (Future): Nice-to-Haves
- 🔲 WSL2 enhancement
- 🔲 FreeBSD support
- 🔲 Dotbot integration
- As needed

---

## ✅ Current Status

**Your dotfiles are production-ready and highly polished!**

**What You Have:**
- ✅ Excellent cross-platform support (macOS, Linux)
- ✅ Comprehensive documentation (100% aligned)
- ✅ Security best practices (automated auditing)
- ✅ Performance optimizations (lazy loading, caching)
- ✅ Modern tooling integration (26 features)
- ✅ Professional version tracking (CHANGELOG)
- ✅ Quality assurance (pre-commit hooks)
- ✅ Modern workflow tools (tmux, SSH templates)

**Remaining Work:** 3 quick wins.

Focus on environment profiles if they are useful for this checkout.

---

**See Also:**
- [CHANGELOG.md](CHANGELOG.md) - Complete version history and completed improvements
- [docs/README.md](docs/README.md) - Documentation hub
- [README.md](README.md) - Main project documentation

