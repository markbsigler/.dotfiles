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
cd ~/.dotfiles && make install
```

Forking for personal use is recommended. With GitHub CLI:

```bash
gh repo fork markbsigler/.dotfiles --clone --default-branch-only ~/.dotfiles
cd ~/.dotfiles && make install
```

Preview changes:

```bash
make install-dry
```

## 📋 System Support

- macOS (Intel & Apple Silicon)
- Ubuntu/Debian, Fedora/CentOS, Arch/Manjaro
- Architectures: amd64, arm64

## 🖼️ Fonts

Use a Nerd Font for icons. Default: Agave Nerd Font.

- `make fonts` on macOS/Linux
- Then set your terminal font to “Agave Nerd Font”
- On Windows/WSL, install manually from the Nerd Fonts site

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
make install        # Full installation
make install-dry    # Preview without changes
make update         # Update existing symlinks only
make packages       # Install packages only
make doctor         # Health check
make test           # Run tests
make lint           # Lint shell scripts
make plugins        # Update Zsh plugins
make fonts          # Install Agave Nerd Font
```

## 🔍 Environment detection

```bash
show_env            # Display detected OS/arch
```

Key variables: `DOTFILES_OS`, `DOTFILES_ARCH`, `DOTFILES_DISTRO`.

## 🎯 Customization

- `~/.config/zsh/local.zsh` for machine-specific settings
- `local/local.zsh` for repo-local overrides
- Add functions to `config/zsh/functions.zsh`

Example:

```bash
export WORK_EMAIL="you@company.com"
alias work-ssh="ssh user@work-server"
```

## 🧪 Test & Health

```bash
make test
make doctor
```

## 🚨 Troubleshooting

- Slow startup: `zsh -x -c exit 2>&1 | ts -i "%.s"`
- Missing tools: `make doctor` then `./scripts/install-packages.sh`
- PATH issues: `echo $PATH | tr ':' '\n' | nl` then `clean_path`

## 📝 License

MIT – see `LICENSE`.

## 🤝 Contributing

PRs welcome. Please test across platforms (`make test`).

---

Made with ❤️ for developers on multiple platforms.


