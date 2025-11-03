#!/usr/bin/env bash
# Setup pre-commit hooks for dotfiles repository

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo -e "${GREEN}Setting up pre-commit hooks...${NC}"

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo -e "${YELLOW}Installing pre-commit...${NC}"
    
    # Try pip3 first, then pip
    if command -v pip3 &> /dev/null; then
        pip3 install --user pre-commit
    elif command -v pip &> /dev/null; then
        pip install --user pre-commit
    else
        echo "❌ Error: pip not found. Please install Python and pip first."
        exit 1
    fi
fi

# Navigate to dotfiles directory
cd ~/.dotfiles || exit 1

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
pre-commit install

# Run once to download and cache hook environments
echo "Running initial pre-commit check..."
pre-commit run --all-files || true

echo -e "${GREEN}✅ Pre-commit hooks installed successfully!${NC}"
echo ""
echo "Hooks will now run automatically on 'git commit'"
echo "To run manually: pre-commit run --all-files"
echo "To skip hooks (not recommended): git commit --no-verify"

