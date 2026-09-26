# AGENTS.md

Cross-platform macOS/Linux dotfiles. The installer symlinks this checkout into
HOME; edits to linked files affect subsequent real shells and tool launches.
Preserve existing user edits and never treat the checkout as a sandbox.

## Layout And Contracts

- `install.sh` owns symlinks, full-install setup and validation; its root is
  resolved from the script location. `scripts/lib/backup.sh` owns backup format.
- `config/zsh/.zshrc` sources fragments in an explicit order. Keep
  `os-detection.zsh` first. `local/local.zsh` in the checkout is sourced once after
  shared config; it is ignored. The tracked `config/zsh/local.zsh` is inactive.
- `.zshenv` is read-only; directory creation belongs in interactive setup.
  Missing plugins are skipped, never downloaded during startup.
- Git uses both `~/.gitconfig` and `~/.config/git` links. Optional machine-specific
  Git overrides belong in `~/.gitconfig.local`, not the shared target.
- Docs live in `docs/`, with command summaries in `README.md`.

## Commands And Validation

| Command | Contract |
| --- | --- |
| `make install-dry` | Zero-write installer preview. |
| `make install` | Full setup; packages, plugins, links and possible login-shell changes. Requires explicit approval for a live machine. |
| `make update` | Relink existing symlinks only; no missing-link provisioning or ancillary setup. |
| `bash install.sh --skip-packages` | Full installation except packages; not a no-side-effect mode. |
| `bash install.sh --test` | Run the test suite without installing. |
| `make test` / `make test-all` | Same isolated runner: syntax, Vim, lint, safety/security fixtures and OS detection. |
| `make test-quick` | Required files and shell syntax only. |
| `make test-integration` | Temporary-HOME recovery/security cases and OS detection. |
| `make lint` | ShellCheck warning severity; excludes Zsh. Missing tools fail. |
| `make security` | Redacted heuristic scan of working-tree Git inventory; no history or live-permission audit. |
| `make backup` | Path-preserving backup; links are not dereferenced. |
| `make restore BACKUP=/path` | Preview explicit completed backup; add `CONFIRM=yes` to restore. |
| `make doctor` | Diagnostics without shell-account changes. |
| `make clean` | Lists log candidates; does not delete backups or logs. |
| `make perf` | Reports unavailable isolated benchmark; no live startup test. |

Tests require Bash, Zsh, Vim, Git, jq, ripgrep and ShellCheck. Run the complete
runner under `/bin/bash` and Bash 5 on macOS for portable changes. CI defines
macOS Bash 3.2/5 and Ubuntu Bash 5 jobs in `.github/workflows/validate.yml`.
Do not claim Linux coverage solely from local macOS runs. Pre-commit hooks are
checkout-relative; installation is a separate explicit action.

## Security Boundaries

- Never run live installers, updates, profiling scripts, credential migration,
  Keychain operations or authenticated MCP servers as a routine test. Fixture
  suites use temporary homes and dummy credentials, not the real shell profile.
- Backups retain home-relative paths and links. They do not protect linked
  checkout contents or secret stores. Restore requires complete validated
  metadata, an explicit path and confirmation; displaced files are backed up.
- `secret_add KEY` accepts a protected prompt or literal stdin, not a value
  argument. JSON storage is `~/.secrets/env.json`, mode 600 in a mode-700 directory;
  values load explicitly with `secret_load KEY`. Legacy executable `env` files
  are never sourced. Do not weaken permissions or expose values to debug failures.
- Keep `config/mcpm/servers.json` tokenless. Atlassian uses a pinned, non-login
  launcher with Keychain PATs and read-only/two-tool defaults. Migration applies
  only to a private regular file under HOME; it refuses the installed symlink.
  Migration backups can contain old credentials and need protected retention.
- Aha uses the remote bridge configured in the template; the old Aha Keychain
  launcher is not active. Filesystem scope is `~/Code`, not a sandbox for the
  other MCP servers. Exact top-level versions do not lock transitive dependencies.
- The scanner is heuristic and excludes ignored untracked files and symlink
  targets. A passing scan does not replace secret rotation or a history audit.

Use Conventional Commits when a commit is requested; do not stage, commit, push
or alter host security policy without specific authorization.
