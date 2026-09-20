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
        expected_zdotdir="${ZDOTDIR:-$expected_config/zsh}"
        export ZPROFILE_LOADED=1 ZSHRC_LOADED=1
        source "$1"
        [[ "$ZDOTDIR" == "$expected_zdotdir" ]]
        [[ "$XDG_CONFIG_HOME" == "$expected_config" && "$XDG_DATA_HOME" == "$expected_data" ]]
        [[ "$XDG_CACHE_HOME" == "$expected_cache" && "$XDG_STATE_HOME" == "$expected_state" ]]
        [[ "$HISTFILE" == "$expected_data/zsh/history" ]]
        [[ -z "${ZPROFILE_LOADED+x}" && -z "${ZSHRC_LOADED+x}" ]]
    ' safety-zshenv "$FIXTURE_REPO/config/zsh/.zshenv" "$1"
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
        make-success|make-failure)
            local git_result=0 result=0
            [[ "$scenario" != make-failure ]] || git_result=19
            printf '#!/bin/sh\nexit %s\n' "$git_result" > "$STUB_BIN/git"
            env -i HOME="$HOME" PATH="$STUB_BIN:/usr/bin:/bin" \
                /usr/bin/make -f "$REPO_DIR/Makefile" plugins || result=$?
            if [[ "$git_result" == 0 ]]; then
                [[ "$result" == 0 ]] || fail 'Plugin update failed after successful Git command'
            else
                [[ "$result" != 0 ]] || fail 'Plugin update masked failed Git command'
            fi
            ;;
        *) fail "Unknown updater scenario: $scenario" ;;
    esac
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
for platform in macos linux; do
    for scenario in missing empty fallback standard; do
        run_case "plugins: $platform $scenario without network or writes" test_plugins "$scenario" "$platform"
    done
done
for scenario in updater-dry updater-failure make-success make-failure; do
    run_case "plugin maintenance: $scenario with isolated commands" test_plugin_updates "$scenario"
done
printf '\nResults: %s passed; %s failed\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]]