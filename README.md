# .dotfiles

A cross-platform, batteries-included dotfiles setup for macOS and Linux. It features smart OS/arch detection, modern Zsh, developer tooling, and automated installation via Make.

## ✨ Features

- **Cross-platform**: macOS, Ubuntu/Debian, Fedora, Arch
- **Modern shell**: Zsh with completions, syntax highlighting, autosuggestions, fzf-tab
- **Universal package funcs** and intelligent PATH management
- **Developer-ready**: languages, version managers, and modern CLI tools
- **Easy maintenance**: Make targets for install, update, doctor, test, and fonts

## 🚀 Quick Start

```bash
git clone https://github.com/markbsigler/.dotfiles ~/.dotfiles
cd ~/.dotfiles
make install-dry
```

Forking for personal use is recommended. With GitHub CLI:

```bash
gh repo fork markbsigler/.dotfiles --clone --default-branch-only ~/.dotfiles
cd ~/.dotfiles
make install-dry
```

After reviewing the preview, run the full installation explicitly:

```bash
make install
```

Full installation creates links and private local settings, installs packages and
plugins, and may change the login shell. `bash install.sh --skip-packages` skips
packages only, not all other side effects. `make update` relinks existing symlinks
only: it does not provision missing Git support links or install anything.
Edits to already-linked configuration affect subsequent shells and tool launches
without reinstalling. Shell startup does not download missing Zsh plugins.

## 📋 System Support

- macOS (Intel & Apple Silicon)
- Ubuntu/Debian, Fedora/CentOS, Arch/Manjaro
- Architectures: amd64, arm64

## 🖼️ Fonts

Use a Nerd Font for icons. Default: Agave Nerd Font.

- `make fonts` on macOS/Linux
- Then set your terminal font to “Agave Nerd Font”
- On Windows/WSL, install manually from the Nerd Fonts site

The legacy font download fallback uses fixed `/tmp` paths and lacks artifact
checksum verification. Package/bootstrap helpers also perform live downloads and
host changes. These paths have not received the recovery suite's safety guarantees;
review them separately before running them on a sensitive or shared machine.

## 🛠️ What Gets Installed

- Core: git, zsh, vim/neovim, curl, wget
- Modern CLI: bat, eza, fd, fzf, ripgrep, jq, tree, htop, ncdu, tldr
- Languages/VMs: Node.js, Python, Go, Rust, Ruby, Java; nvm, pyenv, rbenv, rustup
- Zsh plugins: syntax-highlighting, autosuggestions, fzf-tab

## 📦 Packages by OS

| Category | macOS (Homebrew) | Ubuntu/Debian (APT) | Fedora/CentOS (DNF/YUM) | Arch/Manjaro (Pacman) |
|---|---|---|---|---|
| Core | git, zsh, vim, neovim, curl, wget | git, zsh, vim, neovim, curl, wget | git, zsh, vim, neovim, curl, wget | git, zsh, vim, neovim, curl, wget |
| Modern CLI | bat, eza, fd, fzf, ripgrep, jq, tree, htop, ncdu, tldr | bat, eza, fd/fdfind, fzf, ripgrep, jq, tree, htop, ncdu, tldr | bat, eza, fd-find, fzf, ripgrep, jq, tree, htop, ncdu, tldr | bat, eza, fd, fzf, ripgrep, jq, tree, htop, ncdu, tldr |
| Dev Tools | shellcheck, gh, httpie | shellcheck, gh, httpie | shellcheck, gh, httpie | shellcheck, github-cli (gh), httpie |
| Languages | node, python@3, go, rust, ruby, openjdk | nodejs, npm, python3, python3-pip, golang-go, rustup-init/rust, ruby, openjdk-11-jdk | nodejs, npm, python3, python3-pip, golang, rustup, ruby, java-11-openjdk-devel | nodejs, npm, python, python-pip, go, rustup, ruby, jdk11-openjdk |
| Optional | docker, tmux, screen | docker.io, tmux, screen | moby-engine/docker, tmux, screen | docker, tmux, screen |

Notes:
- Ubuntu/Debian: `bat` may be `batcat`; `fd` may be `fdfind` (a symlink is created to `fd`).
- Fedora: `fd-find` is the package name for `fd`.
- Java versions can vary; scripts default to 11 where applicable.

### Install verification (quick checks)

macOS (Homebrew):

```bash
brew --version
git --version && zsh --version && nvim --version
bat --version && eza --version && fd --version && rg --version && fzf --version && jq --version
node -v && python3 --version && go version && rustup --version && ruby --version && java -version
```

