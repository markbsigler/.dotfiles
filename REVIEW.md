# Dotfiles Review & Improvement Plan

**Date**: May 29, 2026  
**Reviewed**: `~/.dotfiles`  
**User Preference**: Vim/MacVim as default editor (also uses VSCode)

---

## ✅ What's Working Well

1. **Excellent Organization**
   - XDG Base Directory compliance
   - Modular ZSH configuration with clear separation of concerns
   - Cross-platform support (macOS, Linux)
   - Good use of conditional loading

2. **Modern Shell Setup**
   - ZSH with plugins (syntax-highlighting, autosuggestions, fzf-tab)
   - Smart PATH management with deduplication
   - Platform-specific detection and handling

3. **Developer-Friendly**
   - Comprehensive package installation scripts
   - Makefile for easy management
   - Backup and restore functionality
   - Pre-commit hooks setup

4. **Version Control**
   - Good .gitignore coverage
   - Separate git configs for macOS and Linux

---

## 🔧 Critical Fixes Applied

### 1. ✅ FIXED: Editor Priority
- **Issue**: VSCode was prioritized over vim/macvim
- **Fix**: Reordered exports.zsh to prefer: MacVim → Vim → Neovim → VSCode
- **File**: `config/zsh/exports.zsh`

### 2. ✅ FIXED: Git Editor Configuration
- **Issue**: Hard-coded vim in gitconfig
- **Fix**: Now respects $GIT_EDITOR environment variable
- **File**: `config/git/gitconfig`

### 3. ✅ ADDED: .editorconfig
- **Purpose**: Ensures consistent coding styles across vim, vscode, and other editors
- **File**: `.editorconfig`

---

## 📋 Recommended Improvements

### High Priority

#### 1. Enhanced Vim Configuration

**Current Status**: Basic vimrc with minimal features

**Recommendations**:
- [ ] Add vim-plug plugin manager
- [ ] Install essential plugins (fugitive, fzf, surround, commentary)
- [ ] Configure MacVim-specific settings (clipboard, font, GUI options)
- [ ] Add persistent undo, better backup/swap directories
- [ ] Set up modern keybindings (space as leader, buffer navigation)

**Reference**: See `docs/VIM_SETUP.md` for complete implementation guide

#### 2. Neovim Modernization

**Current Status**: Using init.vim (legacy)

**Recommendations**:
- [ ] Create `config/nvim/init.lua` for modern Neovim
- [ ] Migrate to lazy.nvim or packer.nvim for plugin management
- [ ] Configure LSP (Language Server Protocol) for code intelligence
- [ ] Add treesitter for better syntax highlighting
- [ ] Set up telescope.nvim for fuzzy finding

**Example Structure**:
```
config/nvim/
├── init.lua                 # Main config entry point
├── lua/
│   ├── plugins.lua         # Plugin definitions
│   ├── settings.lua        # Core settings
│   ├── keymaps.lua         # Key mappings
│   └── lsp/                # LSP configurations
│       ├── init.lua
│       └── servers.lua
```

#### 3. MacVim Installation

```bash
# Install MacVim with Homebrew
brew install macvim

# Create GUI launcher
brew link macvim

# Verify installation
mvim --version
which mvim
```

#### 4. Shell Aliases for Vim/MacVim

Add to `config/zsh/aliases.zsh`:
```zsh
# Vim/MacVim aliases
if command -v mvim &> /dev/null; then
    alias vim="mvim -v"     # Use MacVim in terminal mode
    alias vi="mvim -v"
    alias vimdiff="mvim -d"
else
    alias vi="vim"
fi

# Quick config editing
alias vimrc="$EDITOR ~/.vim/vimrc"
alias nvimrc="$EDITOR ~/.config/nvim/init.lua"
alias zshrc="$EDITOR ~/.config/zsh/.zshrc"
```

### Medium Priority

#### 5. Security Improvements

**Current Issue**: `secrets.zsh` handling

**Recommendations**:
- [ ] Add template for secrets.zsh with examples
- [ ] Document secret management in README
- [ ] Consider using pass or 1Password CLI for secrets
- [ ] Add secrets.zsh.example to repo

**Example Template** (`config/zsh/secrets.zsh.example`):
```zsh
# secrets.zsh.example
# Copy to secrets.zsh and add your actual secrets
# This file is gitignored

# API Keys
# export OPENAI_API_KEY="sk-..."
# export GITHUB_TOKEN="ghp_..."

# Cloud Credentials
# export AWS_ACCESS_KEY_ID="..."
# export AWS_SECRET_ACCESS_KEY="..."

# Other Secrets
# export DATABASE_URL="postgresql://..."
```

#### 6. Tmux Configuration Enhancement

Current: Basic tmux config exists

**Recommendations**:
- [ ] Add vim-like keybindings for tmux
- [ ] Configure tmux-resurrect for session persistence
- [ ] Add status bar customization
- [ ] Enable mouse support
- [ ] Add plugin manager (TPM)

#### 7. Git Workflow Improvements

**Add to gitconfig**:
```gitconfig
[commit]
    # Show diff in commit message editor
    verbose = true
    # Template for commit messages
    # template = ~/.config/git/commit-template

[rerere]
    # Remember how conflicts were resolved
    enabled = true

[help]
    # Auto-correct typos after 1.5 seconds
    autocorrect = 15
```

