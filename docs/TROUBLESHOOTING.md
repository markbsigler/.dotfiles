# Troubleshooting Guide

Common issues and solutions for dotfiles configuration on macOS and Linux.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Shell Issues](#shell-issues)
- [Performance Issues](#performance-issues)
- [Plugin Issues](#plugin-issues)
- [Path Issues](#path-issues)
- [Completion Issues](#completion-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Git Issues](#git-issues)

## Installation Issues

### Issue: Install script fails with permission errors

**Symptoms:**
```
Permission denied: cannot create directory
```

**Solution:**
```bash
# Ensure dotfiles directory ownership
sudo chown -R $USER:$(id -gn) ~/.dotfiles

# Re-run installation
cd ~/.dotfiles && make install
```

### Issue: Symlinks not created

**Symptoms:**
```
❌ Failed to create symlink: ~/.zshrc
```

**Solution:**
```bash
# Check if files already exist (backup them first)
ls -la ~/ | grep -E '\.(zshrc|zshenv|zprofile|gitconfig|vimrc)'

# Manually remove conflicting files (after backing up)
mv ~/.zshrc ~/.zshrc.backup

# Re-run installation
make install
```

### Issue: Homebrew not found on macOS

**Symptoms:**
```
brew: command not found
```

**Solution:**
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Or (Intel Mac)
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"

# Re-run installation
cd ~/.dotfiles && make install
```

## Shell Issues

### Issue: Slow shell startup

**Symptoms:**
- Shell takes > 1 second to start
- Noticeable delay when opening new terminal

**Diagnosis:**
```bash
# Profile startup time
~/.dotfiles/scripts/profile-startup.sh

# Detailed profiling
~/.dotfiles/scripts/profile-startup.sh --detailed
```

**Common Causes & Solutions:**

1. **Version managers loading eagerly**
```bash
# Check version-managers.zsh for lazy loading
# Should see:
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm "$@"
}
```

2. **Too many plugins**
```bash
# Disable plugins temporarily in ~/.config/zsh/local.zsh
DISABLE_PLUGINS=true
source ~/.zshrc

# If faster, review plugins in config/zsh/plugins.zsh
```

3. **Completion system rebuilding**
```bash
# Ensure completion cache is working
ls -la $XDG_CACHE_HOME/zsh/zcompdump

# Should only rebuild once per day
```

### Issue: Command not found after installation

**Symptoms:**
```
zsh: command not found: brew
zsh: command not found: nvm
```

**Solution:**
```bash
# Check PATH
echo $PATH

# Reload shell configuration
source ~/.zshrc

# Or start a new login shell
exec zsh -l

# Check if .zprofile is loaded
echo $ZPROFILE_LOADED  # Should output: 1

# Verify dotfiles loading
echo $ZSHRC_LOADED     # Should output: 1
```

### Issue: ZSH not set as default shell

**Symptoms:**
- Terminal still opens bash
- `.zshrc` not loaded

**Solution:**
```bash
# Check current shell
echo $SHELL

# Set ZSH as default (macOS)
chsh -s $(which zsh)

# Set ZSH as default (Linux)
sudo chsh -s $(which zsh) $USER

# Restart terminal or login again
```

## Performance Issues

### Issue: High CPU usage in terminal

**Diagnosis:**
```bash
# Check running processes
top -o cpu

# Profile zsh
zsh --version
~/.dotfiles/scripts/profile-startup.sh --detailed
```

**Common Causes:**

1. **Infinite loop in config**
```bash
# Check for recursive sourcing
grep -r "source.*zshrc" ~/.config/zsh/
```

2. **Heavy git operations in prompt**
```bash
# Disable git in prompt temporarily
DISABLE_GIT_PROMPT=true
source ~/.zshrc
```

### Issue: Commands feel slow

**Solution:**
```bash
# Clear completion cache
rm -f $XDG_CACHE_HOME/zsh/zcompdump
rm -rf $XDG_CACHE_HOME/zsh/zcompcache

# Rebuild completions
autoload -U compinit && compinit

# Check disk I/O
iostat 1 5  # macOS
vmstat 1 5  # Linux
```

## Plugin Issues

### Issue: Plugins not loading

**Symptoms:**
```
No syntax highlighting
No autosuggestions
```

**Solution:**
```bash
# Check plugin directory
ls -la ~/.local/share/zsh/plugins/

# Reinstall plugins (macOS)
brew reinstall zsh-autosuggestions zsh-syntax-highlighting

# Reinstall plugins (Linux)
cd ~/.local/share/zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting

# Reload shell
source ~/.zshrc
```

### Issue: Plugin conflicts

**Symptoms:**
- Strange behavior after adding plugin
- Commands not working as expected

**Solution:**
```bash
# Disable all plugins
mv ~/.config/zsh/plugins.zsh ~/.config/zsh/plugins.zsh.disabled
source ~/.zshrc

# Re-enable one by one to find conflict
mv ~/.config/zsh/plugins.zsh.disabled ~/.config/zsh/plugins.zsh
```

## Path Issues

### Issue: Wrong command version being used

**Symptoms:**
```bash
which python  # Shows system python instead of Homebrew
python --version  # Shows old version
```

**Solution:**
```bash
# Check PATH order
echo $PATH | tr ':' '\n' | nl

# Ensure Homebrew paths are first (macOS)
# Should see /opt/homebrew/bin or /usr/local/bin near the top

# Clean duplicate paths
clean_path
echo $PATH | tr ':' '\n' | nl

# Verify command location
which python
which python3
```

### Issue: PATH duplicates

**Symptoms:**
```bash
echo $PATH  # Shows same directory multiple times
```

**Solution:**
```bash
# Use clean_path function
clean_path

# Or manually in ~/.config/zsh/local.zsh
typeset -U PATH  # Ensures uniqueness
```

## Completion Issues

### Issue: Tab completion not working

**Symptoms:**
- Tab does nothing
- No suggestions appear

**Solution:**
```bash
# Rebuild completion cache
rm -f ~/.zcompdump*
rm -f $XDG_CACHE_HOME/zsh/zcompdump
autoload -U compinit && compinit

# Check completion setup
echo $fpath | tr ' ' '\n'

# Verify compinit loaded
typeset -f compinit
```

### Issue: Completion shows warnings

**Symptoms:**
```
zsh compinit: insecure directories
```

**Solution:**
```bash
# macOS: Fix Homebrew permissions
chmod go-w /opt/homebrew/share
chmod -R go-w /opt/homebrew/share/zsh

# Linux: Fix permissions
sudo chmod -R 755 /usr/local/share/zsh

# Or skip security check
export ZSH_DISABLE_COMPFIX=true
```

## Platform-Specific Issues

### macOS Issues

#### Issue: Command line tools not found

**Solution:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p
```

#### Issue: Permission denied on Homebrew

**Solution:**
```bash
# Fix Homebrew permissions (Apple Silicon)
sudo chown -R $(whoami) /opt/homebrew

# Fix Homebrew permissions (Intel)
sudo chown -R $(whoami) /usr/local
```

#### Issue: macOS Keychain prompts

**Solution:**
```bash
# Update git credential helper
git config --global credential.helper osxkeychain

# Clear and re-add credentials
git credential-osxkeychain erase
# (Then re-authenticate on next git operation)
```

### Linux Issues

#### Issue: Missing dependencies on Ubuntu

**Solution:**
```bash
# Install build essentials
sudo apt update
sudo apt install -y build-essential curl git zsh

# Install modern CLI tools
cd ~/.dotfiles && ./scripts/install-packages.sh
```

#### Issue: Snap/Flatpak not in PATH

**Solution:**
```bash
# Add to ~/.config/zsh/local.zsh
export PATH="/snap/bin:$PATH"
export PATH="/var/lib/flatpak/exports/bin:$PATH"

# Reload
source ~/.zshrc
```

## Git Issues

### Issue: Git credential helper not working

**macOS Solution:**
```bash
# Set to use Keychain
git config --global credential.helper osxkeychain
```

**Linux Solution:**
```bash
# Use cache
git config --global credential.helper 'cache --timeout=3600'

# Or use libsecret
sudo apt install libsecret-1-0 libsecret-1-dev
cd /usr/share/doc/git/contrib/credential/libsecret
sudo make
git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
```

### Issue: Git aliases not working

**Solution:**
```bash
# Check if git config is linked
ls -la ~/.gitconfig

# Verify aliases are loaded
git config --get-regexp alias

# Manually source git config
git config --global include.path ~/.config/git/gitconfig
```

## Environment Variables Issues

### Issue: XDG variables not set

**Solution:**
```bash
# Check if .zshenv is loaded
ls -la ~/.zshenv

# Verify XDG variables
echo $XDG_CONFIG_HOME  # Should be ~/.config
echo $XDG_DATA_HOME    # Should be ~/.local/share
echo $XDG_CACHE_HOME   # Should be ~/.cache

# If missing, create symlink
ln -sf ~/.dotfiles/config/zsh/.zshenv ~/.zshenv

# Start new login shell
exec zsh -l
```

### Issue: ZDOTDIR not set

**Solution:**
```bash
# Check ZDOTDIR
echo $ZDOTDIR  # Should be ~/.config/zsh

# If not set, ensure .zshenv is sourced
source ~/.zshenv
```

## Reset and Recovery

### Nuclear Option: Complete Reset

```bash
# Backup current configuration
~/.dotfiles/scripts/backup-dotfiles.sh

# Remove all dotfiles symlinks
rm ~/.zshrc ~/.zshenv ~/.zprofile ~/.gitconfig ~/.vimrc

# Remove config directories
rm -rf ~/.config/zsh ~/.config/nvim ~/.config/git

# Re-install
cd ~/.dotfiles && make install

# Verify
make doctor
```

### Restore from Backup

```bash
# List backups
ls -lt ~/ | grep dotfiles-backup

# Restore (replace TIMESTAMP)
cp -r ~/.dotfiles-backup-TIMESTAMP/* ~/

# Reload
source ~/.zshrc
```

## Diagnostic Commands

### Check System Health

```bash
# Run doctor command
make doctor

# Check all commands
make test

# Profile startup
~/.dotfiles/scripts/profile-startup.sh
```

### Debug Loading

```bash
# Trace zsh loading
zsh -x -c exit 2>&1 | less

# Check what's sourced
PS4='+%x:%I>' zsh -x -c exit 2>&1 | grep -E '^[^+]'
```

### Check Specific Features

```bash
# Check completions
echo $fpath | tr ' ' '\n'
ls -la $XDG_CACHE_HOME/zsh/

# Check plugins
ls -la ~/.local/share/zsh/plugins/

# Check PATH
echo $PATH | tr ':' '\n' | nl

# Check loaded functions
typeset -f | grep '^[a-zA-Z_-]* ()' | sed 's/ ()//'
```

## Getting More Help

1. **Check logs:**
```bash
cat ~/.dotfiles/install.log
```

2. **Run doctor:**
```bash
make doctor
```

3. **Enable verbose mode:**
```bash
VERBOSE=true make install
```

4. **Check GitHub issues:**
```bash
# Search for similar issues
gh issue list --repo markbsigler/.dotfiles
```

5. **Create an issue:**
```bash
# Include output of:
make doctor
zsh --version
uname -a
```

## Still Having Issues?

If none of these solutions work:

1. Backup your current setup
2. Create a minimal test config
3. Add components back one at a time
4. Identify the problematic component
5. Open a GitHub issue with details

**Include in your issue:**
- OS and version (`uname -a`)
- Shell version (`zsh --version`)
- Output of `make doctor`
- Relevant error messages
- Steps to reproduce

