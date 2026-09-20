# Secrets Management

Prefer an OS credential store or password manager for long-lived credentials.
The local JSON store is plaintext, not encryption. Exported credentials are
inherited by child processes; load only what a command needs and unset afterward.
Shell startup never loads stored values automatically.

## Local JSON Store

Requires Zsh and jq. Run these functions in an interactive shell after loading
the dotfiles configuration:

```zsh
secret_add GITHUB_TOKEN
secret_list
secret_load GITHUB_TOKEN
# Run the command that needs the token, then:
unset GITHUB_TOKEN
secret_remove GITHUB_TOKEN
```

`secret_add KEY` prompts silently on a terminal or reads literal stdin. It does
not accept a value argument. Avoid putting values into command lines or shell
history. Quotes, backslashes, shell syntax and trailing newlines in stdin are
stored as data, not executed. NUL bytes are not supported by environment variables.

Values are stored in `~/.secrets/env.json`, an object mapping environment variable
names to strings. The directory must be owned by you with mode 700, and the file
must be owned by you with mode 600. Symlinks, malformed JSON and invalid variable
names are rejected. Creation happens only when adding a value. Replacements are
atomic, but concurrent writers are not coordinated; do not edit from two sessions
at once. Removing a stored value does not remove an existing environment export.

## Credential Providers

Store values using the provider's own protected prompt:

```zsh
# macOS: security prompts for the value; an access-control dialog may appear
keychain_add github_token
secret_from_keychain GITHUB_TOKEN github_token

# Linux desktop with Secret Service and secret-tool
keyring_add github_token
secret_from_keyring GITHUB_TOKEN github_token

# Password Store, after configuring GPG and pass
pass insert github/token
secret_from_pass GITHUB_TOKEN github/token

# 1Password CLI, after signing in using the provider's documented workflow
secret_from_1password GITHUB_TOKEN 'op://Personal/GitHub/token'
```

Provider failures return nonzero and leave existing exports unchanged. Avoid
automatic provider sign-in or bulk secret loading in shell startup. Use functions
in the ignored `local/local.zsh` to load a named credential only when needed.
Keep token values out of terminal output, logs, process arguments and screenshots.

## Legacy Secret Files

The previous `~/.secrets/env` format was executable shell code. It is no longer
sourced or migrated automatically. Keep it private while reviewing its contents
locally. Re-enter each required credential through `secret_add KEY` or a provider
prompt; do not `source`, `eval`, or copy it into a tracked file. Verify the intended
command succeeds without printing the credential, then explicitly remove the old
file when no longer needed. Rotate anything previously exposed in Git or logs.
Ordinary deletion is not guaranteed secure erasure on SSDs or backup systems.

## Atlassian MCP

The managed `config/mcpm/servers.json` is tokenless. The launcher obtains Jira's
PAT from macOS Keychain, and optionally Confluence's PAT when a URL is configured.
Missing Jira credentials fail closed; missing Confluence credentials disable
Confluence. Keychain setup is a separate, interactive action:

```bash
bash scripts/mcpm-atlassian-keychain-setup.sh
```

For a legacy **private regular** MCPM configuration file, the migration command
removes old token fields and token-bearing arguments from the Atlassian entry,
preserves unrelated servers, and creates a mode-600 backup in a mode-700 directory.
That backup may still contain old credentials: restrict access and retire it after
verifying the migration. It does not transfer credentials into Keychain or rotate
them. Input and backup paths must be owned, non-symlink paths under HOME.

```bash
MCPM_SERVERS_FILE="$HOME/.config/mcpm/private-servers.json" \
  bash scripts/mcpm-atlassian-migrate.sh
```

Migration deliberately refuses the installed `servers.json` symlink: never edit
the shared template to store tokens. A fresh template needs Keychain setup, not
migration. Private MCP configurations must be selected explicitly in the client;
`servers.local.json` is ignored by Git but is not an automatic override.

The pinned launcher defaults to `READ_ONLY_MODE=true` and an `ENABLED_TOOLS`
allowlist of `jira_search,jira_get_issue`. Optional Confluence tools require an
explicit allowlist change. These are application controls, not an OS sandbox;
an environment override can change them. No authenticated smoke test is part of
the offline regression suite. Launching `mcpm run atlassian` is a separate action
that accesses credentials and the network.

## MCP Access And Dependencies

The filesystem server is scoped to `~/Code`, not the entire home directory.
All active server packages are pinned to exact top-level versions. Git, fetch and
Atlassian additionally pin compatible MCP SDK 1.x; MarkItDown has a different SDK
requirement. Transitive dependencies are not fully locked or audited, and package
retrieval still trusts the registries. Review and test pins before updating them.

Other servers have their own authority: Git and MarkItDown can access files,
fetch can reach networks including internal addresses, and Apple/Aha integrations
can expose personal or corporate data. Restrict client tool approvals and disable
unneeded servers. Use an OS/container sandbox and network restrictions where a
hard boundary is required. A filesystem-server root is not a global restriction.

## Checks And Recovery

```bash
make security
bash scripts/test-security.sh
```

The scanner inventories tracked files (including ignored and hidden tracked
files) and unignored untracked files. Findings include paths/lines but never
matched values. Suspected credentials or invalid JSON fail the check; missing
dependencies and scan errors also fail. It is heuristic, can report examples,
and does not scan Git history, ignored untracked files, symlink targets or host
permissions. A clean result is not proof that no secrets exist.

Dotfile backups preserve symlinks, not the contents of their targets, and do not
include the secret store. Back up secrets separately using a reviewed encrypted
backup process. Diagnose permissions without displaying values; do not loosen
permissions to make a command work.

References: [1Password CLI](https://developer.1password.com/docs/cli/),
[Password Store](https://www.passwordstore.org/), and
[Secret Service](https://specifications.freedesktop.org/secret-service/).
