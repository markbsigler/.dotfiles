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

```bash
# 1. Create token: https://github.com/settings/tokens/new
#    Scopes: repo
#    Note: "dotfiles push"

# 2. Store securely
secret_add GITHUB_TOKEN "ghp_your_token_here"

# 3. Configure credential helper
git config --global credential.helper osxkeychain

# 4. Push (use token as password)
git push origin main
```

## Testing

```bash
# Test SSH
ssh -T git@github.com

# Test credential helper
git config --get credential.helper
```

---
Created: 2025-11-03
