# AGENTS.md

Cross-platform (macOS/Linux) dotfiles for `markbsigler/.dotfiles`. Live environment is built by symlinking `config/` and scripts into `$HOME` via `./install.sh`.

## Layout & ownership

- `install.sh` – the installer (run via `make install`). Owns the symlink map, backups, zsh setup, machine.info.
- `Makefile` – all developer commands; default target is `help`.
- `config/zsh/` – the shell config; `.zshrc` is the entrypoint and sources the rest in an explicit order. `os-detection.zsh` **must stay first** (it exports `DOTFILES_OS`/`DOTFILES_ARCH`/`DOTFILES_DISTRO` and defines `is_macos`/`is_linux`/`has_*`). Adds `local.zsh` last.
- `config/{git,vim,nvim,aider,tmux,ssh,mcpm}/` – per-tool config.
- `scripts/` – standalone utilities; `config/zsh/*.zsh` are sourced fragments, not scripts.
- `local/` – machine-specific (`local.zsh`, generated `machine.info`), both gitignored.
- `docs/` – CUSTOMIZATION.md, TROUBLESHOOTING.md, SECRETS.md (deep guides live here, not in AGENTS.md).

## Commands

| Command | Purpose |
|---|---|
| `make install` | Bash for the actual install; new symlinks need a re-run (`make install`). `--dry-run` previews. |
| `make install-dry` | `./install.sh --dry-run` – preview only, writes nothing. |
| `make update` | `./install.sh --update` – (re)link without new-config side effects. |
| `make status` | Show symlink health + git status of the repo. |
| `make doctor` | Health check. **Has side effects**: if the default shell isn't zsh it runs `chsh -s` (and appends to `/etc/shells` via sudo on Linux). |
| `make test` | zsh syntax + vimrc + `bash -n` + integration. Requires `zsh`, `vim`, `bash` installed. |
| `make test-all` / `make test-quick` / `make test-integration` | Wraps `scripts/test-dotfiles.sh` (`--quick` / `--integration`). `make test` does **not** run this script. |
| `make lint` | `shellcheck` on all `*.sh`; only warns (exit 0) if shellcheck is missing. |
| `make security` | `scripts/security-audit.sh` – secret/permission scan. |

Also: `packages`, `update` (script), `backup`, `restore`, `clean` (removes backups >30 days + logs), `fonts` (Agave Nerd Font), `plugins`, `docs` (regenerates gitignored `SYSTEM_INFO.md`), `perf`, `dev-setup`, `git-hooks`.

## Install/symlink model

`install.sh` creates these links (also validated by `make status` / `validate_installation`):

- `~/.config/zsh` → `config/zsh`; `~/.zshrc`, `~/.zshenv`, `~/.zprofile` → `config/zsh/{.zshrc,.zshenv,.zprofile}`
- `~/.gitconfig` → `config/git/gitconfig`
- `~/.vimrc` → `config/vim/vimrc`; `~/.config/nvim` → `config/nvim`
- `~/.config/mcpm/servers.json` → `config/mcpm/servers.json`
- `~/.local/bin/mcpm-atlassian-secure` → `scripts/mcpm-atlassian-secure.sh`

Edits to an already-linked file take effect immediately (symlinks). Adding a brand-new link requires editing `link_configs()` in `install.sh` and re-running `make install`.

Local machine config goes in `config/zsh/local.zsh` (sourced last). It's gitignored, but a placeholder copy is **already tracked** – git will show edits there as modifications, so don't commit personal config into it.

## Secrets & MCPM (security-sensitive)

- Never commit secrets. `scripts/security-audit.sh` + `.gitignore` guard this; `.secrets/` and `config/zsh/.secrets/` are ignored.
- `config/zsh/secrets.zsh` provides `secret_*` / `keychain_*` / `secret_from_*` (plain file `~/.secrets/env` 600, macOS Keychain, pass, 1Password). Docs: `docs/SECRETS.md`.
- `config/mcpm/servers.json` must stay **tokenless** – it's the managed template. Jira/Confluence/Aha tokens live in macOS Keychain, read via keychain-launcher scripts. Setup: `scripts/mcpm-atlassian-keychain-setup.sh` → `mcpm-atlassian-migrate.sh` → smoke test `mcpm run atlassian`.
- `install.sh` chmods `~/.config/mcpm/servers_cache.json` + `monitor.db` to 600 because MCPM resets them to 644.

## Repo quirks / gotchas

- **No CI**: `.github/workflows/` does not exist.
- Pre-commit hooks live in `.pre-commit-config.yaml` (shellcheck + `make test`/`make lint`); install with `scripts/setup-pre-commit.sh`. Note its local hooks `cd ~/.dotfiles`, so the repo must live there.
- `install.sh` help advertises `-t/--test`, but `parse_args()` doesn't implement it – it errors "Unknown option".
- Test suite sources `config/zsh/os-detection.zsh` and fails if it's absent; integration tests source the real `~/.zshrc` when installed, else the repo config via `ZDOTDIR`.
- New shell/script files must pass `bash -n`/`zsh -n` syntax checks and shellcheck (`make lint`).
- Commits use Conventional Commits (e.g. `feat(zsh):`, `fix(doctor):`, `chore(mcpm):`).