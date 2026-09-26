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

`make fonts` uses Homebrew on macOS when available. Its manual macOS/Linux
fallback requires curl and unzip (plus fontconfig on Linux), uses a private
temporary directory, and fails if download, extraction or font-cache refresh
fails. The pinned archive is downloaded over HTTPS without an independent
checksum check. The separate package/bootstrap helpers still contain legacy
download paths and host changes; they are not covered by this target's safeguards.

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
| Languages | node, python@3.11, go, rust, ruby, temurin17 | nodejs, npm, python3, python3-pip, golang-go, rustup-init/rust, ruby, openjdk-17-jdk | nodejs, npm, python3, python3-pip, golang, rustup, ruby, java-17-openjdk-devel | nodejs, npm, python, python-pip, go, rustup, ruby, jdk17-openjdk |
| Optional | docker, tmux, screen | docker.io, tmux, screen | moby-engine/docker, tmux, screen | docker, tmux, screen |

Notes:
- Ubuntu/Debian: `bat` may be `batcat`; `fd` may be `fdfind` (a symlink is created to `fd`).
- Fedora: `fd-find` is the package name for `fd`.
- Package selections target Java 17. Availability depends on the OS and package repositories.

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

Run from the checkout root, or use `make -C /path/to/.dotfiles TARGET`.
Bare `make` runs `help`. All targets are phony; namesake files do not suppress them.

| Target | Behavior And Prerequisites |
| --- | --- |
| `help` | Show all targets; no installation. |
| `list` | Print every explicit target name. |
| `deps` | Describe tools and platform package manager; does not install them. |
| `status` | Check managed links and Git state; return nonzero for invalid links or Git errors. Dirty working trees are reported, not treated as errors. |
| `doctor` | Read-only tool, login-shell and link checks; required failures return nonzero. Missing optional tools are informational. |
| `install-dry` | Zero-write installer preview; does not execute package installs. |
| `install` | Full installation, including package/bootstrap downloads, links, plugin setup and possible login-shell changes. |
| `force` | Full installation with replacement backups disabled; existing files can be lost. |
| `update` | Relink existing symlinks only; does not pull Git, upgrade packages or provision missing links. |
| `packages` | Run the package/bootstrap script, including version managers, fonts on some platforms and Vim-Plug; no dotfile linking. Requires network and platform package-manager privileges. |
| `backup` | Create a timestamped private backup of configured HOME paths. |
| `restore` | Require `BACKUP=/absolute/path`; preview by default, restore only with `CONFIRM=yes`. |
| `clean` | List log candidates, without deleting logs or backups. |
| `plugins` | Update existing Git checkouts under `~/.local/share/zsh/plugins`; fail on pull errors or a missing plugin directory. Empty directories are a no-op. |
| `fonts` | Install Agave Nerd Font; see font prerequisites above. |
| `docs` | Atomically replace ignored `SYSTEM_INFO.md` with machine/XDG metadata and configuration paths. Refuse a symlink or directory output. Not a README generator. |
| `dev-setup` | Install Make, Bash, Zsh, Vim, Git, jq, ripgrep, ShellCheck and pre-commit through Brew/APT/DNF/Pacman. Linux requires sudo; Arch performs a system upgrade. No global npm installation. |
| `git-hooks` | Install pre-commit hooks and run all hooks; may install pre-commit via pip and download hook environments. Hooks can modify files; failures return nonzero. |
| `test`, `test-all` | Same complete offline suite: structure, syntax, isolated Vim, lint, recovery/security/Make fixtures and OS detection. |
| `test-quick` | Required files and all shell syntax; no configuration execution. |
| `test-integration` | Isolated recovery, security, Make recipes and OS-detection tests. |
| `test-zsh` | Syntax-check Zsh files, including hidden startup files. |
| `test-vim` | Load vimrc in a temporary HOME with Vim-Plug stubbed and plugin execution disabled. |
| `test-scripts` | Syntax-check shell scripts using their declared interpreters. |
| `lint` | ShellCheck at warning severity for supported shells, excluding Zsh. |
| `security` | Redacted heuristic working-tree scan; requires Git, jq and ripgrep. |
| `perf` | Report that an isolated startup benchmark is unavailable; this is a skip, not a timing result. |
| `mcp-atlassian-setup` | Interactive macOS Keychain credential setup; modifies Keychain. |
| `mcp-atlassian-migrate` | Sanitize a private regular MCPM file; requires jq. Select it with `MCPM_SERVERS_FILE=/absolute/path make mcp-atlassian-migrate`; the managed symlink is deliberately refused. |
| `mcp-atlassian-test` | Start `mcpm run atlassian`; requires MCPM, uvx, the installed launcher, configured Keychain credentials and network. A long-running authenticated server, not an offline unit test. |

Targets that install, restore, update, migrate or launch servers are explicit live
operations. Do not run every target as a smoke-test loop on your real HOME.

**Quality Assurance:**

- `make test` and `make test-all` use the same failure-propagating runner.
- Tests require Make, Bash, Zsh, Vim, Git, jq, ripgrep and ShellCheck. Missing tools fail.
- Recovery and security regressions use temporary homes and dummy credentials.
- ShellCheck excludes Zsh; Zsh syntax is validated separately.
- CI defines macOS Bash 3.2/5 and Linux Bash 5 jobs. Local macOS checks do not
  establish Linux or authenticated MCP compatibility.
- The secret scanner does not inspect Git history, ignored untracked files or
  live permissions; see [docs/SECRETS.md](docs/SECRETS.md) for its limits.

The Make-target audit checks command routing and exit statuses using disposable
homes, paths containing spaces, and stubbed package managers/network/credential
commands. Direct recipe tests cover health failures, atomic documentation output,
font cleanup and development dependencies. Package installation, hook downloads,
authenticated MCP operation and real Linux provisioning were not exercised.
These tests establish target contracts, not end-to-end operability of every
external service or legacy bootstrap script.

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


