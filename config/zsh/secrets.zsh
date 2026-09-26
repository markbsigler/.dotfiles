#!/usr/bin/env zsh
# ~/.config/zsh/secrets.zsh - Secrets management configuration
# Cross-platform secrets management for API keys, tokens, and credentials

# ============================================================================
# Secrets Directory Setup
# ============================================================================

SECRETS_DIR="$HOME/.secrets"

# ============================================================================
# Method 1: Plain File (Simple but less secure)
# ============================================================================

SECRETS_ENV_FILE="$SECRETS_DIR/env.json"

_secret_key_valid() {
    [[ "${1:-}" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] || {
        print -u2 -- 'Invalid environment variable name'
        return 1
    }
}

_secret_store_check() {
    local permissions
    command -v jq >/dev/null || return 1
    [[ ! -L "$SECRETS_DIR" && ! -L "$SECRETS_ENV_FILE" ]] || return 1
    [[ ! -e "$SECRETS_DIR" || ( -d "$SECRETS_DIR" && -O "$SECRETS_DIR" ) ]] || return 1
    if [[ -d "$SECRETS_DIR" ]]; then
        permissions="$(stat -f %Lp "$SECRETS_DIR" 2>/dev/null || stat -c %a "$SECRETS_DIR")" || return 1
        [[ "$permissions" == 700 ]] || { print -u2 -- 'Secrets directory must have mode 700'; return 1; }
    fi
    if [[ -e "$SECRETS_ENV_FILE" ]]; then
        [[ -f "$SECRETS_ENV_FILE" && -O "$SECRETS_ENV_FILE" ]] || return 1
        permissions="$(stat -f %Lp "$SECRETS_ENV_FILE" 2>/dev/null || stat -c %a "$SECRETS_ENV_FILE")" || return 1
        [[ "$permissions" == 600 ]] || { print -u2 -- 'Secrets file must have mode 600'; return 1; }
        command jq -e 'type == "object" and all(to_entries[]; (.key | test("^[A-Za-z_][A-Za-z0-9_]*$")) and (.value | type == "string"))' "$SECRETS_ENV_FILE" >/dev/null 2>&1 || return 1
    fi
}

# Helper function to add secrets to the env file
secret_add() {
    emulate -L zsh
    unsetopt xtrace
    local key="${1:-}" value temporary input
    [[ $# == 1 ]] || { print -u2 -- 'Usage: secret_add KEY (value via prompt or stdin)'; return 1; }
    _secret_key_valid "$key" && _secret_store_check || return 1
    if [[ -t 0 ]]; then
        read -rs 'value?Secret: ' || return 1
        print
    else
        value="$(cat; printf '.')"
        value="${value%.}"
    fi
    (umask 077; mkdir -p "$SECRETS_DIR") || return 1
    chmod 700 "$SECRETS_DIR" || return 1
    input="$SECRETS_ENV_FILE"
    [[ -f "$input" ]] || input=/dev/null
    temporary="$(mktemp "$SECRETS_DIR/.env.XXXXXX")" || return 1
    if print -rn -- "$value" | command jq -s --arg key "$key" --rawfile value /dev/stdin '(.[0] // {}) + {($key): $value}' "$input" > "$temporary" &&
        chmod 600 "$temporary" && mv -f "$temporary" "$SECRETS_ENV_FILE"; then
        print -- "Stored $key; use secret_load $key when needed."
    else
        rm -f "$temporary"
        return 1
    fi
}

# Helper function to list secrets (without values)
secret_list() {
    _secret_store_check && [[ -f "$SECRETS_ENV_FILE" ]] || return 1
    command jq -r 'keys[]' "$SECRETS_ENV_FILE"
}

# Helper function to remove a secret
secret_remove() {
    local key="${1:-}" temporary
    _secret_key_valid "$key" && _secret_store_check && [[ -f "$SECRETS_ENV_FILE" ]] || return 1
    temporary="$(mktemp "$SECRETS_DIR/.env.XXXXXX")" || return 1
    if command jq --arg key "$key" 'del(.[$key])' "$SECRETS_ENV_FILE" > "$temporary" &&
        chmod 600 "$temporary" && mv -f "$temporary" "$SECRETS_ENV_FILE"; then
        print -- "Removed stored value for $key. Existing exports are unchanged."
    else
        rm -f "$temporary"
        return 1
    fi
}

secret_load() {
    emulate -L zsh
    unsetopt xtrace
    local key="${1:-}" value
    _secret_key_valid "$key" && _secret_store_check && [[ -f "$SECRETS_ENV_FILE" ]] || return 1
    value="$(command jq -erj --arg key "$key" '.[$key] // error("Missing key")' "$SECRETS_ENV_FILE" && printf '.')" || return 1
    export "$key=${value%.}"
}

# ============================================================================
# Method 2: Password Store (pass) - More Secure
# ============================================================================

# Helper function to load a secret from pass
secret_from_pass() {
    emulate -L zsh
    unsetopt xtrace
    if [[ $# != 2 ]]; then
        echo "Usage: secret_from_pass <ENV_VAR> <pass-path>"
        echo "Example: secret_from_pass GITHUB_TOKEN github/token"
        return 1
    fi
    
    if ! command -v pass &> /dev/null; then
        echo "❌ pass command not found. Install password-store to use this function."
        return 1
    fi
    
    local env_var="$1"
    local pass_path="$2"
    
    _secret_key_valid "$env_var" || return 1
    local value
    value="$(pass show "$pass_path" 2>/dev/null)" || return 1
    if [[ -n "$value" ]]; then
        export "${env_var}=${value}"
        echo "✅ Loaded ${env_var} from pass:${pass_path}"
    else
        echo "❌ Failed to load secret from pass:${pass_path}"
        return 1
    fi
}

# ============================================================================
# Method 3: 1Password CLI - Most Secure
# ============================================================================

# Helper function to load a secret from 1Password
secret_from_1password() {
    emulate -L zsh
    unsetopt xtrace
    if [[ $# != 2 ]]; then
        echo "Usage: secret_from_1password <ENV_VAR> <op-reference>"
        echo "Example: secret_from_1password GITHUB_TOKEN 'op://Personal/GitHub/token'"
        return 1
    fi
    
    if ! command -v op &> /dev/null; then
        echo "❌ op command not found. Install 1Password CLI to use this function."
        return 1
    fi
    
    local env_var="$1"
    local op_ref="$2"
    
    _secret_key_valid "$env_var" || return 1
    local value
    value="$(op read "$op_ref" 2>/dev/null)" || return 1
    if [[ -n "$value" ]]; then
        export "${env_var}=${value}"
        echo "✅ Loaded ${env_var} from 1Password"
    else
        echo "❌ Failed to load secret from 1Password"
        echo "   Make sure you're signed in: op signin"
        return 1
    fi
}

# ============================================================================
# Method 4: macOS Keychain
# ============================================================================

# Helper function to load a secret from macOS Keychain
secret_from_keychain() {
    emulate -L zsh
    unsetopt xtrace
    if [[ $# != 2 ]]; then
        echo "Usage: secret_from_keychain <ENV_VAR> <service-name>"
        echo "Example: secret_from_keychain GITHUB_TOKEN github_token"
        return 1
    fi
    
    if [[ "$OSTYPE" != darwin* ]]; then
        echo "❌ This function requires macOS"
        return 1
    fi
    
    local env_var="$1"
    local service="$2"
    
    _secret_key_valid "$env_var" || return 1
    local value
    value="$(security find-generic-password -s "$service" -w 2>/dev/null)" || return 1
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
    if [[ $# != 1 || -z "$1" ]]; then
        echo "Usage: keychain_add <service-name> (Keychain prompts for the value)"
        return 1
    fi
    
    if [[ "$OSTYPE" != darwin* ]]; then
        echo "❌ This function requires macOS"
        return 1
    fi
    
    local service="$1"
    local account="${USER}"
    security add-generic-password -U -s "$service" -a "$account" -T "" -w || return 1
    echo "✅ Secret added to Keychain service: $service"
}

# ============================================================================
# Method 5: Linux Secret Service (GNOME Keyring / KWallet)
# ============================================================================

# Helper function to load a secret from Linux Secret Service
secret_from_keyring() {
    emulate -L zsh
    unsetopt xtrace
    if [[ $# != 2 ]]; then
        echo "Usage: secret_from_keyring <ENV_VAR> <service-name>"
        echo "Example: secret_from_keyring GITHUB_TOKEN github_token"
        return 1
    fi
    
    if [[ "$OSTYPE" != linux* ]]; then
        echo "❌ This function requires Linux"
        return 1
    fi
    
    if ! command -v secret-tool &> /dev/null; then
        echo "❌ secret-tool command not found. Install libsecret to use this function."
        return 1
    fi
    
    local env_var="$1"
    local service="$2"
    
    _secret_key_valid "$env_var" || return 1
    local value
    value="$(secret-tool lookup service "$service" 2>/dev/null)" || return 1
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
    if [[ $# != 1 || -z "$1" ]]; then
        echo "Usage: keyring_add <service-name> (prompt or stdin)"
        return 1
    fi
    
    if [[ "$OSTYPE" != linux* ]]; then
        echo "❌ This function requires Linux"
        return 1
    fi
    
    if ! command -v secret-tool &> /dev/null; then
        echo "❌ secret-tool command not found. Install libsecret to use this function."
        return 1
    fi
    
    local service="$1"
    secret-tool store --label="$service" service "$service" || return 1
    echo "✅ Secret added to Secret Service: $service"
}

# ============================================================================
# Helper Functions
# ============================================================================

# Show available secrets management methods
secret_help() {
    cat << 'EOF'
Secrets Management - Available Methods:

1. Plain File (Simple, less secure)
    - secret_add <KEY>             # Prompt, or read literal stdin
    - secret_load <KEY>            # Export on demand
   - secret_list                   # List all secrets (keys only)
   - secret_remove <KEY>           # Remove a secret
    - File location: ~/.secrets/env.json (legacy env files are not executed)

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
    - keychain_add <service-name>
    - Example: keychain_add github_token

5. Linux Secret Service (GNOME Keyring/KWallet)
   - secret_from_keyring <ENV_VAR> <service-name>
    - keyring_add <service-name>
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
# Load named values explicitly with secret_load.

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

