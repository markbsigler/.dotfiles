#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"

if [[ "${1:-}" != --isolated ]]; then
    TEST_ROOT="$(mktemp -d /tmp/dotfiles-safety.XXXXXX)"
    trap 'rm -rf "$TEST_ROOT"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    mkdir "$TEST_ROOT/home"
    exit_code=0
    env -i HOME="$TEST_ROOT/home" PATH=/usr/bin:/bin:/usr/sbin:/sbin SHELL=/bin/zsh \
        "$BASH" --noprofile --norc "$SCRIPT_DIR/test-safety.sh" --isolated "$TEST_ROOT" || exit_code=$?
    exit "$exit_code"
fi

TEST_ROOT="${2:?Missing temporary root}"
[[ "$TEST_ROOT" == /tmp/dotfiles-safety.* && -d "$TEST_ROOT" && ! -L "$TEST_ROOT" && \
    "$HOME" == "$TEST_ROOT/home" ]] || exit 2
export LC_ALL=C
umask 077
PLATFORM="$(uname -s)"
PASSED=0
FAILED=0

fail() {
    printf 'ASSERTION FAILED: %s\n' "$*" >&2
    exit 1
}

run_script() {
    env -i HOME="$HOME" PATH="$STUB_BIN:/usr/bin:/bin:/usr/sbin:/sbin" SHELL=/bin/bash \
        SAFETY_CALLS="$CASE_DIR/forbidden-calls" \
        "$BASH" --noprofile --norc "$@" < /dev/null
}

expect_failure() {
    local result=0
    "$@" || result=$?
    [[ "$result" -ne 0 ]] || fail "Command unexpectedly succeeded: $*"
}

tree_snapshot() {
    local root="$1" detail="${2:-full}" entry format
    find "$root" -print | LC_ALL=C sort | while IFS= read -r entry; do
        printf 'PATH %s\n' "${entry#"$root"}"
        if [[ "$PLATFORM" == Darwin ]]; then
            format='%p:%m:%c:%i:%z'
            [[ "$detail" == full ]] || format='%p'
            stat -f "$format" "$entry"
        else
            format='%f:%Y:%Z:%i:%s'
            [[ "$detail" == full ]] || format='%f'
            stat -c "$format" "$entry"
        fi
        if [[ -L "$entry" ]]; then
            printf 'LINK %s\n' "$(readlink "$entry")"
        elif [[ -f "$entry" ]]; then
            cksum < "$entry"
            cat "$entry"
            printf '\n'
        elif [[ -d "$entry" ]]; then
            printf 'DIRECTORY\n'
        else
            fail "Unexpected fixture type: $entry"
        fi
    done
}

assert_snapshots_equal() {
    if ! cmp -s "$1" "$2"; then
        diff -u "$1" "$2" || true
        fail "Filesystem changed: ${3:-fixture}"
    fi
}

assert_same_entry() {
    tree_snapshot "$1" portable > "$CASE_DIR/expected"
    tree_snapshot "$2" portable > "$CASE_DIR/actual"
    assert_snapshots_equal "$CASE_DIR/expected" "$CASE_DIR/actual" "$2"
}

assert_unchanged() {
    local root="$1"
    shift
    tree_snapshot "$root" > "$CASE_DIR/before"
    "$@"
    tree_snapshot "$root" > "$CASE_DIR/after"
    assert_snapshots_equal "$CASE_DIR/before" "$CASE_DIR/after" "$root"
}

assert_link() {
    [[ -L "$1" ]] || fail "Not a symlink: $1"
    [[ "$(readlink "$1")" == "$2" ]] || fail "Incorrect link target: $1"
}

new_fixture() {
    FIXTURE="$CASE_DIR/fixture with spaces"
    HOME="$FIXTURE/home with spaces"
    export HOME
    FIXTURE_REPO="$FIXTURE/repo with spaces"
    BACKUP="$FIXTURE/backup with spaces"
    EXTERNAL="$FIXTURE/external with spaces"
    mkdir -p "$HOME" "$EXTERNAL" "$FIXTURE_REPO/scripts/lib" \
        "$FIXTURE_REPO/config/zsh" "$FIXTURE_REPO/config/git" \
        "$FIXTURE_REPO/config/vim" "$FIXTURE_REPO/config/nvim" "$FIXTURE_REPO/config/mcpm"
    FIXTURE_REPO="$(cd "$FIXTURE_REPO" && pwd -P)"
    cp "$REPO_DIR/install.sh" "$FIXTURE_REPO/install.sh"
    cp "$SCRIPT_DIR/lib/backup.sh" "$FIXTURE_REPO/scripts/lib/backup.sh"
    cp "$SCRIPT_DIR/backup-dotfiles.sh" "$SCRIPT_DIR/restore-dotfiles.sh" "$FIXTURE_REPO/scripts/"
    local relative
    for relative in zsh/.zshrc zsh/.zshenv zsh/.zprofile git/gitconfig vim/vimrc nvim/init.vim; do
        printf 'dummy configuration: %s\n' "$relative" > "$FIXTURE_REPO/config/$relative"
    done
    printf '{}\n' > "$FIXTURE_REPO/config/mcpm/servers.json"
    printf 'exit 98\n' > "$FIXTURE_REPO/scripts/mcpm-atlassian-secure.sh"
    printf '*.fixture text\n' > "$FIXTURE_REPO/config/git/attributes"
    printf '*.fixture-ignore\n' > "$FIXTURE_REPO/config/git/ignore"
    STUB_BIN="$CASE_DIR/stub bin"
    mkdir "$STUB_BIN"
    printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$0 $*" >> "$SAFETY_CALLS"' 'exit 98' > "$STUB_BIN/git"
    chmod +x "$STUB_BIN/git"
    local command_name
    for command_name in brew apt apt-get dnf yum pacman zypper apk nix nix-env \
        curl wget vim nvim chsh sudo security pass op ssh scp; do
        cp -p "$STUB_BIN/git" "$STUB_BIN/$command_name"
    done
    cp -p "$STUB_BIN/git" "$FIXTURE_REPO/scripts/install-packages.sh"
    cp -p "$STUB_BIN/git" "$FIXTURE_REPO/scripts/test-dotfiles.sh"
}

populate_home() {
    mkdir -p "$HOME/.config/zsh/nested directory" "$HOME/.config/nvim" \
        "$HOME/.config/git" "$HOME/.config/mcpm" "$HOME/.local/bin" "$EXTERNAL/directory target"
    printf 'external original\n' > "$EXTERNAL/file target"
    printf 'external hidden\n' > "$EXTERNAL/directory target/.hidden"
    ln -s "$EXTERNAL/missing target" "$HOME/.zshrc"
    ln -s "$EXTERNAL/file target" "$HOME/.zshenv"
    printf 'profile original\n' > "$HOME/.zprofile"
    printf 'git original\n' > "$HOME/.gitconfig"
    printf 'git attributes original\n' > "$HOME/.config/git/attributes"
    printf 'git ignore original\n' > "$HOME/.config/git/ignore"
    printf 'vim original\n' > "$HOME/.vimrc"
    printf 'hidden original\n' > "$HOME/.config/zsh/.hidden"
    printf 'spaced original\n' > "$HOME/.config/zsh/nested directory/file with spaces"
    ln -s 'missing nested target' "$HOME/.config/zsh/nested directory/dangling link"
    ln -s "$EXTERNAL/directory target" "$HOME/.config/zsh/directory link"
    printf 'nvim original\n' > "$HOME/.config/nvim/.hidden"
    printf '{}\n' > "$HOME/.config/mcpm/servers.json"
    printf 'cache fixture\n' > "$HOME/.config/mcpm/servers_cache.json"
    printf 'database fixture\n' > "$HOME/.config/mcpm/monitor.db"
    printf 'launcher original\n' > "$HOME/.local/bin/mcpm-atlassian-secure"
    chmod 751 "$HOME/.config/zsh"
    chmod 640 "$HOME/.config/zsh/.hidden"
    chmod 644 "$HOME/.config/mcpm/servers_cache.json" "$HOME/.config/mcpm/monitor.db"
}

make_backup() {
    run_script "$FIXTURE_REPO/scripts/backup-dotfiles.sh" --dir "$BACKUP"
}

restore_backup() {
    run_script "$FIXTURE_REPO/scripts/restore-dotfiles.sh" --backup "$BACKUP" "$@"
}