### Low Priority

#### 8. Documentation Improvements

- [ ] Add CONTRIBUTING.md with instructions for personal customization
- [ ] Create TROUBLESHOOTING.md for common issues
- [ ] Document MCP-related configurations
- [ ] Add screenshots/examples to README

#### 9. Testing Enhancements

Current: Basic shell syntax testing

**Recommendations**:
- [ ] Add shellcheck to CI/CD
- [ ] Test vim/nvim configs on fresh install
- [ ] Add integration tests for all major workflows
- [ ] Test on different OS versions

#### 10. Backup Strategy

Current: Time-stamped backups

**Recommendations**:
- [ ] Add automated backup before updates
- [ ] Implement backup rotation (keep last 5)
- [ ] Add restore functionality to Makefile
- [ ] Document backup locations

---

## 🚀 Quick Action Items

### Immediate (Do Now)

1. **Install MacVim**:
   ```bash
   brew install macvim
   ```

2. **Test Editor Configuration**:
   ```bash
   source ~/.zshrc
   echo $EDITOR
   echo $VISUAL
   echo $GIT_EDITOR
   ```

3. **Install Vim-Plug**:
   ```bash
   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
   ```

### This Week

4. **Update vimrc** with recommended improvements
5. **Create secrets.zsh.example** template
6. **Add vim/macvim aliases** to aliases.zsh
7. **Test on a clean terminal** session

### This Month

8. **Migrate to Neovim Lua config**
9. **Set up LSP for your main languages**
10. **Add tmux plugin manager**
11. **Implement backup rotation**

---

## 📊 Configuration Consistency Matrix

| Tool | Config File | Editor Setting | Status |
|------|------------|----------------|--------|
| Shell | `exports.zsh` | MacVim → Vim → NeoVim | ✅ Fixed |
| Git | `gitconfig` | Uses $GIT_EDITOR | ✅ Fixed |
| Aider | `aider.conf.yml` | VSCode | ⚠️ Consider updating |
| Setup | `setup-tools.sh` | vim | ✅ OK |
| Tmux | `tmux.conf` | Not set | ⚠️ Add $EDITOR |

---

## 🔍 File Structure Analysis

### Current Structure (Good)
```
~/.dotfiles/
├── config/              # XDG-compliant
│   ├── zsh/            # Modular shell config ✅
│   ├── vim/            # Basic vim config ⚠️
│   ├── nvim/           # Legacy init.vim ⚠️
│   ├── git/            # Git configs ✅
│   ├── tmux/           # Tmux config ✅
│   └── aider/          # AI coding assistant ✅
├── scripts/            # Install/maintenance ✅
├── docs/               # Documentation ✅
├── Makefile            # Easy commands ✅
└── install.sh          # Main installer ✅
```

### Suggested Additions
```
~/.dotfiles/
├── config/
│   ├── vim/
│   │   └── after/          # After-plugins
│   ├── nvim/
│   │   ├── init.lua        # NEW: Modern config
│   │   └── lua/            # NEW: Lua modules
│   └── zsh/
│       └── secrets.zsh.example  # NEW: Template
├── docs/
│   ├── VIM_SETUP.md        # ✅ Created
│   ├── NEOVIM_SETUP.md     # NEW: Neovim guide
│   └── TROUBLESHOOTING.md  # NEW: Common issues
└── .editorconfig           # ✅ Created
```

---

## 🎯 Success Metrics

After implementing these changes, you should have:

- [ ] `mvim` or `vim` opens when you type `$EDITOR`
- [ ] Git commits open in vim/macvim
- [ ] Consistent behavior across all tools
- [ ] VSCode still available but not default
- [ ] Modern vim/neovim with plugins
- [ ] Efficient workflow for editing configs
- [ ] Proper backup and restore capabilities

---

## 📚 Resources

### Vim/MacVim
- [Vim Awesome](https://vimawesome.com/) - Plugin directory
- [vim-plug](https://github.com/junegunn/vim-plug) - Plugin manager
- [Learn Vimscript the Hard Way](https://learnvimscriptthehardway.stevelosh.com/)

### Neovim
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) - Starting point
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Modern plugin manager
- [NvChad](https://nvchad.com/) - Neovim config framework

### Dotfiles
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)

---

## 💡 Tips

1. **Test Changes Incrementally**: Don't update everything at once
2. **Keep Backups**: Use `make backup` before major changes
3. **Use Branches**: Create a git branch for experimental changes
4. **Document Customizations**: Add comments explaining non-obvious config
5. **Share Learnings**: Update docs when you solve a problem

---

## 🐛 Known Issues to Monitor

1. **ZSH Compinit Warnings**: Check for permission issues on completions
2. **MacVim GUI vs Terminal**: Some aliases might need adjustment
3. **VSCode Integration**: Ensure shell commands still work in VSCode terminal
4. **Path Conflicts**: Watch for duplicate entries after updates

---

## Next Steps

1. Review this document
2. Apply immediate action items
3. Test thoroughly in a new terminal
4. Implement high-priority improvements
5. Schedule time for medium/low priority items
6. Update this review document as you make changes

---

**Last Updated**: 2026-05-29  
**Status**: Initial Review Complete, Improvements In Progress
