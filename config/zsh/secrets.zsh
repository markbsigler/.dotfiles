#!/usr/bin/env zsh
# ~/.config/zsh/secrets.zsh - Secrets management configuration
# Cross-platform secrets management for API keys, tokens, and credentials

# ============================================================================
# Secrets Directory Setup
# ============================================================================

# Create secure secrets directory if it doesn't exist
# This directory should NOT be tracked in git
SECRETS_DIR="$HOME/.secrets"
if [[ ! -d "$SECRETS_DIR" ]]; then
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"  # Only user can read/write/execute
fi

# ============================================================================
# Method 1: Plain File (Simple but less secure)
# ============================================================================

# Load secrets from a plain text file
# Format: export KEY="value"
# Example: export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

SECRETS_ENV_FILE="$SECRETS_DIR/env"

if [[ -f "$SECRETS_ENV_FILE" ]]; then
    # Ensure file has correct permissions
    if [[ $(stat -f '%A' "$SECRETS_ENV_FILE" 2>/dev/null || stat -c '%a' "$SECRETS_ENV_FILE" 2>/dev/null) != "600" ]]; then
        chmod 600 "$SECRETS_ENV_FILE"
    fi
    source "$SECRETS_ENV_FILE"
fi

# Helper function to add secrets to the env file
secret_add() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Usage: secret_add <KEY> <value>"
        echo "Example: secret_add GITHUB_TOKEN ghp_xxxxxxxxxxxx"
        return 1
    fi
    
    local key="$1"
    local value="$2"
    
    # Create file if it doesn't exist
    touch "$SECRETS_ENV_FILE"
    chmod 600 "$SECRETS_ENV_FILE"
    
    # Remove existing entry if present
    if grep -q "^export ${key}=" "$SECRETS_ENV_FILE"; then
        # Cross-platform sed
        if [[ "$OSTYPE" == darwin* ]]; then
            sed -i '' "/^export ${key}=/d" "$SECRETS_ENV_FILE"
        else
            sed -i "/^export ${key}=/d" "$SECRETS_ENV_FILE"
        fi
    fi
    
    # Add new entry
    echo "export ${key}=\"${value}\"" >> "$SECRETS_ENV_FILE"
    echo "✅ Secret '${key}' added to $SECRETS_ENV_FILE"
    echo "⚠️  Run 'source ~/.zshrc' or restart your shell to load the secret"
}

# Helper function to list secrets (without values)
secret_list() {
    if [[ -f "$SECRETS_ENV_FILE" ]]; then
        echo "Stored secrets:"
        grep '^export ' "$SECRETS_ENV_FILE" | sed 's/export \([^=]*\)=.*/  - \1/'
    else
        echo "No secrets file found at $SECRETS_ENV_FILE"
    fi
}

# Helper function to remove a secret
secret_remove() {
    if [[ -z "$1" ]]; then
        echo "Usage: secret_remove <KEY>"
        return 1
    fi
    
    local key="$1"
    
    if [[ -f "$SECRETS_ENV_FILE" ]]; then
        # Cross-platform sed
        if [[ "$OSTYPE" == darwin* ]]; then
            sed -i '' "/^export ${key}=/d" "$SECRETS_ENV_FILE"
        else
            sed -i "/^export ${key}=/d" "$SECRETS_ENV_FILE"
        fi
        echo "✅ Secret '${key}' removed from $SECRETS_ENV_FILE"
    else
        echo "No secrets file found"
    fi
}

# ============================================================================
# Method 2: Password Store (pass) - More Secure
# ============================================================================

