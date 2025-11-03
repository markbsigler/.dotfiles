# ~/.config/zsh/secrets.zsh
# =============================================================================
# Secrets Management Framework
# Secure handling of API keys, tokens, and sensitive environment variables
# Cross-platform: macOS and Linux
# =============================================================================

# =============================================================================
# Secrets File Locations (in order of precedence)
# =============================================================================
# These files are NOT tracked in git (.gitignore)
# Choose the method that best fits your workflow

# Primary: XDG-compliant location
SECRETS_FILE_XDG="$XDG_CONFIG_HOME/secrets/env"

# Fallback: Home directory
SECRETS_FILE_HOME="$HOME/.secrets/env"

# Legacy location (for backward compatibility)
SECRETS_FILE_LEGACY="$HOME/.env"

# =============================================================================
# Load Secrets from File
# =============================================================================
# Simple file-based secrets (not encrypted, but git-ignored)
# Format: export VARIABLE_NAME="value"

load_secrets_from_file() {
    local secrets_file=""
    
    # Find first available secrets file
    for file in "$SECRETS_FILE_XDG" "$SECRETS_FILE_HOME" "$SECRETS_FILE_LEGACY"; do
        if [[ -f "$file" ]]; then
            secrets_file="$file"
            break
        fi
    done
    
    if [[ -n "$secrets_file" ]]; then
        # Source the secrets file
        # shellcheck disable=SC1090
        source "$secrets_file"
        
        # Only show message in verbose mode
        [[ -n "${DOTFILES_VERBOSE:-}" ]] && echo "✓ Loaded secrets from: $secrets_file"
    fi
}

# =============================================================================
# Integration with Password Managers
# =============================================================================

# --- 1Password CLI ---
# Requires: 1Password CLI (op) installed and configured
# Install: https://developer.1password.com/docs/cli/get-started/
load_secrets_from_1password() {
    if ! command -v op &> /dev/null; then
        return 1
    fi
    
    # Check if signed in
    if ! op account list &> /dev/null; then
        [[ -n "${DOTFILES_VERBOSE:-}" ]] && echo "⚠ 1Password CLI: not signed in"
        return 1
    fi
    
    # Example: Load GitHub token from 1Password
    # export GITHUB_TOKEN=$(op read "op://Personal/GitHub/token")
    
    # Example: Load AWS credentials
    # export AWS_ACCESS_KEY_ID=$(op read "op://Personal/AWS/access_key_id")
    # export AWS_SECRET_ACCESS_KEY=$(op read "op://Personal/AWS/secret_access_key")
    
    [[ -n "${DOTFILES_VERBOSE:-}" ]] && echo "✓ 1Password integration available"
    return 0
}

# --- pass (password-store) ---
# Requires: pass installed
# Install macOS: brew install pass
# Install Linux: apt install pass / dnf install pass / pacman -S pass
load_secrets_from_pass() {
    if ! command -v pass &> /dev/null; then
        return 1
    fi
    
    # Check if password store is initialized
    if [[ ! -d "$HOME/.password-store" ]] && [[ ! -d "${PASSWORD_STORE_DIR:-}" ]]; then
        [[ -n "${DOTFILES_VERBOSE:-}" ]] && echo "⚠ pass: not initialized"
        return 1
    fi
    
    # Example: Load secrets from pass
    # export GITHUB_TOKEN=$(pass show github/token)
    # export OPENAI_API_KEY=$(pass show api/openai)
    # export AWS_ACCESS_KEY_ID=$(pass show aws/access_key_id)
    
    [[ -n "${DOTFILES_VERBOSE:-}" ]] && echo "✓ pass integration available"
    return 0
}

# --- macOS Keychain ---
# macOS only - use security command to access keychain
load_secrets_from_keychain_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 1
    fi
    
    if ! command -v security &> /dev/null; then
        return 1
    fi
    
    # Example: Load secret from macOS Keychain
    # export GITHUB_TOKEN=$(security find-generic-password -w -s "github-token" -a "$USER")
    
    # Helper function to get password from keychain
    get_keychain_password() {
        local service="$1"
        local account="${2:-$USER}"
        security find-generic-password -w -s "$service" -a "$account" 2>/dev/null
    }
    
    [[ -n "${DOTFILES_VERBOSE:-}" ]] && echo "✓ macOS Keychain integration available"
    return 0
}

# --- Linux Secret Service (libsecret) ---
# Linux with desktop environment (GNOME Keyring, KWallet, etc.)
# Requires: libsecret-tools
load_secrets_from_libsecret() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        return 1
    fi
    
    if ! command -v secret-tool &> /dev/null; then
        return 1
    fi
    
    # Example: Load secret from GNOME Keyring
    # export GITHUB_TOKEN=$(secret-tool lookup service github account token)
    
    # Helper function to get password from secret service
    get_secret() {
        local service="$1"
        local attribute="$2"
        secret-tool lookup service "$service" "$attribute" 2>/dev/null
    }
    
    [[ -n "${DOTFILES_VERBOSE:-}" ]] && echo "✓ Linux Secret Service integration available"
    return 0
}

