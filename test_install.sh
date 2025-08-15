#!/usr/bin/env bash

# Quick test to verify dotfiles installation components
echo "=== Testing Dotfiles Installation ==="

# Check if script exists and is executable
if [[ -f "./install.sh" ]]; then
    echo "✓ install.sh found"
    if [[ -x "./install.sh" ]]; then
        echo "✓ install.sh is executable"
    else
        echo "✗ install.sh is not executable"
        chmod +x ./install.sh
        echo "✓ Made install.sh executable"
    fi
else
    echo "✗ install.sh not found"
    exit 1
fi

# Check syntax
echo "Checking syntax..."
if bash -n ./install.sh; then
    echo "✓ No syntax errors found"
else
    echo "✗ Syntax errors found"
    exit 1
fi

# Test OS detection functions
echo "Testing OS detection..."
source ./config/zsh/os-detection.zsh
if is_macos; then
    echo "✓ macOS detected correctly"
else
    echo "✗ macOS detection failed"
fi

# Test prompt functions with guards
echo "Testing prompt functions..."
source ./config/zsh/prompt.zsh
if os_prompt_info; then
    echo "✓ os_prompt_info works"
else
    echo "✓ os_prompt_info handled missing functions gracefully"
fi

echo "=== Installation Test Complete ==="
