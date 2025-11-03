# SSH Configuration

Template and guidelines for SSH configuration.

## Quick Setup

1. **Copy template to SSH config:**
   ```bash
   mkdir -p ~/.ssh
   cp ~/.dotfiles/config/ssh/config.template ~/.ssh/config
   chmod 600 ~/.ssh/config
   ```

2. **Edit for your needs:**
   ```bash
   vim ~/.ssh/config
   ```

3. **Create SSH key if needed:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

4. **Add key to SSH agent:**
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

5. **Copy public key to server:**
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub user@hostname
   ```

## Features in Template

### Default Settings
- SSH agent integration
- macOS Keychain support
- Connection keep-alive
- Connection multiplexing for speed
- Compression enabled

### Pre-configured Hosts
- GitHub, GitLab, Bitbucket
- Work server examples
- Jump host / bastion setup
- Local network / homelab
- Cloud provider patterns

### Advanced Features
- Port forwarding examples
- SOCKS proxy setup
- X11 forwarding
- Wildcard patterns

## Common Use Cases

### Multiple GitHub Accounts

```ssh
# Personal GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal

# Work GitHub
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
```

Then clone with:
```bash
git clone git@github-work:company/repo.git
```

### Jump Host Access

```ssh
# Bastion server
Host bastion
    HostName bastion.company.com
    User myuser

# Internal server through bastion
Host internal
    HostName 192.168.1.100
    User myuser
    ProxyJump bastion
```

Connect with:
```bash
ssh internal  # Automatically routes through bastion
```

### Connection Multiplexing

Already enabled in template! Benefits:
- Faster subsequent connections
- Share single connection for multiple sessions
- `scp` and `rsync` use existing connections

View active connections:
```bash
ls -la ~/.ssh/sockets/
```

## Security Best Practices

1. **Use Ed25519 keys** (most secure, modern)
   ```bash
   ssh-keygen -t ed25519 -C "comment"
   ```

2. **Protect your config**
   ```bash
   chmod 600 ~/.ssh/config
   chmod 700 ~/.ssh
   ```

3. **Use strong passphrases** on private keys

4. **Be careful with ForwardAgent**
   - Only enable for trusted servers
   - Potential security risk if server is compromised

5. **Different keys for different purposes**
   - Personal vs. work
   - High-security vs. convenience

## Troubleshooting

### Connection Issues

Test SSH connection:
```bash
ssh -vvv user@hostname  # Verbose output
```

Test SSH config:
```bash
ssh -T git@github.com  # Test GitHub
```

### Permission Issues

Fix SSH directory permissions:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### macOS Keychain Issues

If keys aren't being saved to Keychain:
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## Useful Commands

```bash
# List loaded SSH keys
ssh-add -l

# Remove all keys from agent
ssh-add -D

# Add key with custom lifetime (1 hour)
ssh-add -t 3600 ~/.ssh/id_ed25519

# Kill specific multiplexed connection
ssh -O exit hostname

# Show SSH config for specific host
ssh -G hostname

# Copy file through jump host
scp -o 'ProxyJump bastion' file.txt user@internal:/path/
```

## See Also

- [GitHub SSH Setup](../../../GITHUB_AUTH_SETUP.md)
- [OpenSSH Config Documentation](https://man.openbsd.org/ssh_config)
- [SSH Key Types Comparison](https://security.stackexchange.com/questions/5096/rsa-vs-dsa-for-ssh-authentication-keys)