installer_function() {
    [[ "$(tail -n 1 "$FIXTURE_REPO/install.sh")" == 'main "$@"' ]] || fail 'Installer entry point changed'
    sed '$d' "$FIXTURE_REPO/install.sh" > "$FIXTURE_REPO/install-definitions.sh"
    run_script -c '
        source "$1"
        install_packages() { printf "Unexpected package operation\n" >&2; exit 98; }
        install_vim_plugins() { printf "Unexpected plugin operation\n" >&2; exit 98; }
        setup_zsh() { printf "Unexpected shell operation\n" >&2; exit 98; }
        case "$2" in
            link) create_symlink "$3" "$4" ;;
            failed-ln)
                FORCE="$5"
                ln() { printf "Injected ln failure\n" >&2; return 73; }
                create_symlink "$3" "$4"
                ;;
            update) UPDATE_MODE=true; link_configs ;;
            *) exit 99 ;;
        esac
    ' safety-installer "$FIXTURE_REPO/install-definitions.sh" "$@"
}

test_installer_dry_run() {
    local scenario="$1"
    if [[ "$scenario" != empty ]]; then
        populate_home
        case "$scenario" in
            existing-log)
                printf 'existing install log\n' > "$FIXTURE_REPO/install.log"
                chmod 640 "$FIXTURE_REPO/install.log"
                ;;
            linked-log) ln -s "$EXTERNAL/file target" "$FIXTURE_REPO/install.log" ;;
            dangling-log) ln -s "$EXTERNAL/missing log" "$FIXTURE_REPO/install.log" ;;
        esac
    fi
    assert_unchanged "$FIXTURE" run_script "$FIXTURE_REPO/install.sh" --dry-run
}

test_installer_dry_run_option() {
    populate_home
    assert_unchanged "$FIXTURE" run_script "$FIXTURE_REPO/install.sh" --dry-run "$1"
}

test_installer_test_only() {
    local option="$1" result=0
    populate_home
    printf '#!/bin/sh\nprintf "suite invoked\\n"\nexit %s\n' "$2" > "$FIXTURE_REPO/scripts/test-dotfiles.sh"
    tree_snapshot "$FIXTURE" > "$CASE_DIR/before"
    run_script "$FIXTURE_REPO/install.sh" "$option" > "$CASE_DIR/test-output" || result=$?
    [[ "$result" -eq "$2" ]] || fail "Installer did not propagate test exit $2"
    grep -Fx 'suite invoked' "$CASE_DIR/test-output" >/dev/null || fail 'Installer did not run the suite'
    tree_snapshot "$FIXTURE" > "$CASE_DIR/after"
    assert_snapshots_equal "$CASE_DIR/before" "$CASE_DIR/after" 'test-only installer'
}

test_update_entrypoint() {
    local scenario="$1" link source target relative old_target index=0 backup
    local links=(
        'config/zsh:.config/zsh'
        'config/zsh/.zshrc:.zshrc'
        'config/zsh/.zshenv:.zshenv'
        'config/zsh/.zprofile:.zprofile'
        'config/git/gitconfig:.gitconfig'
        'config/git:.config/git'
        'config/vim/vimrc:.vimrc'
        'config/nvim:.config/nvim'
        'config/mcpm/servers.json:.config/mcpm/servers.json'
        'scripts/mcpm-atlassian-secure.sh:.local/bin/mcpm-atlassian-secure'
    )
    mkdir "$EXTERNAL/old directory"
    printf 'preserve referent\n' > "$EXTERNAL/old file"
    printf 'preserve hidden referent\n' > "$EXTERNAL/old directory/.hidden"
    for link in "${links[@]}"; do
        source="$FIXTURE_REPO/${link%:*}"
        target="$HOME/${link#*:}"
        index=$((index + 1))
        [[ -e "$source" ]] || fail "Incomplete installer fixture: $source"
        [[ "$scenario" != empty ]] || continue
        if [[ "$scenario" == mixed && $((index % 3)) -eq 0 ]]; then continue; fi
        mkdir -p "$(dirname "$target")"
        case "$scenario" in
            real-file) printf 'preserve real file\n' > "$target"; chmod 640 "$target" ;;
            real-directory)
                mkdir "$target"
                printf 'preserve hidden file\n' > "$target/.hidden"
                chmod 751 "$target"
                ;;
            current) ln -s "$source" "$target" ;;
            stale|dangling|mixed)
                if [[ "$scenario" == mixed && $((index % 3)) -eq 2 ]]; then
                    printf 'preserve mixed real file\n' > "$target"
                    continue
                fi
                old_target="$EXTERNAL/old file"
                if [[ -d "$source" ]]; then old_target="$EXTERNAL/old directory"; fi
                if [[ "$scenario" == dangling ]]; then old_target="$EXTERNAL/missing target"; fi
                ln -s "$old_target" "$target"
                ;;
            *) fail "Unknown update scenario: $scenario" ;;
        esac
    done
    if [[ "$scenario" == mixed ]]; then
        mkdir -p "$HOME/.config/mcpm"
        printf 'preserve cache\n' > "$HOME/.config/mcpm/servers_cache.json"
        printf 'preserve database\n' > "$HOME/.config/mcpm/monitor.db"
        chmod 644 "$HOME/.config/mcpm/servers_cache.json" "$HOME/.config/mcpm/monitor.db"
    fi
    case "$scenario" in
        empty|real-file|real-directory|current)
            assert_unchanged "$FIXTURE" run_script "$FIXTURE_REPO/install.sh" --update
            return
            ;;
    esac
    cp -pPR "$HOME" "$CASE_DIR/expected home"
    for link in "${links[@]}"; do
        relative="${link#*:}"
        if [[ -L "$HOME/$relative" ]]; then
            rm "$CASE_DIR/expected home/$relative"
            ln -s "$FIXTURE_REPO/${link%:*}" "$CASE_DIR/expected home/$relative"
        fi
    done
    tree_snapshot "$FIXTURE_REPO" > "$CASE_DIR/repo-before"
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-before"
    run_script "$FIXTURE_REPO/install.sh" --update
    cp -pPR "$HOME" "$CASE_DIR/actual home"
    set -- "$HOME"/.dotfiles-backup-*
    [[ "$#" -eq 1 && -d "$1" && ! -L "$1" ]] || fail 'Expected one update backup'
    backup="$1"
    [[ "$(cat "$backup/COMPLETE")" == complete ]] || fail 'Update backup is incomplete'
    rm -rf "${CASE_DIR:?}/actual home/${backup##*/}"
    assert_same_entry "$CASE_DIR/expected home" "$CASE_DIR/actual home"
    tree_snapshot "$FIXTURE_REPO" > "$CASE_DIR/repo-after"
    assert_snapshots_equal "$CASE_DIR/repo-before" "$CASE_DIR/repo-after" 'update repository'
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-after"
    assert_snapshots_equal "$CASE_DIR/external-before" "$CASE_DIR/external-after" 'update referents'
}

test_backup_dry_run() {
    populate_home
    assert_unchanged "$FIXTURE" run_script "$FIXTURE_REPO/scripts/backup-dotfiles.sh" --dir "$BACKUP" --dry-run
}

test_existing_backup() {
    populate_home
    make_backup
    assert_unchanged "$FIXTURE" expect_failure make_backup
}

test_round_trip() {
    populate_home
    tree_snapshot "$HOME" > "$CASE_DIR/home-before"
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-before"
    make_backup
    tree_snapshot "$HOME" > "$CASE_DIR/home-after"
    assert_snapshots_equal "$CASE_DIR/home-before" "$CASE_DIR/home-after" 'backup source'
    [[ "$(cat "$BACKUP/FORMAT")" == dotfiles-backup-v1 && "$(cat "$BACKUP/COMPLETE")" == complete ]] || fail 'Missing backup markers'
    local mode relative recovery
    if [[ "$PLATFORM" == Darwin ]]; then mode="$(stat -f '%Lp' "$BACKUP")"; else mode="$(stat -c '%a' "$BACKUP")"; fi
    [[ "$mode" == 700 ]] || fail "Backup permissions are $mode, expected 700"
    while IFS= read -r relative; do
        assert_same_entry "$HOME/$relative" "$BACKUP/home/$relative"
    done < "$BACKUP/paths"
    rm "$HOME/.zshrc" "$HOME/.zshenv"
    printf 'displaced rc\n' > "$HOME/.zshrc"
    ln -s "$EXTERNAL/displaced missing target" "$HOME/.zshenv"
    printf 'displaced hidden\n' > "$HOME/.config/zsh/.hidden"
    printf 'displaced extra\n' > "$HOME/.config/zsh/extra file"
    chmod 600 "$HOME/.config/zsh/.hidden"
    cp -pPR "$HOME" "$CASE_DIR/displaced home"
    restore_backup --yes
    set -- "$HOME"/.dotfiles-backup-before-restore-*
    [[ "$#" -eq 1 && -d "$1" ]] || fail 'Expected exactly one recovery backup'
    recovery="$1"
    [[ "$(cat "$recovery/COMPLETE")" == complete ]] || fail 'Incomplete recovery backup'
    cmp "$BACKUP/paths" "$recovery/paths"
    while IFS= read -r relative; do
        assert_same_entry "$BACKUP/home/$relative" "$HOME/$relative"
        assert_same_entry "$CASE_DIR/displaced home/$relative" "$recovery/home/$relative"
    done < "$BACKUP/paths"
    [[ ! -e "$HOME/.config/zsh/extra file" ]] || fail 'Restored directory retained displaced content'
    assert_link "$HOME/.zshrc" "$EXTERNAL/missing target"
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-after"
    assert_snapshots_equal "$CASE_DIR/external-before" "$CASE_DIR/external-after" 'symlink referents'
}

