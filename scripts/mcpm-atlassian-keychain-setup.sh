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
echo "Keychain will prompt directly for token values; do not supply tokens as arguments."

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

read -r -p "Configure optional Confluence access? [y/N]: " configure_confluence
if [[ "$configure_confluence" == y || "$configure_confluence" == Y ]]; then
    security add-generic-password -U -a "$USER" -s "$CONF_SERVICE" -T "" -w
fi
security add-generic-password -U -a "$USER" -s "$JIRA_SERVICE" -T "" -w

echo "Stored Keychain secrets:"
if [[ "$configure_confluence" == y || "$configure_confluence" == Y ]]; then echo "  - $CONF_SERVICE"; fi
echo "  - $JIRA_SERVICE"
echo "Next: run ~/.dotfiles/scripts/mcpm-atlassian-migrate.sh"