#!/usr/bin/env zsh
# ~/.dotfiles/scripts/switch-editor.sh
# Quick script to switch default editor preference

set -euo pipefail
readonly SCRIPT_DIR="${0:A:h}"

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
    This saves a machine-local preference in ~/.dotfiles/local/editor.zsh
    You'll need to reload your shell or source ~/.zshrc
EOF
}

update_exports() {
    local editor="$1"
    local editor_command visual_command
    case "$editor" in
        vim)
            editor_command=vim visual_command=vim
            ;;
        mvim)
            editor_command='mvim -v' visual_command=mvim
            ;;
        nvim)
            editor_command=nvim visual_command=nvim
            ;;
        code)
            editor_command='code --wait' visual_command='code --wait'
            ;;
        *)
            echo "Unknown editor: $editor"
            exit 1
            ;;
    esac
    if ! command -v "$editor" >/dev/null 2>&1; then
        echo "Editor is not installed: $editor" >&2
        return 1
    fi

    local repo_dir="${SCRIPT_DIR:h}" preference temporary
    preference="$repo_dir/local/editor.zsh"
    [[ -d "$repo_dir/local" && ! -L "$repo_dir/local" ]] || { echo "Unsafe local config directory" >&2; return 1; }
    umask 077
    temporary=$(mktemp "$preference.XXXXXX")
    if ! printf 'export EDITOR=%q\nexport VISUAL=%q\nexport GIT_EDITOR=%q\n' \
        "$editor_command" "$visual_command" "$editor_command" > "$temporary"; then
        rm -f -- "$temporary"
        return 1
    fi
    mv -f -- "$temporary" "$preference"
    echo "${GREEN}Setting $editor as default editor...${NC}"
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