test_restore_preview() {
    populate_home
    make_backup
    assert_unchanged "$FIXTURE" restore_backup --dry-run
}

test_confirmation() {
    populate_home
    make_backup
    printf 'must remain\n' > "$HOME/.gitconfig"
    assert_unchanged "$FIXTURE" expect_failure restore_backup
}

test_unsafe_backup_parent() {
    local kind="$1"
    mkdir -p "$EXTERNAL/parent/zsh"
    printf 'outside original\n' > "$EXTERNAL/parent/zsh/.hidden"
    if [[ "$kind" == dangling ]]; then
        ln -s "$EXTERNAL/missing parent" "$HOME/.config"
    else
        ln -s "$EXTERNAL/parent" "$HOME/.config"
    fi
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-before"
    assert_unchanged "$HOME" expect_failure make_backup
    [[ ! -e "$BACKUP/COMPLETE" ]] || fail 'Unsafe backup was marked complete'
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-after"
    assert_snapshots_equal "$CASE_DIR/external-before" "$CASE_DIR/external-after" 'backup symlink parent'
}

test_invalid_restore() {
    local scenario="$1" metadata
    populate_home
    make_backup
    printf 'live data must survive\n' > "$HOME/.gitconfig"
    case "$scenario" in
        missing-FORMAT|missing-paths|missing-COMPLETE|missing-home)
            metadata="${scenario#missing-}"
            rm -rf "${BACKUP:?}/${metadata:?}"
            ;;
        linked-*)
            metadata="${scenario#linked-}"
            mv "$BACKUP/$metadata" "$EXTERNAL/metadata"
            ln -s "$EXTERNAL/metadata" "$BACKUP/$metadata"
            ;;
        bad-format) printf 'unsupported-format\n' > "$BACKUP/FORMAT" ;;
        bad-complete) printf 'incomplete\n' > "$BACKUP/COMPLETE" ;;
        paths-directory) rm "$BACKUP/paths"; mkdir "$BACKUP/paths" ;;
        missing-entry) rm "$BACKUP/home/.zshrc" ;;
        traversal) printf '.gitconfig\n../external with spaces/file target\n' > "$BACKUP/paths" ;;
        nested-traversal) printf '.gitconfig\n.config/../.zprofile\n' > "$BACKUP/paths" ;;
        absolute) printf '.gitconfig\n%s\n' "$EXTERNAL/file target" > "$BACKUP/paths" ;;
        unknown) printf '.gitconfig\n.not-allowed\n' > "$BACKUP/paths" ;;
        blank) printf '.gitconfig\n\n' > "$BACKUP/paths" ;;
        unterminated) printf '.gitconfig\n../external with spaces/file target' > "$BACKUP/paths" ;;
        source-parent)
            mv "$BACKUP/home/.config" "$EXTERNAL/source parent"
            ln -s "$EXTERNAL/source parent" "$BACKUP/home/.config"
            ;;
        destination-parent)
            mv "$HOME/.config" "$EXTERNAL/destination parent"
            ln -s "$EXTERNAL/destination parent" "$HOME/.config"
            ;;
        dangling-parent)
            rm -rf "$HOME/.config"
            ln -s "$EXTERNAL/missing parent" "$HOME/.config"
            ;;
        backup-link)
            mv "$BACKUP" "$EXTERNAL/actual backup"
            ln -s "$EXTERNAL/actual backup" "$BACKUP"
            ;;
        *) fail "Unknown restore scenario: $scenario" ;;
    esac
    assert_unchanged "$FIXTURE" expect_failure restore_backup --yes
}

prepare_link_target() {
    LINK_TARGET="$HOME/.config/zsh"
    mkdir -p "$HOME/.config" "$EXTERNAL/old directory"
    printf 'referent original\n' > "$EXTERNAL/old directory/.hidden"
    case "$1" in
        file) printf 'original file\n' > "$LINK_TARGET"; chmod 640 "$LINK_TARGET" ;;
        directory)
            mkdir "$LINK_TARGET"
            printf 'original hidden\n' > "$LINK_TARGET/.hidden"
            printf 'original spaced\n' > "$LINK_TARGET/file with spaces"
            chmod 751 "$LINK_TARGET"
            ;;
        symlink) ln -s "$EXTERNAL/old directory" "$LINK_TARGET" ;;
        dangling) ln -s "$EXTERNAL/absent directory" "$LINK_TARGET" ;;
        *) fail "Unknown target type: $1" ;;
    esac
    cp -pPR "$LINK_TARGET" "$CASE_DIR/original target"
}

test_link_replacement() {
    prepare_link_target "$1"
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-before"
    installer_function link "$FIXTURE_REPO/config/zsh" "$LINK_TARGET"
    assert_link "$LINK_TARGET" "$FIXTURE_REPO/config/zsh"
    set -- "$HOME"/.dotfiles-backup-*
    [[ "$#" -eq 1 && -d "$1" ]] || fail 'Expected one installer backup'
    assert_same_entry "$CASE_DIR/original target" "$1/home/.config/zsh"
    [[ "$(cat "$1/COMPLETE")" == complete ]] || fail 'Installer backup is incomplete'
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-after"
    assert_snapshots_equal "$CASE_DIR/external-before" "$CASE_DIR/external-after" 'link referent'
}

test_failed_link() {
    prepare_link_target "$1"
    tree_snapshot "$LINK_TARGET" > "$CASE_DIR/target-before"
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-before"
    expect_failure installer_function failed-ln "$FIXTURE_REPO/config/zsh" "$LINK_TARGET" "$2"
    tree_snapshot "$LINK_TARGET" > "$CASE_DIR/target-after"
    assert_snapshots_equal "$CASE_DIR/target-before" "$CASE_DIR/target-after" 'original after failed ln'
    [[ -z "$(find "$HOME" -name '.dotfiles-link.*' -print)" ]] || fail 'Link staging directory leaked'
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-after"
    assert_snapshots_equal "$CASE_DIR/external-before" "$CASE_DIR/external-after" 'failed link referent'
}

test_link_parent() {
    mkdir -p "$EXTERNAL/parent/zsh"
    printf 'preserve outside data\n' > "$EXTERNAL/parent/zsh/.hidden"
    ln -s "$EXTERNAL/parent" "$HOME/.config"
    assert_unchanged "$EXTERNAL" expect_failure installer_function link "$FIXTURE_REPO/config/zsh" "$HOME/.config/zsh"
    assert_link "$HOME/.config" "$EXTERNAL/parent"
}

test_update_preserves_directory() {
    prepare_link_target directory
    assert_unchanged "$HOME" installer_function update
}

run_zsh() {
    local result=0
    env -i HOME="$HOME" PATH="$STUB_BIN" SHELL=/bin/zsh \
        XDG_DATA_HOME="$HOME/.local/share" XDG_CACHE_HOME="$HOME/.cache" \
        SAFETY_CALLS="$CASE_DIR/forbidden-calls" \
        /bin/zsh -df "$@" < /dev/null 2> "$CASE_DIR/zsh-stderr" || result=$?
    cat "$CASE_DIR/zsh-stderr"
    [[ "$result" -eq 0 && ! -s "$CASE_DIR/zsh-stderr" ]] || fail 'Zsh failed or emitted an error'
}

test_zshenv() {
    cp "$REPO_DIR/config/zsh/.zshenv" "$FIXTURE_REPO/config/zsh/.zshenv"
    assert_unchanged "$FIXTURE" run_zsh -c '
        set -eu
        expected_config="$HOME/.config"
        expected_data="$HOME/.local/share"
        expected_cache="$HOME/.cache"
        expected_state="$HOME/.local/state"
        case "$2" in
            default) ;;
            explicit) export ZDOTDIR="$HOME/explicit zsh directory" ;;
            xdg)
                expected_config="$HOME/custom config"
                expected_data="$HOME/custom data"
                expected_cache="$HOME/custom cache"
                expected_state="$HOME/custom state"
                export XDG_CONFIG_HOME="$expected_config" XDG_DATA_HOME="$expected_data"
                export XDG_CACHE_HOME="$expected_cache" XDG_STATE_HOME="$expected_state"
                ;;
            *) exit 99 ;;
        esac
        expected_zdotdir="${ZDOTDIR:-$HOME/.config/zsh}"
        export ZPROFILE_LOADED=1 ZSHRC_LOADED=1
        source "$1"
        [[ "$ZDOTDIR" == "$expected_zdotdir" ]]
        [[ "$XDG_CONFIG_HOME" == "$expected_config" && "$XDG_DATA_HOME" == "$expected_data" ]]
        [[ "$XDG_CACHE_HOME" == "$expected_cache" && "$XDG_STATE_HOME" == "$expected_state" ]]
        [[ "$HISTFILE" == "$expected_data/zsh/history" ]]
        [[ -z "${ZPROFILE_LOADED+x}" && -z "${ZSHRC_LOADED+x}" ]]
    ' safety-zshenv "$FIXTURE_REPO/config/zsh/.zshenv" "$1"
}

