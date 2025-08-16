#!/bin/bash
# Simple test script to verify installation

echo "=== Dotfiles Installation Check ==="
echo "Current directory: $(pwd)"
echo ""

echo "=== Checking home directory dotfiles ==="
ls -la ~/.zshenv ~/.zprofile ~/.zshrc 2>/dev/null || echo "Files not found"
echo ""

echo "=== Checking source files ==="
ls -la /Users/msigler/.dotfiles/.zshenv /Users/msigler/.dotfiles/.zprofile /Users/msigler/.dotfiles/.zshrc 2>/dev/null || echo "Source files not found"
echo ""

echo "=== Creating symlinks manually ==="
ln -sf /Users/msigler/.dotfiles/.zshenv ~/.zshenv
ln -sf /Users/msigler/.dotfiles/.zprofile ~/.zprofile  
ln -sf /Users/msigler/.dotfiles/.zshrc ~/.zshrc

echo "=== Verifying symlinks ==="
ls -la ~/.zshenv ~/.zprofile ~/.zshrc

echo ""
echo "=== Test complete - now open a new Terminal.app window ==="
echo "The .zshrc should now be sourced automatically via .zprofile"
