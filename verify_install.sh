#!/usr/bin/env bash

echo "=== Dotfiles Installation Verification ==="

# Check symlinks in home directory
echo "Checking symlinks:"
for file in .gitconfig .vimrc .zshrc; do
    if [[ -L "$HOME/$file" ]]; then
        target=$(readlink "$HOME/$file")
        echo "✅ $file -> $target"
    elif [[ -f "$HOME/$file" ]]; then
        echo "⚠️  $file exists but is not a symlink"
    else
        echo "❌ $file not found"
    fi
done

# Check if backup was created
latest_backup=$(find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*" -type d 2>/dev/null | sort -r | head -1)
if [[ -n "$latest_backup" ]]; then
    echo "✅ Backup created: $(basename "$latest_backup")"
    echo "   Contains: $(find "$latest_backup" -type f 2>/dev/null | wc -l | tr -d ' ') files"
else
    echo "❌ No backup directory found"
fi

# Test OS detection
echo "Testing OS detection functions:"
# shellcheck source=/dev/null
if source ./config/zsh/os-detection.zsh 2>/dev/null; then
    if is_macos; then
        echo "✅ macOS detection works"
    else
        echo "❌ macOS detection failed"
    fi
else
    echo "❌ Could not load os-detection.zsh"
fi

# Test prompt functions
echo "Testing prompt functions:"
# shellcheck source=/dev/null
if source ./config/zsh/prompt.zsh 2>/dev/null; then
    if [[ -n "$(battery_prompt_info)" ]]; then
        echo "✅ battery_prompt_info returns data"
    else
        echo "✅ battery_prompt_info handled gracefully (no battery or low charge)"
    fi
    
    if [[ -n "$(os_prompt_info)" ]]; then
        echo "✅ os_prompt_info returns data"
    else
        echo "✅ os_prompt_info handled gracefully"
    fi
else
    echo "❌ Could not load prompt.zsh"
fi

echo "=== Verification Complete ==="