test_shell_functions() {
    mkdir -p "$HOME/bookmark target"
    printf 'sample:%s\n' "$HOME/bookmark target" > "$HOME/.bookmarks"
    printf '%s\n' '[[ -n "$ZSHRC_LOADED" ]] && return' 'ZSHRC_LOADED=1' 'RELOAD_COUNT=$((RELOAD_COUNT + 1))' > "$HOME/.zshrc"
    run_zsh -c '
        PATH=/usr/bin:/bin
        source "$1"
        original_path="$PATH"
        clean_bookmarks >/dev/null
        [[ "$PATH" == "$original_path" ]] || exit 1
        (( $+functions[go] == 0 && $+functions[bookmark_go] == 1 )) || exit 1
        bookmark_go sample || exit 1
        [[ "$PWD" == "$HOME/bookmark target" ]] || exit 1
        ZSHRC_LOADED=1 RELOAD_COUNT=0
        reload_zshrc >/dev/null
        [[ "$RELOAD_COUNT" == 1 ]]
    ' shell-functions "$REPO_DIR/config/zsh/functions.zsh"
}

test_plugins() {
    local scenario="$1" platform="$2" plugin_root="$HOME/.local/share/zsh/plugins" expected=''
    cp "$REPO_DIR/config/zsh/plugins.zsh" "$FIXTURE_REPO/config/zsh/plugins.zsh"
    if [[ "$scenario" != missing ]]; then
        mkdir -p "$plugin_root/zsh-autosuggestions" "$plugin_root/zsh-syntax-highlighting" "$plugin_root/fzf-tab"
    fi
    case "$scenario" in
        missing|empty) ;;
        fallback)
            printf '%s\n' 'PLUGIN_TRACE="${PLUGIN_TRACE}first"' > "$plugin_root/zsh-autosuggestions/01-first.zsh"
            printf '%s\n' 'exit 97' > "$plugin_root/zsh-autosuggestions/02-second.zsh"
            printf '%s\n' 'exit 97' > "$plugin_root/zsh-autosuggestions/.hidden.zsh"
            expected=first
            ;;
        standard)
            printf '%s\n' 'PLUGIN_TRACE="${PLUGIN_TRACE}standard"' > "$plugin_root/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
            printf '%s\n' 'exit 97' > "$plugin_root/zsh-autosuggestions/01-fallback.zsh"
            expected=standard
            ;;
        *) fail "Unknown plugin scenario: $scenario" ;;
    esac
    assert_unchanged "$FIXTURE" run_zsh -c '
        set -eu
        setopt NOMATCH
        TEST_PLATFORM="$3"
        is_macos() { [[ "$TEST_PLATFORM" == macos ]]; }
        is_linux() { [[ "$TEST_PLATFORM" == linux ]]; }
        PLUGIN_TRACE=""
        source "$1"
        [[ "$PLUGIN_TRACE" == "$2" ]]
    ' safety-plugins "$FIXTURE_REPO/config/zsh/plugins.zsh" "$expected" "$platform"
}

test_plugin_updates() {
    local scenario="$1"
    mkdir -p "$HOME/.local/share/zsh/plugins/fixture plugin/.git"
    cp "$SCRIPT_DIR/update-all.sh" "$FIXTURE_REPO/scripts/update-all.sh"
    case "$scenario" in
        updater-dry)
            run_script "$FIXTURE_REPO/scripts/update-all.sh" --dry-run --skip-system --skip-vim --skip-vms
            ;;
        updater-failure)
            printf '#!/bin/sh\nexit 19\n' > "$STUB_BIN/git"
            expect_failure run_script "$FIXTURE_REPO/scripts/update-all.sh" --skip-system --skip-vim --skip-vms
            ;;
        updater-vim-failure|updater-vms-failure|updater-repo-failure)
            local output result=0
            case "$scenario" in
                updater-vim-failure)
                    mkdir -p "$HOME/.config/nvim"
                    : > "$HOME/.config/nvim/init.vim"
                    printf '#!/bin/sh\nexit 19\n' > "$STUB_BIN/nvim"
                    output=$(run_script "$FIXTURE_REPO/scripts/update-all.sh" --skip-system --skip-plugins --skip-vms) || result=$?
                    ;;
                updater-vms-failure)
                    mkdir -p "$HOME/.nvm"
                    printf '#!/bin/sh\nexit 19\n' > "$STUB_BIN/git"
                    output=$(run_script "$FIXTURE_REPO/scripts/update-all.sh" --skip-system --skip-plugins --skip-vim) || result=$?
                    ;;
                updater-repo-failure)
                    mkdir -p "$HOME/.dotfiles/.git"
                    printf '#!/bin/sh\nif [ "$3" = remote ]; then echo origin; exit 0; fi\nexit 19\n' > "$STUB_BIN/git"
                    output=$(run_script "$FIXTURE_REPO/scripts/update-all.sh" --skip-system --skip-plugins --skip-vim --skip-vms) || result=$?
                    ;;
            esac
            [[ "$result" -ne 0 && "$output" != *'All updates finished'* ]] || fail "$scenario masked an update failure"
            ;;
        make-success|make-failure)
            local git_result=0 result=0
            [[ "$scenario" != make-failure ]] || git_result=19
            printf '#!/bin/sh\nexit %s\n' "$git_result" > "$STUB_BIN/git"
            prepare_make_fixture
            run_make plugins || result=$?
            if [[ "$git_result" == 0 ]]; then
                [[ "$result" == 0 ]] || fail 'Plugin update failed after successful Git command'
            else
                [[ "$result" != 0 ]] || fail 'Plugin update masked failed Git command'
            fi
            ;;
        *) fail "Unknown updater scenario: $scenario" ;;
    esac
}

prepare_make_fixture() {
    cp "$REPO_DIR/Makefile" "$FIXTURE_REPO/Makefile"
    cat > "$STUB_BIN/make-command" <<'STUB'
#!/bin/sh
printf '%s\0' "${0##*/}" "$#" >> "$MAKE_CALLS"
if [ "$#" -gt 0 ]; then
    printf '%s\0' "$@" >> "$MAKE_CALLS"
fi
exit "${MAKE_STUB_STATUS:-0}"
STUB
    chmod +x "$STUB_BIN/make-command"
    cp -p "$STUB_BIN/make-command" "$FIXTURE_REPO/install.sh"
    local script
    for script in install-packages.sh test-dotfiles.sh security-audit.sh setup-pre-commit.sh \
        mcpm-atlassian-keychain-setup.sh mcpm-atlassian-migrate.sh; do
        cp -p "$STUB_BIN/make-command" "$FIXTURE_REPO/scripts/$script"
    done
    chmod +x "$FIXTURE_REPO/install.sh"
    cp -p "$STUB_BIN/make-command" "$STUB_BIN/mcpm"
    ln -s "$BASH" "$STUB_BIN/bash"
}

run_make() {
    env -i HOME="$HOME" PATH="${MAKE_TEST_PATH:-$STUB_BIN:/usr/bin:/bin:/usr/sbin:/sbin}" SHELL=/bin/sh LC_ALL=C \
        SAFETY_CALLS="$CASE_DIR/forbidden-calls" MAKE_CALLS="$CASE_DIR/make-calls" \
        MAKE_STUB_STATUS="${MAKE_STUB_STATUS:-0}" MAKE_SCENARIO="${MAKE_SCENARIO:-}" \
        MAKE_FAIL_COMMAND="${MAKE_FAIL_COMMAND:-}" DIRECT_CALLS="$CASE_DIR/direct-calls" \
        TMPDIR="${MAKE_TMPDIR:-$CASE_DIR/tmp with spaces}" FIXTURE_ROOT="$FIXTURE" \
        XDG_DATA_HOME="${MAKE_XDG_DATA_HOME:-}" \
        /usr/bin/make -s --no-print-directory -C "$FIXTURE_REPO" \
        "SHELL=${MAKE_RECIPE_SHELL:-/bin/sh}" "$@" < /dev/null
}

