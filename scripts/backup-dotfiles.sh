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
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

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
            BACKUP_DIR="$2"
            shift 2
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
    info "Creating dotfiles backup..."
    info "Backup location: $BACKUP_DIR"
    echo
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Counter for backed up files
    local backed_up=0
    local skipped=0
    
    # Files to backup (single files in home directory)
    local files=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
    )
    
    # Backup individual files
    for file in "${files[@]}"; do
        if [[ -f "$file" ]] || [[ -L "$file" ]]; then
            if [[ "$VERBOSE" == true ]]; then
                info "Backing up: $file"
            fi
            # Use -L to follow symlinks and backup the actual file
            if cp -L "$file" "$BACKUP_DIR/" 2>/dev/null; then
                ((backed_up++))
            else
                ((skipped++))
            fi
        else
            if [[ "$VERBOSE" == true ]]; then
                warning "Skipping (not found): $file"
            fi
            ((skipped++))
        fi
    done
    
    # Directories to backup
    local dirs=(
        "$HOME/.config/zsh"
        "$HOME/.config/nvim"
        "$HOME/.config/git"
    )
    
    # Backup directories
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            if [[ "$VERBOSE" == true ]]; then
                info "Backing up directory: $dir"
            fi
            mkdir -p "$BACKUP_DIR/config"
            # Use -L to follow symlinks
            if cp -rL "$dir" "$BACKUP_DIR/config/" 2>/dev/null; then
                ((backed_up++))
            else
                ((skipped++))
            fi
        else
            if [[ "$VERBOSE" == true ]]; then
                warning "Skipping (not found): $dir"
            fi
            ((skipped++))
        fi
    done
    
    # Create a backup manifest
    cat > "$BACKUP_DIR/MANIFEST.txt" << EOF
Dotfiles Backup Manifest
========================

Backup Date: $(date)
Hostname: $(hostname)
User: $(whoami)
OS: $(uname -s) $(uname -r)
Backed Up: $backed_up items
Skipped: $skipped items

Dotfiles Repository:
  Location: $DOTFILES_DIR
  Git Commit: $(cd "$DOTFILES_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "Not a git repo")
  Git Branch: $(cd "$DOTFILES_DIR" && git branch --show-current 2>/dev/null || echo "N/A")

Restoration:
  To restore this backup, run:
    cp -r $BACKUP_DIR/* ~/

  Or manually copy specific files as needed.

Files Backed Up:
$(find "$BACKUP_DIR" -type f ! -name "MANIFEST.txt" | sed "s|$BACKUP_DIR|  -|")

EOF
    
    echo
    success "Backup complete!"
    echo
    info "Location: $BACKUP_DIR"
    info "Backed up: $backed_up items"
    info "Skipped: $skipped items"
    echo
    info "To restore: cp -r $BACKUP_DIR/* ~/"
    info "View manifest: cat $BACKUP_DIR/MANIFEST.txt"
    
    # Show backup size
    if command -v du &> /dev/null; then
        local size
        if [[ "$(uname -s)" == "Darwin" ]]; then
            size=$(du -sh "$BACKUP_DIR" | awk '{print $1}')
        else
            size=$(du -sh "$BACKUP_DIR" | awk '{print $1}')
        fi
        info "Backup size: $size"
    fi
}

# Run main function
main

exit 0

