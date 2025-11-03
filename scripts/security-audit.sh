#!/usr/bin/env bash
# Security audit script for dotfiles repository
# Checks for potential security issues

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Counters
WARNINGS=0
ERRORS=0
CHECKS=0

# Logging functions
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $*${NC}"; ((WARNINGS++)); }
error() { echo -e "${RED}❌ $*${NC}"; ((ERRORS++)); }

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🔒 Security Audit Report 🔒       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Change to dotfiles directory
cd ~/.dotfiles || exit 1

# ============================================================================
# Check 1: Hard-coded Secrets
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}1. Checking for potential hard-coded secrets...${NC}"

if command -v rg &> /dev/null; then
    # Use ripgrep if available
    if rg -i '(password|secret|api[_-]?key|token|credentials|auth).*=.*["'\''`][^"'\''`]{8,}["'\''`]' . \
       --glob '!*.md' \
       --glob '!*audit*' \
       --glob '!SECRETS.md' \
       --glob '!CUSTOMIZATION.md' \
       --glob '!*.template' \
       --glob '!.git/**' \
       2>/dev/null; then
        warning "Found potential hard-coded secrets"
        echo "   Review the matches above and ensure no real secrets are committed"
    else
        success "No hard-coded secrets found"
    fi
else
    # Fallback to grep
    if grep -ri 'password\|secret\|api_key\|token' . \
       --exclude='*.md' \
       --exclude='*audit*' \
       --exclude-dir='.git' 2>/dev/null | grep -v '^\s*#' | head -5; then
        warning "Found potential hard-coded secrets (install ripgrep for better detection)"
    else
        success "No hard-coded secrets found"
    fi
fi

# ============================================================================
# Check 2: File Permissions
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}2. Checking file permissions...${NC}"

# Find world-writable files
world_writable=$(find . -type f -perm -002 2>/dev/null | grep -v ".git" || true)
if [[ -n "$world_writable" ]]; then
    warning "Found world-writable files:"
    echo "$world_writable"
    echo "   Run: chmod 644 <filename> to fix"
else
    success "No world-writable files found"
fi

# Check scripts are executable
non_executable_scripts=$(find scripts -type f -name "*.sh" ! -perm -100 2>/dev/null || true)
if [[ -n "$non_executable_scripts" ]]; then
    warning "Found non-executable scripts:"
    echo "$non_executable_scripts"
    echo "   Run: chmod +x <filename> to fix"
else
    success "All scripts are executable"
fi

# ============================================================================
# Check 3: .env Files
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}3. Checking for .env files...${NC}"

env_files=$(find . -name ".env*" -type f 2>/dev/null | grep -v ".gitignore" || true)
if [[ -n "$env_files" ]]; then
    warning "Found .env files (ensure they're in .gitignore):"
    echo "$env_files"
    
    # Check if they're in .gitignore
    for file in $env_files; do
        filename=$(basename "$file")
        if ! grep -q "$filename" .gitignore 2>/dev/null; then
            error "  $filename is NOT in .gitignore!"
        fi
    done
else
    success "No .env files found"
fi

# ============================================================================
# Check 4: .gitignore Coverage
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}4. Checking .gitignore coverage for sensitive files...${NC}"

sensitive_patterns=(
    "*.key"
    "*.pem"
    "*.p12"
    "*.pfx"
    "*secret*"
    "*.env"
    ".secrets/"
    "credentials"
)

missing=()
for pattern in "${sensitive_patterns[@]}"; do
    if ! grep -q "$pattern" .gitignore 2>/dev/null; then
        missing+=("$pattern")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    warning "Missing patterns in .gitignore:"
    printf '   - %s\n' "${missing[@]}"
    echo "   Consider adding these patterns to .gitignore"
else
    success ".gitignore covers all sensitive file patterns"
fi

# ============================================================================
# Check 5: SSH Configuration
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}5. Checking SSH configuration...${NC}"

