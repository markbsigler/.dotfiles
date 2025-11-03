#!/usr/bin/env bash
# =============================================================================
# Backup Dotfiles - Cross-Platform Backup Script
# =============================================================================
# Creates timestamped backups of dotfiles before updates or changes
# Supports: macOS and Linux
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup-$BACKUP_TIMESTAMP}"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# What to backup
declare -a FILES_TO_BACKUP=(
    "$HOME/.zshenv"
    "$HOME/.zprofile"
    "$HOME/.zshrc"
    "$HOME/.zsh_history"
    "$HOME/.gitconfig"
    "$HOME/.vimrc"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.profile"
)

declare -a DIRS_TO_BACKUP=(
    "$HOME/.config/zsh"
    "$HOME/.config/git"
    "$HOME/.config/nvim"
    "$HOME/.vim"
    "$HOME/.ssh/config"
)

# Flags
DRY_RUN=false
VERBOSE=false
COMPRESS=false
INCLUDE_HISTORY=false

# =============================================================================
# Logging Functions
# =============================================================================

info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

error() {
    echo -e "${RED}❌ $*${NC}"
}

section() {
    echo -e "\n${CYAN}▶ $*${NC}\n"
}

# =============================================================================
# Backup Functions
# =============================================================================

backup_file() {
    local source="$1"
    local dest="$2"
    
    if [[ ! -e "$source" ]] && [[ ! -L "$source" ]]; then
        [[ "$VERBOSE" == true ]] && info "Skipping (not found): $source"
        return 0
    fi
    
    # Create destination directory
    local dest_dir=$(dirname "$dest")
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dest_dir"
    fi
    
    # Check if it's a symlink
    if [[ -L "$source" ]]; then
        # For symlinks, follow them and backup the target
        if [[ "$DRY_RUN" == false ]]; then
            cp -rL "$source" "$dest" 2>/dev/null || warning "Failed to backup: $source"
        fi
        info "Backed up (symlink): $(basename "$source")"
    elif [[ -f "$source" ]]; then
        # Regular file
        if [[ "$DRY_RUN" == false ]]; then
            cp "$source" "$dest"
        fi
        info "Backed up (file): $(basename "$source")"
    elif [[ -d "$source" ]]; then
        # Directory
        if [[ "$DRY_RUN" == false ]]; then
            cp -r "$source" "$dest"
        fi
        info "Backed up (dir): $(basename "$source")"
    fi
}

backup_dotfiles() {
    section "Backing up dotfiles"
    
    # Create backup directory
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        chmod 700 "$BACKUP_DIR"  # Owner only
    else
        info "Would create backup directory: $BACKUP_DIR"
    fi
    
    # Backup individual files
    for file in "${FILES_TO_BACKUP[@]}"; do
        if [[ -e "$file" ]] || [[ -L "$file" ]]; then
            local filename=$(basename "$file")
            backup_file "$file" "$BACKUP_DIR/$filename"
        fi
    done
    
    # Backup directories
    for dir in "${DIRS_TO_BACKUP[@]}"; do
        if [[ -e "$dir" ]] || [[ -L "$dir" ]]; then
            local dirname=$(basename "$dir")
            local parent=$(basename "$(dirname "$dir")")
            
            # Preserve directory structure
            if [[ "$parent" == ".config" ]]; then
                backup_file "$dir" "$BACKUP_DIR/config/$dirname"
            else
                backup_file "$dir" "$BACKUP_DIR/$dirname"
            fi
        fi
    done
}

backup_git_state() {
    section "Backing up git repository state"
    
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        warning "Dotfiles directory is not a git repository"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would backup git state"
        return 0
    fi
    
    local git_backup_dir="$BACKUP_DIR/git-state"
    mkdir -p "$git_backup_dir"
    
    (
        cd "$DOTFILES_DIR"
        
        # Save current branch
        git branch --show-current > "$git_backup_dir/current-branch.txt"
        
        # Save commit hash
        git rev-parse HEAD > "$git_backup_dir/commit-hash.txt"
        
        # Save status
        git status --porcelain > "$git_backup_dir/status.txt"
        
        # Save diff of uncommitted changes
        if [[ -n "$(git status --porcelain)" ]]; then
            git diff > "$git_backup_dir/uncommitted-changes.diff"
            git diff --cached > "$git_backup_dir/staged-changes.diff"
        fi
        
        # Save list of remotes
        git remote -v > "$git_backup_dir/remotes.txt"
        
        info "Git state backed up"
    )
}

backup_shell_history() {
    if [[ "$INCLUDE_HISTORY" == false ]]; then
        return 0
    fi
    
    section "Backing up shell history"
    
    local history_files=(
        "$HOME/.zsh_history"
        "$XDG_DATA_HOME/zsh/history"
        "$HOME/.bash_history"
    )
    
    for hist_file in "${history_files[@]}"; do
        if [[ -f "$hist_file" ]]; then
            backup_file "$hist_file" "$BACKUP_DIR/history/$(basename "$hist_file")"
        fi
    done
}

create_manifest() {
    section "Creating backup manifest"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would create manifest"
        return 0
    fi
    
    local manifest="$BACKUP_DIR/MANIFEST.txt"
    
    cat > "$manifest" << EOF
Dotfiles Backup Manifest
=============================================================================
Created: $(date)
Hostname: $(hostname)
User: $(whoami)
OS: $(uname -s)
Backup Directory: $BACKUP_DIR
Dotfiles Directory: $DOTFILES_DIR

Files Backed Up:
-----------------------------------------------------------------------------
EOF
    
    # List all files in backup
    find "$BACKUP_DIR" -type f | sed "s|$BACKUP_DIR/||" | sort >> "$manifest"
    
    # Add sizes
    echo "" >> "$manifest"
    echo "Backup Size:" >> "$manifest"
    echo "-----------------------------------------------------------------------------" >> "$manifest"
    du -sh "$BACKUP_DIR" >> "$manifest"
    
    info "Manifest created: $manifest"
}

