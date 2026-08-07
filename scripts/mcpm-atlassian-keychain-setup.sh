#!/usr/bin/env bash
set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
    echo "This script requires macOS Keychain." >&2
    exit 1
fi

if ! command -v security >/dev/null 2>&1; then
    echo "Missing required command: security" >&2
    exit 1
fi

echo "Configure Atlassian MCP Keychain secrets"
echo "Token values are read silently and never passed as command arguments."

CONF_SERVICE="${ATL_MCP_CONFLUENCE_TOKEN_SERVICE:-atl_mcp_confluence_token}"
JIRA_SERVICE="${ATL_MCP_JIRA_TOKEN_SERVICE:-atl_mcp_jira_token}"

read -r -p "Confluence token service name [$CONF_SERVICE]: " conf_input
if [[ -n "$conf_input" ]]; then
    CONF_SERVICE="$conf_input"
fi

read -r -p "Jira token service name [$JIRA_SERVICE]: " jira_input
if [[ -n "$jira_input" ]]; then
    JIRA_SERVICE="$jira_input"
fi

read -r -s -p "Enter Confluence token: " conf_token
echo
if [[ -z "$conf_token" ]]; then
    echo "Confluence token cannot be empty." >&2
    exit 1
fi
security add-generic-password -U -a "$USER" -s "$CONF_SERVICE" -w "$conf_token" >/dev/null
unset conf_token

read -r -s -p "Enter Jira token: " jira_token
echo
if [[ -z "$jira_token" ]]; then
    echo "Jira token cannot be empty." >&2
    exit 1
fi
security add-generic-password -U -a "$USER" -s "$JIRA_SERVICE" -w "$jira_token" >/dev/null
unset jira_token

echo "Stored Keychain secrets:"
echo "  - $CONF_SERVICE"
echo "  - $JIRA_SERVICE"
echo "Next: run ~/.dotfiles/scripts/mcpm-atlassian-migrate.sh"