Ubuntu/Debian (APT):

```bash
apt --version
git --version && zsh --version && nvim --version
$(command -v bat >/dev/null 2>&1 && echo bat --version || echo batcat --version)
$(command -v fd >/dev/null 2>&1 && echo fd --version || echo fdfind --version)
rg --version && fzf --version && jq --version
node -v && python3 --version && go version && rustup --version && ruby --version && java -version
```

Fedora/CentOS (DNF/YUM):

```bash
dnf --version || yum --version
git --version && zsh --version && nvim --version
bat --version && eza --version && fd --version 2>/dev/null || fd-find --version
rg --version && fzf --version && jq --version
node -v && python3 --version && go version && rustup --version && ruby --version && java -version
```

Arch/Manjaro (Pacman):

```bash
pacman -V
git --version && zsh --version && nvim --version
bat --version && eza --version && fd --version && rg --version && fzf --version && jq --version
node -v && python --version && go version && rustup --version && ruby --version && java -version
```

### Upstream documentation

- Package managers: [Homebrew](https://docs.brew.sh/), [APT](https://wiki.debian.org/Apt), [DNF](https://dnf.readthedocs.io/), [Pacman](https://man.archlinux.org/list/pacman)
- Editors: [Neovim](https://neovim.io/doc/), [Vim](https://www.vim.org/docs.php)
- Modern CLI: [bat](https://github.com/sharkdp/bat), [eza](https://github.com/eza-community/eza), [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep), [fzf](https://github.com/junegunn/fzf), [jq](https://stedolan.github.io/jq/), [tldr](https://tldr.sh/)
- Dev tools: [GitHub CLI (gh)](https://cli.github.com/), [ShellCheck](https://www.shellcheck.net/), [HTTPie](https://httpie.io/)
- Languages / VMs: [Node.js](https://nodejs.org/), [Python](https://www.python.org/doc/), [Go](https://go.dev/doc/), [Rust/rustup](https://rust-lang.github.io/rustup/), [Ruby](https://www.ruby-lang.org/en/documentation/), [OpenJDK](https://openjdk.org/)

## ⚙️ Layout

```text
.dotfiles/
├── config/
│   ├── zsh/
│   ├── git/
│   ├── vim/
│   └── nvim/
├── scripts/
└── Makefile
```

## 🔧 Commands

```bash
make install        # Full installation (creates backups)
make install-dry    # Preview without changes
make update         # Update existing symlinks only
make packages       # Install packages only
make doctor         # Health check and diagnostics
make test           # Run comprehensive test suite ✅
make lint           # Lint shell scripts with shellcheck ✅
make security       # Redacted working-tree secret scan
make plugins        # Update Zsh plugins
make fonts          # Install Agave Nerd Font
```

**Quality Assurance:**

- `make test` and `make test-all` use the same failure-propagating runner.
- Tests require Bash, Zsh, Vim, Git, jq, ripgrep and ShellCheck. Missing tools fail.
- Recovery and security regressions use temporary homes and dummy credentials.
- ShellCheck excludes Zsh; Zsh syntax is validated separately.
- CI defines macOS Bash 3.2/5 and Linux Bash 5 jobs. Local macOS checks do not
  establish Linux or authenticated MCP compatibility.
- The secret scanner does not inspect Git history, ignored untracked files or
  live permissions; see [docs/SECRETS.md](docs/SECRETS.md) for its limits.

### Backup And Restore

```bash
bash scripts/backup-dotfiles.sh --dry-run
make backup
make restore BACKUP=/absolute/path/to/completed-backup
make restore BACKUP=/absolute/path/to/completed-backup CONFIRM=yes
```

Restore previews by default and requires an explicit completed backup. Confirmed
restore saves displaced files before replacement. Backups retain home-relative
paths, hidden files and symlinks. They do not dereference links, capture the
checkout contents, or include credentials. Keep a separate repository backup.
`make clean` lists log candidates; it does not delete backups or logs.

## 🔍 Environment Detection

```bash
show_env            # Display detected OS/arch
```

Key variables: `DOTFILES_OS`, `DOTFILES_ARCH`, `DOTFILES_DISTRO`.

## 🔒 Secrets Management

Prefer a credential provider. The JSON store is plaintext with restricted file
permissions, not encrypted storage. No method automatically exports all secrets.

| Method | Security | Ease | Platform | Best For |
|--------|----------|------|----------|----------|
| Plaintext JSON (jq required) | ⭐ | ⭐⭐⭐⭐ | macOS/Linux | Local development |
| Password Store (pass) | ⭐⭐⭐⭐ | ⭐⭐⭐ | macOS/Linux | Power Users |
| 1Password CLI | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | All | Enterprise |
| macOS Keychain | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | macOS | Mac Users |
| Linux Keyring | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Linux GUI | Linux Desktop |

**Quick Start:**
```bash
secret_add GITHUB_TOKEN  # Enter value at the protected prompt
secret_list             # List names only
secret_load GITHUB_TOKEN # Explicitly export for a command
unset GITHUB_TOKEN      # Remove the export afterward
secret_help             # Show all methods
```

**Advanced:**
```bash
# 1Password CLI
secret_from_1password GITHUB_TOKEN "op://Personal/GitHub/token"

# macOS Keychain
keychain_add github_token # The OS utility prompts for the value
secret_from_keychain GITHUB_TOKEN github_token

# Password Store (pass)
secret_from_pass GITHUB_TOKEN github/token
```

See [docs/SECRETS.md](docs/SECRETS.md) for comprehensive guide with all 5 methods.

## 📁 XDG Base Directory Compliance

Follows the XDG Base Directory specification for clean configuration management:

- **Config**: `~/.config/zsh/` - All ZSH configuration files
- **Data**: `~/.local/share/` - Plugins, completions, persistent data
- **Cache**: `~/.cache/zsh/` - Completion cache, temporary files
- **State**: `~/.local/state/` - History, logs, state files

Managed via `~/.zshenv` (loaded first for all shell invocations) and `~/.zprofile` (login shells).

## 🎯 Customization

- `local/local.zsh` in this checkout for ignored machine-specific settings,
  sourced once after shared configuration
- `~/.gitconfig.local` for private Git overrides, including optional credential
  manager or tracing settings
- Add functions to `config/zsh/functions.zsh`

The tracked `config/zsh/local.zsh` placeholder is no longer sourced. Move any
personal settings from that old location manually after reviewing them. Do not
store token literals in either file; use explicit credential-loading functions.

Example:

```bash
export WORK_EMAIL="you@company.com"
alias work-ssh="ssh user@work-server"
```

## 🧪 Test & Health

```bash
make test     # Run comprehensive test suite
make doctor   # System health check
make lint     # ShellCheck for supported shell scripts
```

**Test Coverage:**
- ZSH configuration syntax
- Shell script validation
- Integration tests
- Vim configuration

`make perf` reports that an isolated benchmark is not yet available. The optional
profiling scripts below start real shells and can execute private startup code;
they are not part of the offline test suite.

## 🚨 Troubleshooting

Quick diagnostics:
```bash
make doctor                           # Health check
make test                             # Run all tests
scripts/profile-startup.sh            # Profile shell startup time
```

Common issues:
- **Slow startup**: `scripts/profile-startup.sh --detailed`
- **Missing tools**: `make doctor` then `scripts/install-packages.sh`
- **PATH issues**: `echo $PATH | tr ':' '\n' | nl` then `clean_path`

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for comprehensive guide.

## 📚 Documentation

Complete documentation for customization, troubleshooting, and advanced features:

- **[docs/README.md](docs/README.md)** - Documentation hub and quick reference
- **[docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md)** - How to customize your dotfiles
- **[docs/SECRETS.md](docs/SECRETS.md)** - Secure secrets management (5 methods)
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[ROADMAP.md](ROADMAP.md)** - Future enhancements and planned improvements
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[GITHUB_AUTH_SETUP.md](GITHUB_AUTH_SETUP.md)** - GitHub authentication setup

**Configuration Guides:**
- **[config/tmux/README.md](config/tmux/README.md)** - tmux setup and key bindings
- **[config/ssh/README.md](config/ssh/README.md)** - SSH configuration guide
- **[config/zsh/README.md](config/zsh/README.md)** - Zsh-specific documentation

**Quick Links:**
- Customize: `~/.dotfiles/local/local.zsh` for machine-specific settings
- Functions: See `config/zsh/functions.zsh` for all available functions
- Secrets: Run `secret_help` for secrets management options
- Security: Run `make security` or `./scripts/security-audit.sh`
- Pre-commit: Run `./scripts/setup-pre-commit.sh` to install hooks

## 📝 License

MIT – see `LICENSE`.

## 🤝 Contributing

PRs welcome. Please test across platforms (`make test`).

---

Made with ❤️ for developers on multiple platforms.


