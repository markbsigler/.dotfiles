#!/usr/bin/env bash
set -euo pipefail

MCPM_SERVERS_FILE="${MCPM_SERVERS_FILE:-$HOME/.config/mcpm/servers.json}"
BACKUP_DIR="${MCPM_BACKUP_DIR:-$HOME/.config/mcpm/backups}"

if [[ ! -f "$MCPM_SERVERS_FILE" ]]; then
    echo "MCPM servers file not found: $MCPM_SERVERS_FILE" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Missing required command: jq" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"
backup_file="$BACKUP_DIR/servers.json.$(date +%Y%m%d-%H%M%S).bak"
cp "$MCPM_SERVERS_FILE" "$backup_file"
echo "Backup created: $backup_file"

tmp_file="$(mktemp)"

jq '
  def argValue($args; $prefix):
    (($args // []) | map(select(startswith($prefix))) | .[0] // "" | sub("^" + $prefix; ""));
  def nonEmpty($v; $fallback):
    if ($v == null) or ($v == "") then $fallback else $v end;

  if (.atlassian == null) then
    .
  else
    (.atlassian.args // []) as $oldArgs
    | .atlassian.env = ((.atlassian.env // {}) + {
        "CONFLUENCE_URL": nonEmpty(.atlassian.env.CONFLUENCE_URL; nonEmpty(argValue($oldArgs; "--confluence-url="); "https://your-company.atlassian.net/wiki")),
        "CONFLUENCE_USERNAME": nonEmpty(.atlassian.env.CONFLUENCE_USERNAME; nonEmpty(argValue($oldArgs; "--confluence-username="); "your.email@company.com")),
        "JIRA_URL": nonEmpty(.atlassian.env.JIRA_URL; nonEmpty(argValue($oldArgs; "--jira-url="); "https://your-company.atlassian.net")),
        "JIRA_USERNAME": nonEmpty(.atlassian.env.JIRA_USERNAME; nonEmpty(argValue($oldArgs; "--jira-username="); "your.email@company.com")),
        "ATL_MCP_CONFLUENCE_TOKEN_SERVICE": nonEmpty(.atlassian.env.ATL_MCP_CONFLUENCE_TOKEN_SERVICE; "atl_mcp_confluence_token"),
        "ATL_MCP_JIRA_TOKEN_SERVICE": nonEmpty(.atlassian.env.ATL_MCP_JIRA_TOKEN_SERVICE; "atl_mcp_jira_token")
      })
    | .atlassian.command = "/bin/zsh"
    | .atlassian.args = ["-lc", "$HOME/.local/bin/mcpm-atlassian-secure"]
  end
' "$MCPM_SERVERS_FILE" > "$tmp_file"

mv -f "$tmp_file" "$MCPM_SERVERS_FILE"

echo "Updated Atlassian MCP server to secure launcher."
echo "Next steps:"
echo "  1) ~/.dotfiles/scripts/mcpm-atlassian-keychain-setup.sh"
echo "  2) mcpm run atlassian"