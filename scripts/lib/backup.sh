#!/usr/bin/env bash

backup_paths=(
    .zshrc .zshenv .zprofile .gitconfig .vimrc
    .config/zsh .config/nvim .config/git .config/mcpm/servers.json
    .local/bin/mcpm-atlassian-secure
)

backup_allowed_path() {
    local candidate
    for candidate in "${backup_paths[@]}"; do
        [[ "$1" != "$candidate" ]] || return 0
    done
    printf 'Unsupported backup path: %s\n' "$1" >&2
    return 1
}

backup_safe_parent() {
    local relative="$1" parent="$HOME" component
    while [[ "$relative" == */* ]]; do
        component="${relative%%/*}"
        relative="${relative#*/}"
        parent="$parent/$component"
        if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
            printf 'Unsafe parent path: %s\n' "$parent" >&2
            return 1
        fi
    done
}

backup_init() {
    local directory="$1"
    (umask 077; mkdir -m 700 "$directory" && mkdir "$directory/home" &&
        printf '%s\n' dotfiles-backup-v1 > "$directory/FORMAT" &&
        : > "$directory/paths")
}

backup_save() {
    local directory="$1" relative="$2"
    backup_allowed_path "$relative" || return 1
    backup_safe_parent "$relative" || return 1
    if [[ -e "$HOME/$relative" || -L "$HOME/$relative" ]]; then
        [[ ! -e "$directory/home/$relative" && ! -L "$directory/home/$relative" ]] || return 0
        (umask 077; mkdir -p "$(dirname "$directory/home/$relative")" &&
            cp -pPR "$HOME/$relative" "$directory/home/$relative" &&
            printf '%s\n' "$relative" >> "$directory/paths") || return 1
    fi
}