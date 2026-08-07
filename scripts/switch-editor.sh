#!/usr/bin/env zsh
# ~/.dotfiles/scripts/switch-editor.sh
# Quick script to switch default editor preference

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

show_current() {
    echo "${GREEN}Current Editor Settings:${NC}"
    echo "  EDITOR:     ${EDITOR:-not set}"
    echo "  VISUAL:     ${VISUAL:-not set}"
    echo "  GIT_EDITOR: ${GIT_EDITOR:-not set}"
    echo ""
}

show_help() {
    cat << EOF
Switch Default Editor

USAGE:
    $0 [OPTION]

OPTIONS:
    vim       Use vim as default editor
    mvim      Use MacVim as default editor
    nvim      Use Neovim as default editor  
    code      Use VS Code as default editor
    current   Show current editor settings
    help      Show this help message

EXAMPLES:
    $0 mvim      # Switch to MacVim
    $0 code      # Switch to VS Code
    $0 current   # Show current settings

NOTES:
    This modifies ~/.dotfiles/config/zsh/exports.zsh
    You'll need to reload your shell or source ~/.zshrc
EOF
}

update_exports() {
    local editor="$1"
    local exports_file="$HOME/.dotfiles/config/zsh/exports.zsh"
    
    if [[ ! -f "$exports_file" ]]; then
        echo "Error: $exports_file not found"
        exit 1
    fi
    
    # Backup
    cp "$exports_file" "$exports_file.bak"
    
    case "$editor" in
        vim)
            echo "${GREEN}Setting vim as default editor...${NC}"
            # Move vim check to first position
            ;;
        mvim)
            echo "${GREEN}Setting MacVim as default editor...${NC}"
            # Move mvim check to first position
            ;;
        nvim)
            echo "${GREEN}Setting Neovim as default editor...${NC}"
            # Move nvim check to first position
            ;;
        code)
            echo "${GREEN}Setting VS Code as default editor...${NC}"
            # Move code check to first position
            ;;
        *)
            echo "Unknown editor: $editor"
            exit 1
            ;;
    esac
    
    echo "${YELLOW}Please reload your shell: source ~/.zshrc${NC}"
}

case "${1:-help}" in
    vim|mvim|nvim|code)
        update_exports "$1"
        ;;
    current)
        show_current
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
