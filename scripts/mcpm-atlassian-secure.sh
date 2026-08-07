#!/usr/bin/env zsh
set -euo pipefail

# Load required settings for Jira (required)
: "${JIRA_URL:?Missing JIRA_URL}"

# Confluence is optional (set CONFLUENCE_URL to enable)
CONFLUENCE_URL="${CONFLUENCE_URL:-}"

# Use overridable Keychain service names to support multiple profiles.
: "${ATL_MCP_JIRA_TOKEN_SERVICE:=atl_mcp_jira_token}"
: "${ATL_MCP_CONFLUENCE_TOKEN_SERVICE:=atl_mcp_confluence_token}"

# Read Jira Personal Access Token from Keychain (required for Server/Data Center)
JIRA_PERSONAL_TOKEN="$(security find-generic-password -s "$ATL_MCP_JIRA_TOKEN_SERVICE" -w 2>/dev/null || true)"

if [[ -z "$JIRA_PERSONAL_TOKEN" ]]; then
    echo "Missing Keychain secret for service: $ATL_MCP_JIRA_TOKEN_SERVICE" >&2
    echo "Run: ~/.dotfiles/scripts/mcpm-atlassian-keychain-setup.sh" >&2
    exit 1
fi

# Export environment variables for Server/Data Center authentication
export JIRA_URL
export JIRA_PERSONAL_TOKEN

# Add Confluence if URL is set
if [[ -n "$CONFLUENCE_URL" ]]; then
    CONFLUENCE_PERSONAL_TOKEN="$(security find-generic-password -s "$ATL_MCP_CONFLUENCE_TOKEN_SERVICE" -w 2>/dev/null || true)"
    
    if [[ -z "$CONFLUENCE_PERSONAL_TOKEN" ]]; then
        echo "Warning: CONFLUENCE_URL set but no token in Keychain (service: $ATL_MCP_CONFLUENCE_TOKEN_SERVICE)" >&2
        echo "Confluence functionality will be disabled." >&2
    else
        export CONFLUENCE_URL
        export CONFLUENCE_PERSONAL_TOKEN
    fi
fi

# Execute mcp-atlassian (Server/Data Center uses env vars, not CLI args)
exec uvx mcp-atlassian