#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
exec bash "$DOTFILES_DIR/scripts/backup-dotfiles.sh" "$@"