prepare_direct_make_fixture() {
    prepare_make_fixture
    MAKE_TEST_PATH="$STUB_BIN"
    MAKE_RECIPE_SHELL="$BASH"
    local command_name
    for command_name in npm npx pip pip3 uv uvx unzip fc-cache getent dscl zsh; do
        cp -p "$STUB_BIN/git" "$STUB_BIN/$command_name"
    done
    for command_name in uname tr grep cut readlink head wc id awk find date mktemp \
        mkdir cp mv rm stat cat sort; do
        ln -s "$(command -v "$command_name")" "$STUB_BIN/$command_name"
    done
    ln -s /usr/bin/printf "$STUB_BIN/printf"
    ln -s /usr/bin/make "$STUB_BIN/make"
}

populate_make_links() {
    local source target
    while IFS='|' read -r source target; do
        mkdir -p "$(dirname "$HOME/$target")"
        ln -s "$FIXTURE_REPO/$source" "$HOME/$target"
    done <<'LINKS'
config/zsh|.config/zsh
config/zsh/.zshrc|.zshrc
config/zsh/.zshenv|.zshenv
config/zsh/.zprofile|.zprofile
config/git/gitconfig|.gitconfig
config/git|.config/git
config/mcpm/servers.json|.config/mcpm/servers.json
scripts/mcpm-atlassian-secure.sh|.local/bin/mcpm-atlassian-secure
config/vim/vimrc|.vimrc
config/nvim|.config/nvim
LINKS
}

prepare_status_git() {
    cat > "$STUB_BIN/git" <<'STUB'
#!/bin/sh
printf 'git %s\n' "$*" >> "$DIRECT_CALLS"
case "$*" in
    'rev-parse --is-inside-work-tree')
        [ "$MAKE_SCENARIO" != git-rev-failure ] || exit 37
        printf 'true\n' ;;
    'branch --show-current')
        [ "$MAKE_SCENARIO" != git-branch-failure ] || exit 37
        [ "$MAKE_SCENARIO" = detached ] || printf 'fixture-branch\n' ;;
    'remote get-url origin')
        [ "$MAKE_SCENARIO" != no-remote ] || exit 37
        printf 'https://example.invalid/fixture.git\n' ;;
    '--no-optional-locks status --porcelain')
        [ "$MAKE_SCENARIO" != git-status-failure ] || exit 37
        [ "$MAKE_SCENARIO" != dirty ] || printf ' M fixture-file\n' ;;
    *) printf 'git %s\n' "$*" >> "$SAFETY_CALLS"; exit 98 ;;
esac
exit 0
STUB
    mkdir "$FIXTURE_REPO/.git"
    populate_make_links
}

test_make_status() {
    local scenario="$1" result=0
    prepare_direct_make_fixture
    prepare_status_git
    MAKE_SCENARIO="$scenario"
    case "$scenario" in
        missing|stale|dangling|real-file)
            rm "$HOME/.zshrc"
            case "$scenario" in
                missing) ;;
                stale) ln -s "$FIXTURE_REPO/config/zsh/.zshenv" "$HOME/.zshrc" ;;
                dangling) ln -s "$EXTERNAL/missing target" "$HOME/.zshrc" ;;
                real-file) printf 'preserve real startup file\n' > "$HOME/.zshrc" ;;
            esac
            ;;
        worktree)
            rmdir "$FIXTURE_REPO/.git"
            printf 'gitdir: %s\n' "$EXTERNAL/fake worktree" > "$FIXTURE_REPO/.git"
            ;;
    esac
    tree_snapshot "$FIXTURE" > "$CASE_DIR/status-before"
    run_make status > "$CASE_DIR/status-output" 2>&1 || result=$?
    tree_snapshot "$FIXTURE" > "$CASE_DIR/status-after"
    assert_snapshots_equal "$CASE_DIR/status-before" "$CASE_DIR/status-after" 'make status fixture'
    case "$scenario" in
        missing|stale|dangling|real-file|git-*-failure)
            [[ "$result" -ne 0 ]] || fail "make status accepted $scenario"
            if grep -F 'Working tree is clean' "$CASE_DIR/status-output" > /dev/null; then
                fail "make status reported clean after $scenario"
            fi
            ;;
        *)
            [[ "$result" -eq 0 ]] || fail "make status rejected $scenario"
            grep -Fx 'git rev-parse --is-inside-work-tree' "$CASE_DIR/direct-calls" > /dev/null
            local expected='Working tree is clean'
            case "$scenario" in
                detached) expected='Branch: detached HEAD' ;;
                dirty) expected=' M fixture-file' ;;
                no-remote) expected='Remote: No remote configured' ;;
            esac
            grep -F "$expected" "$CASE_DIR/status-output" > /dev/null || fail "make status omitted $expected"
            ;;
    esac
}

test_make_doctor() {
    local scenario="$1" result=0 command_name
    prepare_direct_make_fixture
    prepare_status_git
    MAKE_SCENARIO="$scenario"
    cat > "$STUB_BIN/getent" <<'STUB'
#!/bin/sh
printf 'getent %s\n' "$*" >> "$DIRECT_CALLS"
login_shell=/fixture/bin/zsh
[ "$MAKE_SCENARIO" != bad-shell ] || login_shell=/fixture/bin/bash
printf 'fixture:x:1000:1000:fixture:%s:%s\n' "$HOME" "$login_shell"
STUB
    printf '#!/bin/sh\nprintf "zsh 5.9 (fixture)\\n"\n' > "$STUB_BIN/zsh"
    case "$scenario" in missing-*) rm "$STUB_BIN/${scenario#missing-}" ;; esac
    run_make doctor OS=linux DISTRO=debian > "$CASE_DIR/doctor-output" 2>&1 || result=$?
    case "$scenario" in
        bad-shell|missing-*)
            [[ "$result" -ne 0 ]] || fail "make doctor accepted $scenario"
            grep -F "${scenario#missing-}" "$CASE_DIR/doctor-output" > /dev/null || {
                [[ "$scenario" == bad-shell ]] || fail 'Missing required-tool diagnostic'
            }
            if [[ "$scenario" == bad-shell ]]; then
                grep -F 'expected zsh' "$CASE_DIR/doctor-output" > /dev/null
            fi
            ;;
        *)
            [[ "$result" -eq 0 ]] || fail 'make doctor failed with required tools and zsh login shell'
            grep -F 'zsh is the default shell' "$CASE_DIR/doctor-output" > /dev/null
            grep -F 'Working tree is clean' "$CASE_DIR/doctor-output" > /dev/null
            for command_name in bat eza fd fzf rg jq gh nvm pyenv rbenv rustup; do
                grep -F "$command_name: not installed" "$CASE_DIR/doctor-output" > /dev/null || \
                    fail "Optional tool $command_name was not absent"
            done
            ;;
    esac
}

test_make_docs() {
    local scenario="$1" result=0 relative document="$FIXTURE_REPO/SYSTEM_INFO.md"
    prepare_direct_make_fixture
    case "$scenario" in
        generate) ;;
        replace|find-failure) printf 'previous documentation\n' > "$document"; chmod 640 "$document" ;;
        symlink)
            printf 'external documentation\n' > "$EXTERNAL/document"
            ln -s "$EXTERNAL/document" "$document"
            ;;
        dangling-symlink) ln -s "$EXTERNAL/missing document" "$document" ;;
        directory) mkdir "$document"; printf 'preserve directory content\n' > "$document/.hidden" ;;
        *) fail "Unknown docs scenario: $scenario" ;;
    esac
    if [[ "$scenario" == find-failure ]]; then
        rm "$STUB_BIN/find"
        printf '#!/bin/sh\nprintf -- "- partial result\\n"\nexit 37\n' > "$STUB_BIN/find"
        chmod +x "$STUB_BIN/find"
    fi
    tree_snapshot "$FIXTURE" portable > "$CASE_DIR/docs-before"
    run_make docs OS=linux DISTRO=debian > "$CASE_DIR/docs-output" 2>&1 || result=$?
    case "$scenario" in
        generate|replace)
            if [[ "$result" -ne 0 || ! -f "$document" || -L "$document" ]]; then
                cat "$CASE_DIR/docs-output"
                fail 'make docs did not publish a regular file'
            fi
            for relative in zsh/.zshrc zsh/.zshenv zsh/.zprofile vim/vimrc nvim/init.vim git/gitconfig; do
                grep -Fx -- "- config/$relative" "$document" > /dev/null || fail "make docs omitted $relative"
            done
            grep -Fx -- "- XDG_DATA_HOME: $HOME/.local/share" "$document" > /dev/null
            grep -Fx -- '- Distribution: debian' "$document" > /dev/null
            if grep -F 'previous documentation' "$document" > /dev/null; then fail 'make docs appended instead of replacing'; fi
            ;;
        *)
            [[ "$result" -ne 0 ]] || fail "make docs accepted $scenario"
            tree_snapshot "$FIXTURE" portable > "$CASE_DIR/docs-after"
            assert_snapshots_equal "$CASE_DIR/docs-before" "$CASE_DIR/docs-after" 'failed docs publication'
            ;;
    esac
    set -- "$FIXTURE_REPO"/SYSTEM_INFO.md.*
    [[ ! -e "$1" && ! -L "$1" ]] || fail 'make docs leaked a staging file'
}