compress_backup() {
    if [[ "$COMPRESS" == false ]]; then
        return 0
    fi
    
    section "Compressing backup"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would compress backup"
        return 0
    fi
    
    local archive="$BACKUP_DIR.tar.gz"
    
    info "Creating archive: $archive"
    tar -czf "$archive" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
    
    # Remove uncompressed backup
    rm -rf "$BACKUP_DIR"
    
    success "Backup compressed: $archive"
    info "Size: $(du -sh "$archive" | cut -f1)"
}

cleanup_old_backups() {
    section "Cleaning up old backups"
    
    local days="${1:-30}"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would remove backups older than $days days"
        return 0
    fi
    
    info "Removing backups older than $days days..."
    
    # Find and remove old backup directories
    find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*" -type d -mtime +"$days" -exec rm -rf {} + 2>/dev/null || true
    
    # Find and remove old backup archives
    find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*.tar.gz" -type f -mtime +"$days" -delete 2>/dev/null || true
    
    success "Old backups cleaned up"
}

# =============================================================================
# Restore Functions
# =============================================================================

list_backups() {
    section "Available Backups"
    
    # List backup directories
    local backups=$(find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*" -type d | sort -r)
    
    # List backup archives
    local archives=$(find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*.tar.gz" -type f | sort -r)
    
    if [[ -z "$backups" ]] && [[ -z "$archives" ]]; then
        warning "No backups found"
        return 0
    fi
    
    echo "Backup Directories:"
    while IFS= read -r backup; do
        if [[ -n "$backup" ]]; then
            local size=$(du -sh "$backup" 2>/dev/null | cut -f1)
            local date=$(basename "$backup" | sed 's/.dotfiles-backup-//')
            echo "  $date ($size)"
        fi
    done <<< "$backups"
    
    echo ""
    echo "Backup Archives:"
    while IFS= read -r archive; do
        if [[ -n "$archive" ]]; then
            local size=$(du -sh "$archive" 2>/dev/null | cut -f1)
            local date=$(basename "$archive" | sed 's/.dotfiles-backup-//;s/.tar.gz//')
            echo "  $date ($size)"
        fi
    done <<< "$archives"
}

# =============================================================================
# Help Function
# =============================================================================

show_help() {
    cat << EOF
Backup Dotfiles - Cross-Platform Backup Script

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    backup              Create a new backup (default)
    list                List available backups
    cleanup [days]      Remove backups older than N days (default: 30)

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be done without doing it
    -v, --verbose       Verbose output
    -c, --compress      Compress backup into tar.gz archive
    --include-history   Include shell history files
    --backup-dir DIR    Custom backup directory location

EXAMPLES:
    $0                              # Create backup
    $0 --compress                   # Create compressed backup
    $0 --dry-run                    # Preview backup
    $0 list                         # List all backups
    $0 cleanup 7                    # Remove backups older than 7 days

WHAT GETS BACKED UP:
    Files:
    - Shell configs (.zshrc, .zshenv, .zprofile, .bashrc, etc.)
    - Git config (.gitconfig)
    - Vim/Neovim configs
    
    Directories:
    - ~/.config/zsh
    - ~/.config/git
    - ~/.config/nvim
    - ~/.vim
    - ~/.ssh/config (permissions preserved)
    
    Optional (--include-history):
    - Shell history files

BACKUP LOCATION:
    $HOME/.dotfiles-backup-YYYYMMDD-HHMMSS/

FEATURES:
    - Timestamped backups
    - Follows symlinks
    - Preserves permissions
    - Creates manifest
    - Optional compression
    - Automatic cleanup
    - Git state snapshot

EOF
}

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
    local command="backup"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--compress)
                COMPRESS=true
                shift
                ;;
            --include-history)
                INCLUDE_HISTORY=true
                shift
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            backup|list|cleanup)
                command="$1"
                shift
                # For cleanup, check if there's a number argument
                if [[ "$command" == "cleanup" ]] && [[ $# -gt 0 ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
                    cleanup_old_backups "$1"
                    exit 0
                fi
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        backup)
            return 0
            ;;
        list)
            list_backups
            exit 0
            ;;
        cleanup)
            cleanup_old_backups
            exit 0
            ;;
    esac
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    parse_args "$@"
    
    # Print banner
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    BACKUP DOTFILES                           ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    info "Backup location: $BACKUP_DIR"
    
    # Perform backup
    backup_dotfiles
    backup_git_state
    backup_shell_history
    create_manifest
    compress_backup
    
    # Summary
    echo ""
    success "Backup completed successfully!"
    
    if [[ "$COMPRESS" == true ]]; then
        info "Backup archive: $BACKUP_DIR.tar.gz"
    else
        info "Backup directory: $BACKUP_DIR"
    fi
    
    # Show total size
    if [[ "$DRY_RUN" == false ]]; then
        if [[ "$COMPRESS" == true ]] && [[ -f "$BACKUP_DIR.tar.gz" ]]; then
            info "Total size: $(du -sh "$BACKUP_DIR.tar.gz" | cut -f1)"
        elif [[ -d "$BACKUP_DIR" ]]; then
            info "Total size: $(du -sh "$BACKUP_DIR" | cut -f1)"
        fi
    fi
    
    echo ""
    info "To restore from this backup, copy files from backup directory to your home directory"
    info "To list all backups: $0 list"
    info "To cleanup old backups: $0 cleanup [days]"
}

# Run main function
main "$@"

