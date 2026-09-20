#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/lib/backup.sh"
BACKUP_DIR=""
DRY_RUN=false
CONFIRMED=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup) BACKUP_DIR="${2:?Missing backup directory}"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --yes) CONFIRMED=true; shift ;;
        -h|--help) printf 'Usage: %s --backup DIRECTORY [--dry-run | --yes]\n' "$0"; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done

[[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" && ! -L "$BACKUP_DIR" ]] || { printf 'Select a real backup directory.\n' >&2; exit 1; }
BACKUP_DIR="$(cd "$BACKUP_DIR" && pwd -P)"
for metadata in FORMAT paths COMPLETE; do
    [[ -f "$BACKUP_DIR/$metadata" && ! -L "$BACKUP_DIR/$metadata" ]] || { printf 'Incomplete or unsafe backup.\n' >&2; exit 1; }
done
[[ -d "$BACKUP_DIR/home" && ! -L "$BACKUP_DIR/home" ]] || { printf 'Unsafe backup payload.\n' >&2; exit 1; }
[[ "$(< "$BACKUP_DIR/COMPLETE")" == complete ]] || { printf 'Incomplete backup.\n' >&2; exit 1; }
[[ "$(< "$BACKUP_DIR/FORMAT")" == dotfiles-backup-v1 ]] || { printf 'Unsupported backup format; restore legacy backups manually.\n' >&2; exit 1; }

while IFS= read -r relative || [[ -n "$relative" ]]; do
    backup_allowed_path "$relative"
    backup_safe_parent "$relative"
    [[ -e "$BACKUP_DIR/home/$relative" || -L "$BACKUP_DIR/home/$relative" ]] || { printf 'Missing backup entry: %s\n' "$relative" >&2; exit 1; }
    (HOME="$BACKUP_DIR/home"; backup_safe_parent "$relative")
    case "$BACKUP_DIR/" in "$HOME/$relative/"*) printf 'Backup is inside a restore target.\n' >&2; exit 1 ;; esac
done < "$BACKUP_DIR/paths"

if [[ "$DRY_RUN" == true ]]; then
    printf 'Would restore these home-relative paths from %s:\n' "$BACKUP_DIR"
    cat "$BACKUP_DIR/paths"
    exit 0
fi
[[ "$CONFIRMED" == true ]] || { printf 'Review with --dry-run, then use --yes to restore.\n' >&2; exit 2; }

RECOVERY_DIR="$HOME/.dotfiles-backup-before-restore-$(date +%Y%m%d-%H%M%S)-$$"
backup_init "$RECOVERY_DIR"
while IFS= read -r relative || [[ -n "$relative" ]]; do
    backup_save "$RECOVERY_DIR" "$relative"
done < "$BACKUP_DIR/paths"
printf '%s\n' complete > "$RECOVERY_DIR/COMPLETE"
printf 'Pre-restore recovery: %s\n' "$RECOVERY_DIR"

STAGING=""
trap '[[ -z "$STAGING" ]] || rm -rf "$STAGING"' EXIT
while IFS= read -r relative || [[ -n "$relative" ]]; do
    target="$HOME/$relative"
    mkdir -p "$(dirname "$target")"
    STAGING="$(mktemp -d "$(dirname "$target")/.dotfiles-restore.XXXXXX")"
    cp -pPR "$BACKUP_DIR/home/$relative" "$STAGING/replacement"
    if [[ -e "$target" || -L "$target" ]]; then
        mv "$target" "$STAGING/previous"
    fi
    if ! mv "$STAGING/replacement" "$target"; then
        if [[ -e "$STAGING/previous" || -L "$STAGING/previous" ]]; then
            mv "$STAGING/previous" "$target" || { printf 'Recovery retained at %s\n' "$STAGING" >&2; STAGING=""; exit 1; }
        fi
        exit 1
    fi
    rm -rf "$STAGING"
    STAGING=""
done < "$BACKUP_DIR/paths"
printf 'Restore complete. Previous files: %s\n' "$RECOVERY_DIR"