prepare_package_stubs() {
    cat > "$STUB_BIN/package-command" <<'STUB'
#!/bin/sh
command_name="${0##*/}"
printf '%s' "$command_name" >> "$DIRECT_CALLS"
printf ' <%s>' "$@" >> "$DIRECT_CALLS"
printf '\n' >> "$DIRECT_CALLS"
if [ -n "$MAKE_FAIL_COMMAND" ]; then
    case "$command_name $*" in "$MAKE_FAIL_COMMAND"|"$MAKE_FAIL_COMMAND "*) exit 37 ;; esac
fi
exit 0
STUB
    chmod +x "$STUB_BIN/package-command"
    cp -p "$STUB_BIN/package-command" "$STUB_BIN/brew"
    cp -p "$STUB_BIN/package-command" "$STUB_BIN/sudo"
}

prepare_font_stubs() {
    local command_name
    MAKE_TMPDIR="$CASE_DIR/tmp with spaces"
    mkdir "$MAKE_TMPDIR"
    for command_name in mktemp mkdir cp mv rm; do
        mv "$STUB_BIN/$command_name" "$STUB_BIN/real-$command_name"
    done
    cat > "$STUB_BIN/font-files" <<'STUB'
#!/bin/sh
set -eu
command_name="${0##*/}"
refuse() { printf 'unsafe %s %s\n' "$command_name" "$*" >> "$SAFETY_CALLS"; exit 98; }
if [ "$command_name" = mktemp ]; then
    [ "$#" -eq 2 ] && [ "$1" = -d ] && [ "$2" = "$TMPDIR/dotfiles-fonts.XXXXXX" ] || refuse "$@"
    temporary=$("${0%/*}/real-mktemp" "$@")
    printf '%s\n' "$temporary" >> "$DIRECT_CALLS.temporary"
    if [ "$(uname -s)" = Darwin ]; then
        stat -f '%Lp' "$temporary" >> "$DIRECT_CALLS.mode"
    else
        stat -c '%a' "$temporary" >> "$DIRECT_CALLS.mode"
    fi
    printf '%s\n' "$temporary"
    exit 0
fi
for argument do
    case "$argument" in
        */../*|*/..) refuse "$argument" ;;
        -*) ;;
        "$FIXTURE_ROOT"/*|"$TMPDIR"/*) ;;
        *) refuse "$argument" ;;
    esac
done
exec "${0%/*}/real-$command_name" "$@"
STUB
    chmod +x "$STUB_BIN/font-files"
    for command_name in mktemp mkdir cp mv rm; do
        cp -p "$STUB_BIN/font-files" "$STUB_BIN/$command_name"
    done
    cat > "$STUB_BIN/font-command" <<'STUB'
#!/bin/sh
set -eu
command_name="${0##*/}"
printf '%s' "$command_name" >> "$DIRECT_CALLS"
printf ' <%s>' "$@" >> "$DIRECT_CALLS"
printf '\n' >> "$DIRECT_CALLS"
refuse() { printf 'unsafe %s %s\n' "$command_name" "$*" >> "$SAFETY_CALLS"; exit 98; }
[ -f "$DIRECT_CALLS.temporary" ] || refuse 'no private staging directory'
IFS= read -r temporary < "$DIRECT_CALLS.temporary"
case "$command_name" in
    curl)
        archive=''
        while [ "$#" -gt 0 ]; do
            case "$1" in
                -fL|-L|-f|--fail|--location) shift ;;
                --retry) [ "$#" -ge 2 ] || refuse "$@"; shift 2 ;;
                -o|--output) [ "$#" -ge 2 ] || refuse "$@"; archive="$2"; shift 2 ;;
                https://github.com/ryanoasis/nerd-fonts/releases/download/*/Agave.zip) shift ;;
                *) refuse "$@" ;;
            esac
        done
        [ "$archive" = "$temporary/Agave.zip" ] || refuse "$archive"
        printf 'dummy archive\n' > "$archive"
        [ "$MAKE_SCENARIO" != curl-failure ] || exit 37
        ;;
    unzip)
        destination='' archive=''
        while [ "$#" -gt 0 ]; do
            case "$1" in
                -oq|'*.ttf') shift ;;
                -d) [ "$#" -ge 2 ] || refuse "$@"; destination="$2"; shift 2 ;;
                "$temporary/Agave.zip") archive="$1"; shift ;;
                *) refuse "$@" ;;
            esac
        done
        [ "$destination" = "$temporary/fonts" ] && [ -f "$archive" ] || refuse "$destination"
        [ "$(cat "$archive")" = 'dummy archive' ] || refuse 'not a fixture archive'
        mkdir -p "$destination"
        if [ "$MAKE_SCENARIO" != empty-archive ]; then
            printf 'fixture font\n' > "$destination/Agave Fixture.ttf"
        fi
        [ "$MAKE_SCENARIO" != unzip-failure ] || exit 37
        ;;
    fc-cache)
        [ "$#" -eq 2 ] && [ "$1" = -f ] || refuse "$@"
        [ "$2" = "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/AgaveNerdFont" ] || refuse "$@"
        [ -f "$2/Agave Fixture.ttf" ] || refuse 'font was not installed'
        [ "$MAKE_SCENARIO" != cache-failure ] || exit 37
        ;;
    *) refuse "$@" ;;
esac
exit 0
STUB
    chmod +x "$STUB_BIN/font-command"
    for command_name in curl unzip fc-cache; do
        cp -p "$STUB_BIN/font-command" "$STUB_BIN/$command_name"
    done
}

test_make_fonts() {
    local platform="$1" scenario="$2" result=0 destination temporary expected_commands
    prepare_direct_make_fixture
    prepare_package_stubs
    prepare_font_stubs
    MAKE_SCENARIO="$scenario"
    destination="$HOME/.local/share/fonts/AgaveNerdFont"
    case "$scenario" in
        brew-failure) MAKE_FAIL_COMMAND='brew install --cask font-agave-nerd-font' ;;
        fallback) rm "$STUB_BIN/brew"; destination="$HOME/Library/Fonts" ;;
        xdg) MAKE_XDG_DATA_HOME="$FIXTURE/xdg data with spaces"; destination="$MAKE_XDG_DATA_HOME/fonts/AgaveNerdFont" ;;
    esac
    run_make fonts "OS=$platform" DISTRO=debian > "$CASE_DIR/fonts-output" 2>&1 || result=$?
    [[ -z "$(find "$MAKE_TMPDIR" -mindepth 1 -print)" ]] || fail 'make fonts leaked private staging files'
    if [[ "$scenario" == brew-success || "$scenario" == brew-failure ]]; then
        printf 'brew <install> <--cask> <font-agave-nerd-font>\n' > "$CASE_DIR/expected-font-calls"
        cmp "$CASE_DIR/expected-font-calls" "$CASE_DIR/direct-calls" || fail 'Incorrect font cask request'
        [[ ! -e "$CASE_DIR/direct-calls.temporary" ]] || fail 'Brew font install unnecessarily staged a download'
    elif [[ "$scenario" == unsupported ]]; then
        [[ ! -e "$CASE_DIR/direct-calls" && ! -e "$CASE_DIR/direct-calls.temporary" ]] || fail 'Unsupported OS attempted a font install'
    else
        [[ "$(cat "$CASE_DIR/direct-calls.mode")" == 700 ]] || fail 'Font staging directory was not private'
        IFS= read -r temporary < "$CASE_DIR/direct-calls.temporary"
        [[ "$temporary" == "$MAKE_TMPDIR"/dotfiles-fonts.* && ! -e "$temporary" && ! -L "$temporary" ]] || \
            fail 'Font staging escaped TMPDIR or was not removed'
        grep -F ' <-fL>' "$CASE_DIR/direct-calls" > /dev/null || fail 'curl did not request -fL'
        case "$scenario" in
            curl-failure) expected_commands=curl ;;
            unzip-failure|empty-archive|fallback) expected_commands=$'curl\nunzip' ;;
            *) expected_commands=$'curl\nunzip\nfc-cache' ;;
        esac
        [[ "$(cut -d' ' -f1 "$CASE_DIR/direct-calls")" == "$expected_commands" ]] || fail 'Unexpected font command sequence'
        case "$scenario" in
            curl-failure|unzip-failure|empty-archive)
                [[ ! -e "$destination" ]] || fail 'Failed download/extraction installed font content'
                ;;
            *) [[ "$(cat "$destination/Agave Fixture.ttf")" == 'fixture font' ]] || fail 'Font not installed at expected spaced destination' ;;
        esac
    fi
    case "$scenario" in
        *-failure|empty-archive|unsupported)
            [[ "$result" -ne 0 ]] || fail "make fonts masked $scenario"
            if grep -F 'Nerd Font installed' "$CASE_DIR/fonts-output" > /dev/null; then fail 'Font failure reported success'; fi
            ;;
        *) [[ "$result" -eq 0 ]] || fail "make fonts failed for $platform/$scenario" ;;
    esac
}

