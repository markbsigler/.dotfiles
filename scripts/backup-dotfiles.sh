#!/usr/bin/env bash
# Backup current dotfiles before updates
# Cross-platform backup script for macOS and Linux

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
declare -a backup_paths
source "$SCRIPT_DIR/lib/backup.sh"
DRY_RUN=false

# Logging functions
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }

# Show help
show_help() {
    cat << EOF
Dotfiles Backup Script - Cross-Platform

Creates a timestamped backup of your current dotfiles configuration.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --dir DIR       Specify backup directory (default: ~/.dotfiles-backup-TIMESTAMP)
    -v, --verbose       Verbose output
    --dry-run          Preview without writing files

Symlinks are preserved, not dereferenced. Back up their targets separately.

BACKED UP FILES:
    - ~/.zshrc, ~/.zshenv, ~/.zprofile
    - ~/.gitconfig
    - ~/.vimrc
    - ~/.config/zsh/ directory
    - ~/.config/nvim/ directory
    - ~/.config/git/ directory

EXAMPLES:
    $0                          # Create backup with timestamp
    $0 --dir ~/my-backup        # Backup to specific directory
    $0 --verbose                # Show detailed output

EOF
}

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            BACKUP_DIR="${2:?Missing backup directory}"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main backup function
main() {
    local relative
    if [[ "$DRY_RUN" == true ]]; then
        printf 'Would create backup: %s\n' "$BACKUP_DIR"
        printf '  %s\n' "${backup_paths[@]}"
        return 0
    fi
    backup_init "$BACKUP_DIR"
    for relative in "${backup_paths[@]}"; do
        if [[ "$VERBOSE" == true ]]; then info "Checking: $relative"; fi
        backup_save "$BACKUP_DIR" "$relative"
    done
    printf '%s\n' complete > "$BACKUP_DIR/COMPLETE"
    success "Backup complete: $BACKUP_DIR"
    printf 'Restore with: bash %q --backup %q --yes\n' "$SCRIPT_DIR/restore-dotfiles.sh" "$BACKUP_DIR"
}

# Run main function
main

exit 0

