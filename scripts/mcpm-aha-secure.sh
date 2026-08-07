#!/bin/zsh
# Secure launcher for Aha MCP server - reads API token from macOS Keychain

set -euo pipefail

# Require AHA_DOMAIN from MCPM environment
if [[ -z "${AHA_DOMAIN:-}" ]]; then
    echo "ERROR: AHA_DOMAIN environment variable is required" >&2
    exit 1
fi

# Read API token from Keychain
TOKEN_SERVICE="${AHA_MCP_TOKEN_SERVICE:-aha_mcp_token}"
if ! AHA_API_TOKEN=$(security find-generic-password -s "$TOKEN_SERVICE" -w 2>/dev/null); then
    echo "ERROR: Failed to read Aha API token from Keychain service '$TOKEN_SERVICE'" >&2
    echo "Run: security add-generic-password -s '$TOKEN_SERVICE' -a 'your-email' -w 'your-token'" >&2
    exit 1
fi

export AHA_API_TOKEN
export AHA_DOMAIN

# Execute aha-mcp with npx
exec npx -y aha-mcp