test_make_dev_setup() {
    local platform="$1" distro="$2" scenario="$3" result=0 prefix tool
    prepare_direct_make_fixture
    prepare_package_stubs
    case "$platform/$distro" in
        darwin/*) prefix='brew <install>'; MAKE_FAIL_COMMAND='brew install' ;;
        linux/debian)
            prefix='sudo <apt> <install> <-y>'
            MAKE_FAIL_COMMAND='sudo apt install'
            [[ "$scenario" != update-failure ]] || MAKE_FAIL_COMMAND='sudo apt update'
            ;;
        linux/fedora) prefix='sudo <dnf> <install> <-y>'; MAKE_FAIL_COMMAND='sudo dnf install' ;;
        linux/arch) prefix='sudo <pacman> <-Syu> <--needed>'; MAKE_FAIL_COMMAND='sudo pacman -Syu' ;;
        *) prefix='' ;;
    esac
    [[ "$scenario" != success ]] || MAKE_FAIL_COMMAND=''
    run_make dev-setup "OS=$platform" "DISTRO=$distro" > "$CASE_DIR/dev-output" 2>&1 || result=$?
    if [[ "$scenario" == success ]]; then
        [[ "$result" -eq 0 ]] || fail "make dev-setup failed for $platform/$distro"
        grep -F "$prefix" "$CASE_DIR/direct-calls" > "$CASE_DIR/install-call" || fail 'Incorrect package manager or install flags'
        for tool in make bash zsh vim git jq ripgrep shellcheck pre-commit; do
            grep -Fi " <$tool>" "$CASE_DIR/install-call" > /dev/null || fail "make dev-setup omitted $tool for $platform/$distro"
        done
        if [[ "$distro" == debian ]]; then
            [[ "$(head -n 1 "$CASE_DIR/direct-calls")" == 'sudo <apt> <update>' ]] || fail 'apt install did not follow apt update'
        fi
    else
        [[ "$result" -ne 0 ]] || fail "make dev-setup masked $platform/$distro/$scenario"
        if [[ "$scenario" == unsupported ]]; then
            [[ ! -e "$CASE_DIR/direct-calls" ]] || fail 'Unsupported platform invoked a package manager'
            grep -F 'Unsupported development setup' "$CASE_DIR/dev-output" > /dev/null
        elif [[ "$scenario" == update-failure ]]; then
            [[ "$(cat "$CASE_DIR/direct-calls")" == 'sudo <apt> <update>' ]] || fail 'apt update failure did not stop installation'
        else
            grep -F "$prefix" "$CASE_DIR/direct-calls" > /dev/null || fail 'Failure did not reach the package install command'
        fi
        if grep -F 'Development tools installed' "$CASE_DIR/dev-output" > /dev/null; then fail 'Package failure reported success'; fi
    fi
    if [[ -e "$CASE_DIR/direct-calls" ]] && grep -F '<npm>' "$CASE_DIR/direct-calls" > /dev/null; then
        fail 'make dev-setup unexpectedly requested npm'
    fi
}

test_make_forwarding() {
    local target="$1" stub_status="$2" command_name="$3" result=0
    shift 3
    prepare_make_fixture
    printf '%s\0' "$command_name" "$#" > "$CASE_DIR/expected-calls"
    if [[ "$#" -gt 0 ]]; then printf '%s\0' "$@" >> "$CASE_DIR/expected-calls"; fi
    MAKE_STUB_STATUS="$stub_status" run_make "$target" || result=$?
    cmp "$CASE_DIR/expected-calls" "$CASE_DIR/make-calls" || fail "Incorrect command or arguments for make $target"
    if [[ "$stub_status" -eq 0 ]]; then
        [[ "$result" -eq 0 ]] || fail "make $target failed after a successful wrapper"
    else
        [[ "$result" -ne 0 ]] || fail "make $target masked wrapper exit $stub_status"
    fi
}

test_make_backup_restore() {
    prepare_make_fixture
    populate_home
    cp -pPR "$HOME" "$CASE_DIR/original home"
    tree_snapshot "$FIXTURE_REPO" > "$CASE_DIR/repo-before"
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-before"
    run_make backup
    set -- "$HOME"/.dotfiles-backup-*
    [[ "$#" -eq 1 && -d "$1" && ! -L "$1" ]] || fail 'make backup did not create one isolated backup'
    BACKUP="$1"
    [[ "$(cat "$BACKUP/FORMAT")" == dotfiles-backup-v1 && \
        "$(cat "$BACKUP/COMPLETE")" == complete && -s "$BACKUP/paths" ]] || fail 'make backup produced incomplete metadata'
    local relative recovery
    while IFS= read -r relative; do
        assert_same_entry "$CASE_DIR/original home/$relative" "$BACKUP/home/$relative"
        assert_same_entry "$CASE_DIR/original home/$relative" "$HOME/$relative"
    done < "$BACKUP/paths"
    tree_snapshot "$BACKUP" > "$CASE_DIR/backup-before"
    rm "$HOME/.zshrc" "$HOME/.zshenv"
    printf 'displaced rc\n' > "$HOME/.zshrc"
    ln -s "$EXTERNAL/displaced missing target" "$HOME/.zshenv"
    printf 'displaced hidden\n' > "$HOME/.config/zsh/.hidden"
    printf 'displaced extra\n' > "$HOME/.config/zsh/extra file"
    chmod 600 "$HOME/.config/zsh/.hidden"
    cp -pPR "$HOME" "$CASE_DIR/displaced home"
    assert_unchanged "$FIXTURE" run_make restore "BACKUP=$BACKUP"
    assert_unchanged "$FIXTURE" run_make restore "BACKUP=$BACKUP" CONFIRM=no
    run_make restore "BACKUP=$BACKUP" CONFIRM=yes
    set -- "$HOME"/.dotfiles-backup-before-restore-*
    [[ "$#" -eq 1 && -d "$1" ]] || fail 'make restore did not create one recovery backup'
    recovery="$1"
    [[ "$(cat "$recovery/COMPLETE")" == complete ]] || fail 'make restore recovery is incomplete'
    cmp "$BACKUP/paths" "$recovery/paths"
    while IFS= read -r relative; do
        assert_same_entry "$CASE_DIR/original home/$relative" "$HOME/$relative"
        assert_same_entry "$CASE_DIR/displaced home/$relative" "$recovery/home/$relative"
    done < "$BACKUP/paths"
    [[ ! -e "$HOME/.config/zsh/extra file" ]] || fail 'make restore retained displaced content'
    tree_snapshot "$BACKUP" > "$CASE_DIR/backup-after"
    assert_snapshots_equal "$CASE_DIR/backup-before" "$CASE_DIR/backup-after" 'make restore source backup'
    tree_snapshot "$FIXTURE_REPO" > "$CASE_DIR/repo-after"
    assert_snapshots_equal "$CASE_DIR/repo-before" "$CASE_DIR/repo-after" 'make backup/restore repository'
    tree_snapshot "$EXTERNAL" > "$CASE_DIR/external-after"
    assert_snapshots_equal "$CASE_DIR/external-before" "$CASE_DIR/external-after" 'make backup/restore referents'
    [[ ! -e "$CASE_DIR/make-calls" ]] || fail 'make backup/restore invoked an unrelated wrapper'
}

test_make_restore_missing_backup() {
    prepare_make_fixture
    populate_home
    run_make backup
    assert_unchanged "$FIXTURE" expect_failure run_make restore "$@"
    [[ ! -e "$CASE_DIR/make-calls" ]] || fail 'make restore invoked an unrelated wrapper'
}

test_make_clean() {
    prepare_make_fixture
    populate_home
    run_make backup
    mkdir "$FIXTURE_REPO/.dotfiles-backup-retained"
    printf 'retained backup\n' > "$FIXTURE_REPO/.dotfiles-backup-retained/original"
    printf 'retained install log\n' > "$FIXTURE_REPO/install.log"
    printf 'retained script log\n' > "$FIXTURE_REPO/scripts/log with spaces.log"
    printf 'retained home log\n' > "$HOME/install.log"
    assert_unchanged "$FIXTURE" run_make clean > "$CASE_DIR/clean-output"
    grep -F './install.log' "$CASE_DIR/clean-output" > /dev/null || fail 'make clean omitted root log candidate'
    grep -F './scripts/log with spaces.log' "$CASE_DIR/clean-output" > /dev/null || fail 'make clean omitted spaced log candidate'
    [[ ! -e "$CASE_DIR/make-calls" ]] || fail 'make clean invoked an unrelated wrapper'
}

test_make_target_inventory() {
    local mode="$1" target missing=''
    prepare_make_fixture
    awk '/^[[:alnum:]_-]+:/ { sub(/:.*/, ""); print }' "$FIXTURE_REPO/Makefile" \
        | LC_ALL=C sort -u > "$CASE_DIR/expected-targets"
    [[ -s "$CASE_DIR/expected-targets" ]] || fail 'No explicit targets found in fixture Makefile'
    assert_unchanged "$FIXTURE" run_make "$mode" > "$CASE_DIR/target-output"
    if [[ "$mode" == list ]]; then
        LC_ALL=C sort "$CASE_DIR/target-output" > "$CASE_DIR/actual-targets"
        assert_snapshots_equal "$CASE_DIR/expected-targets" "$CASE_DIR/actual-targets" 'make list target inventory'
    else
        while IFS= read -r target; do
            if ! grep -Eq "(^|[[:space:]])make[[:space:]]+$target([[:space:]]|$)" "$CASE_DIR/target-output"; then
                missing="$missing $target"
            fi
        done < "$CASE_DIR/expected-targets"
        [[ -z "$missing" ]] || fail "make help omits targets:$missing"
    fi
    [[ ! -e "$CASE_DIR/make-calls" ]] || fail "make $mode invoked a wrapper"
}