# =============================================================================
# Environment-specific Secrets
# =============================================================================
# Load different secrets based on work/personal context

load_work_secrets() {
    # Work-specific secrets
    # This function can be called via: work_env (see environments.zsh)
    
    # File-based
    local work_secrets="$XDG_CONFIG_HOME/secrets/work.env"
    [[ -f "$work_secrets" ]] && source "$work_secrets"
    
    # Or from password manager
    # export WORK_VPN_PASSWORD=$(pass show work/vpn)
    # export WORK_API_KEY=$(op read "op://Work/API/key")
}

load_personal_secrets() {
    # Personal-specific secrets
    # This function can be called via: personal_env (see environments.zsh)
    
    # File-based
    local personal_secrets="$XDG_CONFIG_HOME/secrets/personal.env"
    [[ -f "$personal_secrets" ]] && source "$personal_secrets"
}

# =============================================================================
# Helper Functions
# =============================================================================

# Initialize secrets directory
init_secrets_dir() {
    local secrets_dir="$XDG_CONFIG_HOME/secrets"
    
    if [[ ! -d "$secrets_dir" ]]; then
        mkdir -p "$secrets_dir"
        chmod 700 "$secrets_dir"  # Owner only
        
        # Create template file
        cat > "$secrets_dir/env.template" << 'EOF'
# Secrets Environment Variables
# =============================================================================
# Copy this file to 'env' and fill in your secrets
# The 'env' file is git-ignored for security
# =============================================================================

# Example: GitHub Personal Access Token
# export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

# Example: OpenAI API Key
# export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxxxxxx"

# Example: AWS Credentials
# export AWS_ACCESS_KEY_ID="AKIAxxxxxxxxx"
# export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxx"
# export AWS_DEFAULT_REGION="us-east-1"

# Example: Docker Hub
# export DOCKER_USERNAME="your-username"
# export DOCKER_PASSWORD="your-password"

# Example: NPM Token
# export NPM_TOKEN="npm_xxxxxxxxxxxxxxxxxxxx"

# Example: Database URLs
# export DATABASE_URL="postgresql://user:pass@localhost:5432/dbname"

# Example: API Keys
# export STRIPE_API_KEY="sk_test_xxxxxxxxxxxxxxxxxxxx"
# export SENDGRID_API_KEY="SG.xxxxxxxxxxxxxxxxxxxx"

# Example: Other services
# export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/xxxx"
# export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/xxxx"
EOF
        
        echo "✓ Created secrets directory: $secrets_dir"
        echo "  Template created: $secrets_dir/env.template"
        echo "  Copy template to: $secrets_dir/env"
    fi
}

# Check secrets file permissions
check_secrets_permissions() {
    local secrets_file="$1"
    
    if [[ ! -f "$secrets_file" ]]; then
        return 0
    fi
    
    # Get file permissions (cross-platform)
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS
        local perms=$(stat -f "%Lp" "$secrets_file")
    else
        # Linux
        local perms=$(stat -c "%a" "$secrets_file")
    fi
    
    # Check if file is readable by others
    if [[ "$perms" -gt 600 ]]; then
        echo "⚠ WARNING: Secrets file has permissive permissions: $secrets_file"
        echo "  Current: $perms (should be 600)"
        echo "  Run: chmod 600 $secrets_file"
    fi
}

# Show loaded secrets (names only, not values!)
show_loaded_secrets() {
    echo "Loaded secret environment variables:"
    env | grep -E '^(GITHUB|AWS|OPENAI|ANTHROPIC|DOCKER|NPM|API|TOKEN|KEY|SECRET|PASSWORD)' | cut -d= -f1 | sort
}

# =============================================================================
# Main Loading Logic
# =============================================================================

# Load secrets using the first available method
load_secrets() {
    # Try password managers first (more secure)
    load_secrets_from_1password && return 0
    load_secrets_from_pass && return 0
    load_secrets_from_keychain_macos && return 0
    load_secrets_from_libsecret && return 0
    
    # Fall back to file-based secrets
    load_secrets_from_file
}

# =============================================================================
# Auto-load on shell start
# =============================================================================
# Only load if not already loaded (check for marker variable)

if [[ -z "$SECRETS_LOADED" ]]; then
    load_secrets
    export SECRETS_LOADED=1
    
    # Check permissions on secrets files
    for file in "$SECRETS_FILE_XDG" "$SECRETS_FILE_HOME" "$SECRETS_FILE_LEGACY"; do
        check_secrets_permissions "$file"
    done
fi

# =============================================================================
# Usage Examples
# =============================================================================
# 1. Create secrets directory: init_secrets_dir
# 2. Edit secrets file: $EDITOR $XDG_CONFIG_HOME/secrets/env
# 3. Add your secrets in format: export VAR_NAME="value"
# 4. Restart shell to load secrets
# 5. Check loaded secrets: show_loaded_secrets

