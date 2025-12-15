# AGENTS.md

This file contains machine‑readable instructions that assist automated assistants in working with the **.dotfiles** repository.

## 1. Project Overview

The project is a cross‑platform collection of dotfiles, configuration scripts, and installation utilities for macOS and Linux. Key components:

- **config/** – Platform‑specific configuration (zsh, git, vim, nvim, tmux).
- **scripts/** – Bash utilities (`bootstrap.sh`, `install-packages.sh`, `update-all.sh`, ...).
- **Makefile** – Declarative build system for installing, updating, linting, and testing.
- **docs/** – Documentation for customization and troubleshooting.

The repository is designed to be safe to install on a fresh system and to be maintained via standard `make` goals.

## 2. Setup Commands

| Command | Purpose |
|--------|---------|
| `make install` | Full installation: backs up existing files, installs packages, sets up symlinks, and configures the shell environment. |
| `make install-dry` | Preview changes without writing anything. |
| `make update` | Refresh just the symlinks to current repo state. |
| `make packages` | Installs the necessary packages for the target platform (uses Homebrew, apt, dnf, pacman). |
| `make cleanup` *(if available)* | Removes temporary files created during install. |

If you fork the repo under a different GitHub user, replace references to `markbsigler/.dotfiles` with your own when cloning:
```bash
git clone https://github.com/<your-username>/.dotfiles ~/.dotfiles
cd ~/.dotfiles && make install
```

## 3. Build & Test

The repo doesn’t compile code, but it is verified with a set of automated checks:

- `make doctor` – Health‑check of the environment and installed tools.
- `make lint` – Runs `shellcheck` against all shells scripts.
- `make test` – Executes the integrated test suite (`scripts/test-dotfiles.sh`).
- `make security` – Runs a security audit that looks for hard‑coded secrets and insecure permissions.

CI is implemented via GitHub Actions (see `.github/workflows/`). The pipeline mirrors the `make` targets above.

## 4. Code style & conventions

The repository follows:

- Bash scripts following **ShellCheck** recommendation style.
- Makefiles written in POSIX‑compliant syntax.
- No hard‑coded file paths; all paths are relative or derived from environment variables (`HOME`, `DOTFILES`.
- Functions and variables are prefixed with `__` to avoid clashes.

## 5. Dependencies

All dependencies are declared in `Makefile` per-platform via `DOTFILES_PACKAGES`. The installer pulls them with:

- **macOS**: Homebrew.
- **Debian/Ubuntu**: `apt`.
- **Fedora/CentOS**: `dnf`.
- **Arch/Manjaro**: `pacman`.

The install script also creates a `~/.config/zsh/autoload` directory for `zsh` autoloaded functions.

## 6. Compatibility

The dotfiles are actively supported on:

- macOS 13+ (Intel & Apple Silicon)
- Ubuntu 22.04 LTS / 20.04 LTS
- Fedora 38
- Arch / Manjaro (rolling releases)

If you’re on a distro not listed, the install‑time `make doctor` will flag missing utilities, and you may need to add them manually.

## 7. Troubleshooting & Resources

- `scripts/security-audit.sh` – Quick audit for secrets or permission issues.
- `scripts/backup-dotfiles.sh` – Create a backup of all dotfiles before overwrite.
- The `docs/` folder contains deeper guides (CUSTOMIZATION.md, TROUBLESHOOTING.md).
- Issue tracker on GitHub for bugs or feature requests.

---

**Author**: Mark Sigler (github.com/markbsigler)
**License**: MIT