run_case() {
    local label="$1" result
    shift
    CASE_DIR="$TEST_ROOT/case $((PASSED + FAILED + 1))"
    mkdir "$CASE_DIR"
    set +e
    (
        set -euo pipefail
        new_fixture
        "$@"
        [[ ! -e "$CASE_DIR/forbidden-calls" ]] || fail "Forbidden commands invoked: $(cat "$CASE_DIR/forbidden-calls")"
    ) > "$CASE_DIR/output" 2>&1
    result=$?
    set -e
    if [[ "$result" -eq 0 ]]; then
        PASSED=$((PASSED + 1))
        printf 'PASS %s\n' "$label"
    else
        FAILED=$((FAILED + 1))
        printf 'FAIL %s (exit %s)\n' "$label" "$result"
        cat "$CASE_DIR/output"
    fi
}

printf 'Safety tests with Bash %s\n' "$BASH_VERSION"
for scenario in empty populated existing-log linked-log dangling-log; do
    run_case "installer dry-run: $scenario" test_installer_dry_run "$scenario"
done
for option in --skip-packages -s --test -t; do
    run_case "installer dry-run accepts $option without execution" test_installer_dry_run_option "$option"
done
for option in --test -t; do
    run_case "installer $option runs only tests" test_installer_test_only "$option" 0
    run_case "installer $option propagates test failure" test_installer_test_only "$option" 37
done
for scenario in empty real-file real-directory current stale dangling mixed; do
    run_case "installer --update: $scenario destinations" test_update_entrypoint "$scenario"
done
run_case 'backup preview writes nothing' test_backup_dry_run
run_case 'existing backup directory refused unchanged' test_existing_backup
run_case 'backup/restore preserves hidden files, links, spaces, modes and recovery' test_round_trip
run_case 'restore preview writes nothing' test_restore_preview
run_case 'restore requires explicit confirmation' test_confirmation
for scenario in real dangling; do
    run_case "backup refuses $scenario symlink parent" test_unsafe_backup_parent "$scenario"
done
for scenario in missing-FORMAT missing-paths missing-COMPLETE missing-home \
    linked-FORMAT linked-paths linked-COMPLETE linked-home bad-format bad-complete \
    paths-directory missing-entry traversal nested-traversal absolute unknown blank \
    unterminated source-parent destination-parent dangling-parent backup-link; do
    run_case "restore rejects $scenario before writes" test_invalid_restore "$scenario"
done
for scenario in file directory symlink dangling; do
    run_case "installer safely replaces $scenario" test_link_replacement "$scenario"
    run_case "failed ln preserves $scenario with backup" test_failed_link "$scenario" false
    run_case "failed ln preserves $scenario with force" test_failed_link "$scenario" true
done
run_case 'installer refuses symlink parent' test_link_parent
run_case 'update preserves real directory' test_update_preserves_directory
for scenario in default explicit xdg; do
    run_case "zshenv preserves $scenario paths without writes" test_zshenv "$scenario"
done
run_case 'bookmark and reload functions preserve PATH and run' test_shell_functions
for platform in macos linux; do
    for scenario in missing empty fallback standard; do
        run_case "plugins: $platform $scenario without network or writes" test_plugins "$scenario" "$platform"
    done
done
for scenario in updater-dry updater-failure updater-vim-failure updater-vms-failure updater-repo-failure make-success make-failure; do
    run_case "plugin maintenance: $scenario with isolated commands" test_plugin_updates "$scenario"
done
while IFS='|' read -r target command_name argument; do
    for stub_status in 0 37; do
        if [[ -n "$argument" ]]; then
            run_case "make $target forwards exact arguments, wrapper exit $stub_status" \
                test_make_forwarding "$target" "$stub_status" "$command_name" "$argument"
        else
            run_case "make $target forwards exact arguments, wrapper exit $stub_status" \
                test_make_forwarding "$target" "$stub_status" "$command_name"
        fi
    done
done <<'TARGETS'
install|install.sh|
install-dry|install.sh|--dry-run
update|install.sh|--update
force|install.sh|--force
packages|install-packages.sh|
test|test-dotfiles.sh|
test-all|test-dotfiles.sh|
test-quick|test-dotfiles.sh|--quick
test-integration|test-dotfiles.sh|--integration
test-zsh|test-dotfiles.sh|--zsh
test-vim|test-dotfiles.sh|--vim
test-scripts|test-dotfiles.sh|--scripts
lint|test-dotfiles.sh|--lint
perf|test-dotfiles.sh|--performance
security|security-audit.sh|
git-hooks|setup-pre-commit.sh|
mcp-atlassian-setup|mcpm-atlassian-keychain-setup.sh|
mcp-atlassian-migrate|mcpm-atlassian-migrate.sh|
TARGETS
for stub_status in 0 37; do
    run_case "make mcp-atlassian-test forwards exact arguments, wrapper exit $stub_status" \
        test_make_forwarding mcp-atlassian-test "$stub_status" mcpm run atlassian
done
run_case 'make backup and explicit restore preview/confirmed roundtrip' test_make_backup_restore
run_case 'make restore refuses omitted BACKUP even with an existing backup' test_make_restore_missing_backup
run_case 'make restore CONFIRM=yes still requires BACKUP' test_make_restore_missing_backup CONFIRM=yes
run_case 'make restore refuses empty BACKUP' test_make_restore_missing_backup BACKUP= CONFIRM=yes
run_case 'make clean lists logs without changing logs or backups' test_make_clean
run_case 'make list enumerates every explicit non-dot target' test_make_target_inventory list
run_case 'make help describes every explicit non-dot target' test_make_target_inventory help
for scenario in valid missing stale dangling real-file git-rev-failure git-branch-failure \
    git-status-failure worktree detached dirty no-remote; do
    run_case "make status: $scenario" test_make_status "$scenario"
done
for scenario in optional-absent bad-shell missing-git missing-zsh missing-vim missing-curl; do
    run_case "make doctor: $scenario" test_make_doctor "$scenario"
done
for scenario in generate replace symlink dangling-symlink directory find-failure; do
    run_case "make docs: $scenario" test_make_docs "$scenario"
done
while IFS='|' read -r platform scenario; do
    run_case "make fonts: $platform $scenario" test_make_fonts "$platform" "$scenario"
done <<'FONTS'
darwin|brew-success
darwin|brew-failure
darwin|fallback
linux|success
linux|xdg
linux|curl-failure
linux|unzip-failure
linux|cache-failure
linux|empty-archive
freebsd|unsupported
FONTS
while IFS='|' read -r platform distro scenario; do
    run_case "make dev-setup: $platform/$distro $scenario" test_make_dev_setup "$platform" "$distro" "$scenario"
done <<'DEVELOPMENT'
darwin|unknown|success
darwin|unknown|install-failure
linux|debian|success
linux|debian|update-failure
linux|debian|install-failure
linux|fedora|success
linux|fedora|install-failure
linux|arch|success
linux|arch|install-failure
linux|alpine|unsupported
freebsd|unknown|unsupported
DEVELOPMENT
printf '\nResults: %s passed; %s failed\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]]