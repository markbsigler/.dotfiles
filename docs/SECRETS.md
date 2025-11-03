# Secrets Management Guide

Comprehensive guide for managing API keys, tokens, and credentials in your dotfiles.

## Table of Contents

- [Overview](#overview)
- [Security Levels](#security-levels)
- [Method 1: Plain File](#method-1-plain-file)
- [Method 2: Password Store (pass)](#method-2-password-store-pass)
- [Method 3: 1Password CLI](#method-3-1password-cli)
- [Method 4: macOS Keychain](#method-4-macos-keychain)
- [Method 5: Linux Secret Service](#method-5-linux-secret-service)
- [Best Practices](#best-practices)
- [Migration Guide](#migration-guide)

## Overview

The dotfiles include a comprehensive secrets management system that supports multiple methods from simple (plain text) to enterprise-grade (1Password). Choose the method that best fits your security requirements.

### Quick Start

```bash
# Show all available methods
secret_help

# Simple method (good for development)
secret_add GITHUB_TOKEN "ghp_xxxxxxxxxxxx"
secret_list

# Secure method (macOS)
keychain_add github_token "ghp_xxxxxxxxxxxx"
secret_from_keychain GITHUB_TOKEN github_token

# Most secure (any platform with 1Password)
secret_from_1password GITHUB_TOKEN "op://Personal/GitHub/token"
```

## Security Levels

| Method | Security | Ease of Use | Platforms | Best For |
|--------|----------|-------------|-----------|----------|
| Plain File | ⭐ | ⭐⭐⭐⭐⭐ | All | Development |
| Password Store | ⭐⭐⭐⭐ | ⭐⭐⭐ | macOS/Linux | Power Users |
| 1Password CLI | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | All | Enterprise |
| macOS Keychain | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | macOS only | Mac Users |
| Linux Keyring | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Linux GUI | Linux Desktop |

## Method 1: Plain File

### Pros
- ✅ Simple to use
- ✅ No additional software required
- ✅ Works everywhere
- ✅ Easy to backup

### Cons
- ❌ Secrets stored in plain text
- ❌ File permissions are only protection
- ❌ Risk if computer compromised

### Setup

No setup required - the system creates `~/.secrets/env` automatically with proper permissions (600).

### Usage

```bash
# Add a secret
secret_add GITHUB_TOKEN "ghp_xxxxxxxxxxxx"

# Add multiple secrets
secret_add OPENAI_API_KEY "sk-xxxxxxxxxxxxxxxx"
secret_add AWS_ACCESS_KEY_ID "AKIAXXXXXXXXXXXXXXXX"
secret_add AWS_SECRET_ACCESS_KEY "xxxxxxxxxxxxxxxxxxxxxx"

# List secrets (keys only, not values)
secret_list

# Remove a secret
secret_remove GITHUB_TOKEN
```

### File Format

The secrets are stored in `~/.secrets/env` as:

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxx"
```

### Manual Editing

```bash
# Edit the file directly
vim ~/.secrets/env

# Reload after editing
source ~/.zshrc
```

### Security Notes

- File has 600 permissions (only you can read/write)
- Directory has 700 permissions (only you can access)
- Never commit this directory to git (already in .gitignore)
- Consider encrypting your home directory

## Method 2: Password Store (pass)

### Pros
- ✅ GPG-encrypted storage
- ✅ Git integration for backup
- ✅ Standard Unix tool
- ✅ Terminal-based

### Cons
- ❌ Requires GPG setup
- ❌ CLI-only
- ❌ Steeper learning curve

### Setup

```bash
# Install pass
# macOS
brew install pass

# Ubuntu/Debian
sudo apt install pass

# Generate GPG key if you don't have one
gpg --full-generate-key

# Initialize pass with your GPG key ID
pass init your-gpg-key-id
```

### Usage

```bash
# Store a secret
pass insert github/token
# (Enter your token when prompted)

# Load secret into environment variable
secret_from_pass GITHUB_TOKEN github/token

# View a secret
pass show github/token

# List all secrets
pass ls

# Remove a secret
pass rm github/token
```

### Automation in .zshrc

Add to `~/.config/zsh/local.zsh`:

```bash
# Auto-load secrets from pass
if command -v pass &> /dev/null; then
    secret_from_pass GITHUB_TOKEN github/token
    secret_from_pass OPENAI_API_KEY openai/api-key
    secret_from_pass AWS_ACCESS_KEY_ID aws/access-key-id
fi
```

### Backup

```bash
# Initialize git repository
pass git init

# Add remote
pass git remote add origin git@github.com:yourusername/password-store.git

# Push
pass git push
```

## Method 3: 1Password CLI

### Pros
- ✅ Enterprise-grade security
- ✅ Cross-platform
- ✅ GUI + CLI
- ✅ Team sharing
- ✅ Excellent documentation

### Cons
- ❌ Requires 1Password subscription
- ❌ Additional software

### Setup

```bash
# Install 1Password CLI
# macOS
brew install --cask 1password-cli

# Linux
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

# Ubuntu/Debian
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  sudo tee /etc/apt/sources.list.d/1password.list
sudo apt update && sudo apt install 1password-cli

# Sign in
op signin
```

### Usage

```bash
# Get reference path from 1Password
# In 1Password, right-click item → "Copy Private Link"
# Or get path: op://Vault/Item/field

# Load secret
secret_from_1password GITHUB_TOKEN "op://Personal/GitHub/token"

# List items
op item list

# Get item details
op item get GitHub
```

### Automation in .zshrc

Add to `~/.config/zsh/local.zsh`:

```bash
# Auto-load secrets from 1Password
if command -v op &> /dev/null; then
    # Sign in if needed (will prompt once)
    op signin --account your-account.1password.com 2>/dev/null || true
    
    # Load secrets
    secret_from_1password GITHUB_TOKEN "op://Personal/GitHub/token"
    secret_from_1password OPENAI_API_KEY "op://Personal/OpenAI/api-key"
fi
```

### Best Practices

- Use separate vaults for work/personal
- Use shared vaults for team secrets
- Keep API keys in "API Credential" items
- Use meaningful names and tags

## Method 4: macOS Keychain

### Pros
- ✅ Built into macOS
- ✅ Secure enclave on Apple Silicon
- ✅ GUI available
- ✅ No additional software

### Cons
- ❌ macOS only
- ❌ Not easily portable

### Setup

No setup required - Keychain is built into macOS.

### Usage

```bash
# Add a secret to Keychain
keychain_add github_token "ghp_xxxxxxxxxxxx"

# Load secret into environment variable
secret_from_keychain GITHUB_TOKEN github_token

# View in Keychain Access app
open -a "Keychain Access"

# Remove a secret
security delete-generic-password -s github_token
```

### Automation in .zshrc

Add to `~/.config/zsh/local.zsh`:

```bash
# Auto-load secrets from Keychain (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
    secret_from_keychain GITHUB_TOKEN github_token
    secret_from_keychain OPENAI_API_KEY openai_api_key
fi
```

### GUI Management

```bash
# Open Keychain Access
open -a "Keychain Access"

# Find your secrets under "login" keychain
# Search for the service name you used
```

## Method 5: Linux Secret Service

### Pros
- ✅ Native Linux integration
- ✅ Works with GNOME Keyring / KWallet
- ✅ D-Bus based
- ✅ GUI available

### Cons
- ❌ Requires GUI session
- ❌ Not available on headless servers
- ❌ Linux only

### Setup

```bash
# Ubuntu/Debian
sudo apt install libsecret-1-0 libsecret-tools

# Fedora
sudo dnf install libsecret

# Arch
sudo pacman -S libsecret
```

### Usage

```bash
# Add a secret
keyring_add github_token "ghp_xxxxxxxxxxxx"

# Load secret into environment variable
secret_from_keyring GITHUB_TOKEN github_token

# List secrets
secret-tool search --all service github_token

# Remove a secret
secret-tool clear service github_token
```

### Automation in .zshrc

Add to `~/.config/zsh/local.zsh`:

```bash
# Auto-load secrets from Secret Service (Linux GUI)
if [[ "$OSTYPE" == linux* ]] && command -v secret-tool &> /dev/null; then
    secret_from_keyring GITHUB_TOKEN github_token
    secret_from_keyring OPENAI_API_KEY openai_api_key
fi
```

## Best Practices

### 1. Never Commit Secrets

✅ **Do:**
```bash
# Use secrets management
secret_add API_KEY "xxx"

# Or use environment variables
export API_KEY=$(secret-tool lookup service api_key)
```

❌ **Don't:**
```bash
# Hard-code in tracked files
export API_KEY="actual-secret-here"
```

### 2. Use Different Secrets for Different Environments

```bash
# Development
secret_add DEV_DB_PASSWORD "dev-password"

# Production (use more secure method)
secret_from_1password PROD_DB_PASSWORD "op://Production/Database/password"
```

### 3. Rotate Secrets Regularly

```bash
# Update a secret
secret_remove OLD_API_KEY
secret_add NEW_API_KEY "new-value"

# Or with 1Password
# Update in 1Password, reload shell
```

### 4. Use Least Privilege

- Create separate API keys for different purposes
- Use read-only keys when possible
- Set expiration dates on temporary keys

### 5. Backup Your Secrets Securely

```bash
# Plain file method
# Backup the encrypted directory
tar -czf secrets-backup.tar.gz ~/.secrets/
gpg -c secrets-backup.tar.gz
rm secrets-backup.tar.gz

# 1Password method
# Secrets are automatically backed up in cloud

# pass method
pass git push
```

## Migration Guide

### From Plain File to 1Password

```bash
# 1. List current secrets
secret_list

# 2. Add each to 1Password manually or with op CLI
op item create --category "API Credential" \
  --title "GitHub Token" \
  password="$(grep GITHUB_TOKEN ~/.secrets/env | cut -d'"' -f2)"

# 3. Update ~/.config/zsh/local.zsh
# Remove: source ~/.secrets/env
# Add: secret_from_1password GITHUB_TOKEN "op://Personal/GitHub Token/password"

# 4. Test
source ~/.zshrc
echo $GITHUB_TOKEN

# 5. Delete plain file (after confirming it works)
rm ~/.secrets/env
```

### From Keychain to pass

```bash
# 1. Extract from Keychain
TOKEN=$(security find-generic-password -s github_token -w)

# 2. Add to pass
echo "$TOKEN" | pass insert -e github/token

# 3. Update ~/.config/zsh/local.zsh
# Replace: secret_from_keychain GITHUB_TOKEN github_token
# With: secret_from_pass GITHUB_TOKEN github/token

# 4. Test
source ~/.zshrc
```

## Common Scenarios

### Scenario 1: Multiple GitHub Accounts

```bash
# Store both tokens
secret_add GITHUB_TOKEN_WORK "ghp_work_token"
secret_add GITHUB_TOKEN_PERSONAL "ghp_personal_token"

# Create functions to switch
github_work() {
    export GITHUB_TOKEN="$GITHUB_TOKEN_WORK"
    git config --global user.email "you@work.com"
}

github_personal() {
    export GITHUB_TOKEN="$GITHUB_TOKEN_PERSONAL"
    git config --global user.email "you@personal.com"
}
```

### Scenario 2: Team Shared Secrets

Use 1Password with shared vaults:

```bash
# Team member adds to shared vault in 1Password
# Each team member loads it:
secret_from_1password TEAM_API_KEY "op://Team/API/key"
```

### Scenario 3: Temporary API Keys

```bash
# Add with comment
secret_add TEMP_API_KEY "xxx"  # Expires 2024-12-31

# Set reminder to remove
echo "secret_remove TEMP_API_KEY" | at 2024-12-31
```

## Troubleshooting

### Secrets not loading

```bash
# Check if secrets.zsh is loaded
typeset -f secret_add

# Check file permissions
ls -la ~/.secrets/

# Reload configuration
source ~/.zshrc
```

### Permission denied errors

```bash
# Fix directory permissions
chmod 700 ~/.secrets
chmod 600 ~/.secrets/env
```

### 1Password CLI not authenticated

```bash
# Sign in
op signin

# Or sign in to specific account
op signin --account your-account.1password.com
```

## Security Checklist

- [ ] Never commit secrets to git
- [ ] Use strong, unique passwords
- [ ] Enable 2FA where possible
- [ ] Rotate secrets regularly
- [ ] Use read-only keys when possible
- [ ] Set expiration on temporary keys
- [ ] Backup secrets securely
- [ ] Use different secrets for dev/prod
- [ ] Audit secret access regularly
- [ ] Use most secure method available

## Getting Help

```bash
# Show help for all methods
secret_help

# List available functions
typeset -f | grep secret

# Check specific method
secret_from_1password --help
```

## Resources

- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [pass - the standard Unix password manager](https://www.passwordstore.org/)
- [GPG Documentation](https://gnupg.org/documentation/)
- [macOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [freedesktop.org Secret Service API](https://specifications.freedesktop.org/secret-service/)