if [[ -d ~/.ssh ]]; then
    # Check .ssh directory permissions
    ssh_perms=$(stat -f %A ~/.ssh 2>/dev/null || stat -c %a ~/.ssh 2>/dev/null)
    if [[ "$ssh_perms" == "700" ]]; then
        success "~/.ssh has correct permissions (700)"
    else
        warning "~/.ssh should have 700 permissions (current: $ssh_perms)"
        echo "   Run: chmod 700 ~/.ssh"
    fi
    
    # Check private key permissions
    if find ~/.ssh -name "id_*" -not -name "*.pub" -type f 2>/dev/null | head -1 > /dev/null; then
        bad_key_perms=$(find ~/.ssh -name "id_*" -not -name "*.pub" -type f ! -perm 600 2>/dev/null || true)
        if [[ -n "$bad_key_perms" ]]; then
            warning "Found private keys with incorrect permissions:"
            echo "$bad_key_perms"
            echo "   Run: chmod 600 <keyfile>"
        else
            success "All private SSH keys have correct permissions (600)"
        fi
    fi
    
    # Check SSH config permissions
    if [[ -f ~/.ssh/config ]]; then
        config_perms=$(stat -f %A ~/.ssh/config 2>/dev/null || stat -c %a ~/.ssh/config 2>/dev/null)
        if [[ "$config_perms" == "600" ]]; then
            success "~/.ssh/config has correct permissions (600)"
        else
            warning "~/.ssh/config should have 600 permissions (current: $config_perms)"
            echo "   Run: chmod 600 ~/.ssh/config"
        fi
    fi
else
    info "~/.ssh directory not found (not necessarily a problem)"
fi

# ============================================================================
# Check 6: Secrets Directory
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}6. Checking secrets directory...${NC}"

if [[ -d ~/.secrets ]]; then
    # Check directory permissions
    secrets_perms=$(stat -f %A ~/.secrets 2>/dev/null || stat -c %a ~/.secrets 2>/dev/null)
    if [[ "$secrets_perms" == "700" ]]; then
        success "~/.secrets has correct permissions (700)"
    else
        warning "~/.secrets should have 700 permissions (current: $secrets_perms)"
        echo "   Run: chmod 700 ~/.secrets"
    fi
    
    # Check file permissions in secrets directory
    if [[ -f ~/.secrets/env ]]; then
        env_perms=$(stat -f %A ~/.secrets/env 2>/dev/null || stat -c %a ~/.secrets/env 2>/dev/null)
        if [[ "$env_perms" == "600" ]]; then
            success "~/.secrets/env has correct permissions (600)"
        else
            warning "~/.secrets/env should have 600 permissions (current: $env_perms)"
            echo "   Run: chmod 600 ~/.secrets/env"
        fi
    fi
    
    # Check if secrets directory is in .gitignore
    if grep -q ".secrets/" .gitignore 2>/dev/null; then
        success ".secrets/ is in .gitignore"
    else
        error ".secrets/ is NOT in .gitignore!"
        echo "   Add '.secrets/' to .gitignore immediately"
    fi
else
    info "~/.secrets directory not found (create with 'mkdir -m 700 ~/.secrets' if needed)"
fi

# ============================================================================
# Check 7: Git Configuration
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}7. Checking git configuration...${NC}"

# Check if using HTTPS with passwords
if git remote get-url origin 2>/dev/null | grep -q "https://"; then
    warning "Using HTTPS for git remote (consider switching to SSH)"
    echo "   See GITHUB_AUTH_SETUP.md for SSH setup instructions"
else
    success "Using SSH for git remote"
fi

# Check for GPG signing
if git config --get user.signingkey &> /dev/null; then
    success "GPG signing is configured"
else
    info "GPG signing not configured (optional but recommended)"
    echo "   See: https://docs.github.com/en/authentication/managing-commit-signature-verification"
fi

# ============================================================================
# Check 8: Public Files in Repository
# ============================================================================

((CHECKS++))
echo -e "\n${BLUE}8. Checking for accidentally tracked sensitive files...${NC}"

# Check git for tracked sensitive files
tracked_sensitive=$(git ls-files | grep -E '\.(key|pem|p12|pfx)$' 2>/dev/null || true)
if [[ -n "$tracked_sensitive" ]]; then
    error "Found sensitive files tracked in git:"
    echo "$tracked_sensitive"
    echo "   Remove with: git rm --cached <filename>"
    echo "   Then add to .gitignore"
else
    success "No sensitive files tracked in git"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Security Audit Summary        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Checks performed: $CHECKS"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Errors: $ERRORS${NC}"
echo ""

if [[ $ERRORS -gt 0 ]]; then
    error "Security audit found $ERRORS critical issues!"
    echo "   Please fix the errors above immediately"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    warning "Security audit found $WARNINGS warnings"
    echo "   Review and address the warnings above"
    exit 0
else
    success "Security audit passed! No issues found 🎉"
    exit 0
fi

