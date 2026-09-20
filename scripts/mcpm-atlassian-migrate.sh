#!/usr/bin/env bash
set -euo pipefail
umask 077

MCPM_SERVERS_FILE="${MCPM_SERVERS_FILE:-$HOME/.config/mcpm/servers.json}"
BACKUP_DIR="${MCPM_BACKUP_DIR:-$HOME/.config/mcpm/backups}"

private_path() {
  local relative="${1#"$HOME/"}" parent="$HOME" component
  [[ "$relative" != "$1" ]] || return 1
  while [[ -n "$relative" ]]; do
    component="${relative%%/*}"
    [[ -n "$component" && "$component" != . && "$component" != .. ]] || return 1
    parent="$parent/$component"
    [[ ! -L "$parent" && ( ! -e "$parent" || -O "$parent" ) ]] || return 1
    [[ "$relative" == */* ]] || break
    [[ ! -e "$parent" || -d "$parent" ]] || return 1
    relative="${relative#*/}"
  done
}

private_path "$MCPM_SERVERS_FILE" && private_path "$BACKUP_DIR" || {
  echo "Migration paths must be owned, non-symlink paths beneath HOME." >&2
  exit 1
}

if [[ ! -f "$MCPM_SERVERS_FILE" || -L "$MCPM_SERVERS_FILE" ]]; then
    echo "MCPM servers file not found: $MCPM_SERVERS_FILE" >&2
  echo "Migration requires a private regular file, not a managed template symlink." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Missing required command: jq" >&2
    exit 1
fi

[[ ! -L "$BACKUP_DIR" ]] || { echo "Refusing symlink backup directory" >&2; exit 1; }
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
tmp_file="$(mktemp "$(dirname "$MCPM_SERVERS_FILE")/.servers.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

jq '
  def argValue($args; $prefix):
    (($args // []) | map(select(startswith($prefix))) | .[0] // "" | sub("^" + $prefix; ""));
  def nonEmpty($v; $fallback):
    if ($v == null) or ($v == "") then $fallback else $v end;

  if ((.atlassian | type) != "object") or
     (((.atlassian.args // []) | type) != "array") or
     (((.atlassian.env // {}) | type) != "object") then
    error("Invalid Atlassian configuration")
  elif ((.atlassian.args // []) | all(.[]; type == "string") | not) or
       ((.atlassian.env // {}) | all(.[]; type == "string") | not) then
    error("Atlassian arguments and environment values must be strings")
  else
    (.atlassian.args // []) as $oldArgs
    | .atlassian.env = {
        "CONFLUENCE_URL": nonEmpty(.atlassian.env.CONFLUENCE_URL; argValue($oldArgs; "--confluence-url=")),
        "CONFLUENCE_USERNAME": nonEmpty(.atlassian.env.CONFLUENCE_USERNAME; argValue($oldArgs; "--confluence-username=")),
        "JIRA_URL": nonEmpty(.atlassian.env.JIRA_URL; argValue($oldArgs; "--jira-url=")),
        "JIRA_USERNAME": nonEmpty(.atlassian.env.JIRA_USERNAME; argValue($oldArgs; "--jira-username=")),
        "ATL_MCP_CONFLUENCE_TOKEN_SERVICE": nonEmpty(.atlassian.env.ATL_MCP_CONFLUENCE_TOKEN_SERVICE; "atl_mcp_confluence_token"),
        "ATL_MCP_JIRA_TOKEN_SERVICE": nonEmpty(.atlassian.env.ATL_MCP_JIRA_TOKEN_SERVICE; "atl_mcp_jira_token"),
        "READ_ONLY_MODE": "true",
        "ENABLED_TOOLS": "jira_search,jira_get_issue"
      }
    | .atlassian.env |= with_entries(select(.value != ""))
    | if (.atlassian.env.JIRA_URL // "") == "" then error("Missing Jira URL") else . end
    | .atlassian.command = "/bin/zsh"
    | .atlassian.args = ["-fc", "exec \"$HOME/.local/bin/mcpm-atlassian-secure\""]
  end
' "$MCPM_SERVERS_FILE" > "$tmp_file"

backup_file="$(mktemp "$BACKUP_DIR/servers.json.XXXXXX")"
cat "$MCPM_SERVERS_FILE" > "$backup_file"
chmod 600 "$tmp_file" "$backup_file"
echo "Private backup created (may contain old credentials): $backup_file"
mv -f "$tmp_file" "$MCPM_SERVERS_FILE"

echo "Updated Atlassian MCP server to secure launcher."
echo "Next steps:"
echo "  1) ~/.dotfiles/scripts/mcpm-atlassian-keychain-setup.sh"
echo "  2) mcpm run atlassian"