# GitHub Authentication Setup

## Quick SSH Setup (Recommended)

```bash
# 1. Add SSH key to agent (enter your passphrase when prompted)
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 2. Copy your public key
cat ~/.ssh/id_ed25519.pub | pbcopy

# 3. Add to GitHub: https://github.com/settings/ssh/new

# 4. Switch repo to SSH
cd ~/.dotfiles
git remote set-url origin git@github.com:markbsigler/.dotfiles.git

# 5. Test and push
ssh -T git@github.com
git push origin main
```

Your SSH public key:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgP8TXNCu7KYdqPwJX/WewMin3ysrPmwiudeTF8K1qU
```

## Alternative: Personal Access Token

The shared Git configuration uses GitHub CLI as its HTTPS credential helper.
Authenticate through its interactive flow; do not put a token in command arguments.
Prefer fine-grained repository access with an expiration when a PAT is required.

```bash
gh auth login --hostname github.com --git-protocol https
gh auth status
```

Use `~/.gitconfig.local` for an alternative credential helper. Do not overwrite
the shared symlinked Git configuration with machine-specific settings.

## Testing

```bash
# Test SSH
ssh -T git@github.com

# Test credential helper
git config --get credential.helper
```

---
Created: 2025-11-03