# Setup pass (password-store) integration if available
if command -v pass &> /dev/null; then
    # Example: Load GitHub token from pass
    # export GITHUB_TOKEN=$(pass show github/token 2>/dev/null)
    
    # Helper function to load a secret from pass
    secret_from_pass() {
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo "Usage: secret_from_pass <ENV_VAR> <pass-path>"
            echo "Example: secret_from_pass GITHUB_TOKEN github/token"
            return 1
        fi
        
        local env_var="$1"
        local pass_path="$2"
        
        local value=$(pass show "$pass_path" 2>/dev/null)
        if [[ -n "$value" ]]; then
            export "${env_var}=${value}"
            echo "✅ Loaded ${env_var} from pass:${pass_path}"
        else
            echo "❌ Failed to load secret from pass:${pass_path}"
            return 1
        fi
fi

# ============================================================================
# Method 3: 1Password CLI - Most Secure
# ============================================================================

# Setup 1Password CLI integration if available
if command -v op &> /dev/null; then
    # Example: Load GitHub token from 1Password
    # export GITHUB_TOKEN=$(op read "op://Personal/GitHub/token" 2>/dev/null)
    
    # Helper function to load a secret from 1Password
    secret_from_1password() {
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo "Usage: secret_from_1password <ENV_VAR> <op-reference>"
            echo "Example: secret_from_1password GITHUB_TOKEN 'op://Personal/GitHub/token'"
            return 1
        fi
        
        local env_var="$1"
        local op_ref="$2"
        
        local value=$(op read "$op_ref" 2>/dev/null)
        if [[ -n "$value" ]]; then
            export "${env_var}=${value}"
            echo "✅ Loaded ${env_var} from 1Password"
        else
            echo "❌ Failed to load secret from 1Password"
            echo "   Make sure you're signed in: op signin"
            return 1
        fi
    fi
fi

# ============================================================================
# Method 4: macOS Keychain
# ============================================================================

if [[ "$OSTYPE" == darwin* ]]; then
    # Helper function to load a secret from macOS Keychain
    secret_from_keychain() {
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo "Usage: secret_from_keychain <ENV_VAR> <service-name>"
            echo "Example: secret_from_keychain GITHUB_TOKEN github_token"
            return 1
        fi
        
        local env_var="$1"
        local service="$2"
        
        local value=$(security find-generic-password -s "$service" -w 2>/dev/null)
        if [[ -n "$value" ]]; then
            export "${env_var}=${value}"
            echo "✅ Loaded ${env_var} from Keychain"
        else
            echo "❌ Failed to load secret from Keychain service: $service"
            return 1
        fi
    }
    
    # Helper to add a secret to Keychain
    keychain_add() {
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo "Usage: keychain_add <service-name> <secret>"
            echo "Example: keychain_add github_token ghp_xxxxxxxxxxxx"
            return 1
        fi
        
        local service="$1"
        local secret="$2"
        local account="${USER}"
        
        # Delete existing if present
        security delete-generic-password -s "$service" 2>/dev/null
        
        # Add new secret
        security add-generic-password -s "$service" -a "$account" -w "$secret"
        echo "✅ Secret added to Keychain service: $service"
    }
fi

# ============================================================================
# Method 5: Linux Secret Service (GNOME Keyring / KWallet)
# ============================================================================

if [[ "$OSTYPE" == linux* ]] && command -v secret-tool &> /dev/null; then
    # Helper function to load a secret from Linux Secret Service
    secret_from_keyring() {
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo "Usage: secret_from_keyring <ENV_VAR> <service-name>"
            echo "Example: secret_from_keyring GITHUB_TOKEN github_token"
            return 1
        fi
        
        local env_var="$1"
        local service="$2"
        
        local value=$(secret-tool lookup service "$service" 2>/dev/null)
        if [[ -n "$value" ]]; then
            export "${env_var}=${value}"
            echo "✅ Loaded ${env_var} from Secret Service"
        else
            echo "❌ Failed to load secret from Secret Service: $service"
            return 1
        fi
    }
    
    # Helper to add a secret to Secret Service
    keyring_add() {
        if [[ -z "$1" ]] || [[ -z "$2" ]]; then
            echo "Usage: keyring_add <service-name> <secret>"
            echo "Example: keyring_add github_token ghp_xxxxxxxxxxxx"
            return 1
        fi
        
        local service="$1"
        local secret="$2"
        
        echo -n "$secret" | secret-tool store --label="$service" service "$service"
        echo "✅ Secret added to Secret Service: $service"
    }
fi

# ============================================================================
# Helper Functions
# ============================================================================

# Show available secrets management methods
secret_help() {
    cat << 'EOF'
Secrets Management - Available Methods:

1. Plain File (Simple, less secure)
   - secret_add <KEY> <value>     # Add a secret
   - secret_list                   # List all secrets (keys only)
   - secret_remove <KEY>           # Remove a secret
   - File location: ~/.secrets/env

2. Password Store (pass) - Linux/macOS
   - secret_from_pass <ENV_VAR> <pass-path>
   - Example: secret_from_pass GITHUB_TOKEN github/token
   - Requires: pass (password-store)

3. 1Password CLI - Cross-platform
   - secret_from_1password <ENV_VAR> <op-reference>
   - Example: secret_from_1password GITHUB_TOKEN 'op://Personal/GitHub/token'
   - Requires: op (1Password CLI)

4. macOS Keychain
   - secret_from_keychain <ENV_VAR> <service-name>
   - keychain_add <service-name> <secret>
   - Example: keychain_add github_token ghp_xxxx

5. Linux Secret Service (GNOME Keyring/KWallet)
   - secret_from_keyring <ENV_VAR> <service-name>
   - keyring_add <service-name> <secret>
   - Requires: secret-tool (libsecret)

Security Recommendations:
- Use method 2, 3, 4, or 5 for production secrets
- Method 1 is convenient for development but less secure
- Never commit secrets to git
- Always set proper file permissions (600)

For more information, see: ~/.config/zsh/secrets.zsh
EOF
}

# ============================================================================
# Example Usage (Commented Out)
# ============================================================================

# Uncomment and customize these examples for your secrets

# Method 1: Plain file
# Already loaded automatically if ~/.secrets/env exists

# Method 2: Password Store
# secret_from_pass GITHUB_TOKEN github/token
# secret_from_pass OPENAI_API_KEY openai/api-key

# Method 3: 1Password
# secret_from_1password GITHUB_TOKEN 'op://Personal/GitHub/token'
# secret_from_1password AWS_ACCESS_KEY_ID 'op://Personal/AWS/access-key-id'

# Method 4: macOS Keychain
# secret_from_keychain GITHUB_TOKEN github_token

# Method 5: Linux Secret Service
# secret_from_keyring GITHUB_TOKEN github_token

