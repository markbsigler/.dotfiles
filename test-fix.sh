#!/usr/bin/env bash

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install a package if it doesn't exist (our fixed version)
install_if_missing() {
    local package="$1"
    local install_cmd="$2"
    local check_cmd="${3:-$package}"
    
    if command_exists "$check_cmd"; then
        info "$package is already installed"
        return 0
    fi
    
    info "Installing $package..."
    
    # Temporarily disable exit on error for the install command
    set +e
    eval "$install_cmd"
    local install_result=$?
    set -e
    
    # Check if the package is now available, regardless of install command exit code
    if command_exists "$check_cmd"; then
        success "$package is available"
        return 0
    else
        error "Failed to install $package (exit code: $install_result)"
        return 1
    fi
}

# Test the fix with coreutils
echo "Testing the fix with coreutils..."
install_if_missing "coreutils" "brew install coreutils"

echo "Test completed!"
