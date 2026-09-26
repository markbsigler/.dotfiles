#!/usr/bin/env bash

set -u -o pipefail
umask 077
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export LC_ALL=C
unset CDPATH

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)" || exit 1
PASSED=0
FAILED=0
SKIPPED=0

usage() {
    printf '%s\n' \
        "Usage: ${0##*/} [--quick|--zsh|--scripts|--vim|--lint|--integration|--performance]" \
        'No arguments: run all checks.' \
        '--quick: required files and all shell syntax (no configuration execution).' \
        '--zsh: syntax of Zsh configs and scripts, including hidden startup files.' \
        '--scripts: syntax of shell scripts, using their declared interpreter.' \
        '--vim: isolated Vim and, when available, Neovim startup without installed plugins.' \
        '--lint: ShellCheck at warning severity; required, and excludes Zsh.' \
        '--integration: isolated safety/security suites and OS detection only.' \
        '--performance: report benchmark availability; never start a live shell.'
}

if [[ "$#" -gt 1 ]]; then
    usage >&2
    exit 2
fi
MODE="${1:---all}"
case "$MODE" in
    -h|--help) usage; exit 0 ;;
    --all|--quick|--zsh|--scripts|--vim|--lint|--integration|--performance) ;;
    *) usage >&2; exit 2 ;;
esac

TEST_ROOT="$(mktemp -d /tmp/dotfiles-validation.XXXXXX)" || exit 1
trap 'rm -rf -- "$TEST_ROOT"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/tmp" || exit 1

fail() {
    FAILED=$((FAILED + 1))
    printf 'FAIL %s\n' "$*" >&2
}

check() {
    local label="$1"
    shift
    if "$@"; then
        PASSED=$((PASSED + 1))
        printf 'PASS %s\n' "$label"
    else
        fail "$label"
    fi
}

isolated() {
    local home="$1"
    shift
    (
        cd "$home" || exit 1
        env -i HOME="$home" ZDOTDIR="$home" \
            XDG_CONFIG_HOME="$home/.config" XDG_DATA_HOME="$home/.local/share" \
            XDG_CACHE_HOME="$home/.cache" XDG_STATE_HOME="$home/.local/state" \
            TMPDIR="$TEST_ROOT/tmp" PATH="$PATH" LC_ALL=C TERM=dumb \
            USER=fixture LOGNAME=fixture SHELL=/bin/zsh \
            GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$@" < /dev/null
    )
}

test_structure() {
    local file
    for file in install.sh config/zsh/.zshrc config/zsh/.zshenv config/zsh/.zprofile \
        config/zsh/os-detection.zsh config/vim/vimrc scripts/test-safety.sh scripts/test-security.sh; do
        check "required $file" test -f "$REPO_DIR/$file"
    done
}

shell_inventory() {
    find "$REPO_DIR" \( -name .git -o -name .secrets \) -prune -o \
        -type f \( -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.ksh' \
        -o -name '.zshrc' -o -name '.zshenv' -o -name '.zprofile' \
        -o -name '.zlogin' -o -name '.zlogout' -o -name '.bashrc' \
        -o -name '.bash_profile' -o -name '.bash_login' -o -name '.bash_logout' \
        -o -name '.bash_aliases' -o -name '.profile' -o -name '.kshrc' \) -print0
}

file_shell() {
    local file="$1" first_line=''
    [[ -r "$file" ]] || return 1
    IFS= read -r first_line < "$file" || true
    if [[ "$first_line" =~ ^#!.*(/|[[:space:]])(bash|zsh|sh|dash|ksh)([[:space:]]|$) ]]; then
        INTERPRETER="${BASH_REMATCH[2]}"
    else
        case "$first_line" in
            '#!'*) return 1 ;;
        esac
        case "$file" in
            *.zsh|*/.zshrc|*/.zshenv|*/.zprofile|*/.zlogin|*/.zlogout) INTERPRETER=zsh ;;
            *.ksh|*/.kshrc) INTERPRETER=ksh ;;
            */.profile) INTERPRETER='sh' ;;
            *) INTERPRETER=bash ;;
        esac
    fi
}

test_shells() {
    local mode="$1" file executable shellcheck_bin=''
    if [[ "$mode" == --lint ]]; then
        shellcheck_bin="$(type -P shellcheck)" || { fail 'ShellCheck is required for --lint'; return; }
    fi
    if ! shell_inventory > "$TEST_ROOT/shell-files"; then
        fail 'shell file discovery'
        return
    fi
    while IFS= read -r -d '' file; do
        if ! file_shell "$file"; then
            fail "unreadable file or unsupported shebang: ${file#"$REPO_DIR/"}"
            continue
        fi
        case "$mode" in
            --zsh) [[ "$INTERPRETER" == zsh ]] || continue ;;
            --scripts) [[ "$file" == *.sh || "$INTERPRETER" != zsh ]] || continue ;;
            --lint)
                if [[ "$INTERPRETER" == zsh ]]; then
                    SKIPPED=$((SKIPPED + 1))
                    printf 'SKIP ShellCheck (Zsh): %s\n' "${file#"$REPO_DIR/"}"
                    continue
                fi
                check "lint ${file#"$REPO_DIR/"}" isolated "$TEST_ROOT/home" \
                    "$shellcheck_bin" --norc -S warning -s "$INTERPRETER" "$file"
                continue
                ;;
        esac
        if [[ "$INTERPRETER" == bash ]]; then
            check "bash syntax ${file#"$REPO_DIR/"}" isolated "$TEST_ROOT/home" \
                "$BASH" --noprofile --norc -n "$file"
        elif executable="$(type -P "$INTERPRETER")"; then
            if [[ "$INTERPRETER" == zsh ]]; then
                check "zsh syntax ${file#"$REPO_DIR/"}" isolated "$TEST_ROOT/home" \
                    "$executable" -d -f -n "$file"
            else
                check "$INTERPRETER syntax ${file#"$REPO_DIR/"}" isolated "$TEST_ROOT/home" \
                    "$executable" -n "$file"
            fi
        else
            fail "missing $INTERPRETER for ${file#"$REPO_DIR/"}"
        fi
    done < "$TEST_ROOT/shell-files"
}

vim_fixture() {
    mkdir -p "$TEST_ROOT/vim-home/.vim/autoload" "$TEST_ROOT/vim-home/.vim/backup" \
        "$TEST_ROOT/vim-home/.vim/swap" "$TEST_ROOT/vim-home/.vim/undo" || return 1
    cat > "$TEST_ROOT/vim-home/.vim/autoload/plug.vim" <<'VIM' || return 1
function! plug#begin(...) abort
    command! -nargs=+ Plug let g:dotfiles_test_plugin_declared = 1
endfunction
function! plug#end(...) abort
endfunction
VIM
    cat > "$TEST_ROOT/vim-home/check.vim" <<'VIM'
set nomodeline noloadplugins eventignore=all
let &runtimepath = $HOME . '/.vim,' . $VIMRUNTIME
let &packpath = &runtimepath
try
    execute 'source ' . fnameescape($DOTFILES_VIMRC)
catch
    call writefile([v:exception, v:throwpoint], $HOME . '/errors')
    cquit 1
endtry
qa!
VIM
}

test_vim() {
    local executable result=0
    executable="$(type -P vim)" || { fail 'Vim is required for --vim'; return; }
    if ! vim_fixture; then
        fail 'Vim fixture setup'
        return
    fi
    isolated "$TEST_ROOT/vim-home" DOTFILES_VIMRC="$REPO_DIR/config/vim/vimrc" \
        "$executable" -Nu NONE -i NONE -n -es -Z -S "$TEST_ROOT/vim-home/check.vim" || result=$?
    if [[ -f "$TEST_ROOT/vim-home/errors" ]]; then
        cat "$TEST_ROOT/vim-home/errors" >&2
    fi
    check 'isolated vimrc (stubbed vim-plug; restricted mode)' test "$result" -eq 0

    if executable="$(type -P nvim)"; then
        mkdir -p "$TEST_ROOT/nvim-home" || { fail 'Neovim fixture setup'; return; }
        check 'isolated Neovim startup (no plugins)' isolated "$TEST_ROOT/nvim-home" \
            "$executable" --headless --noplugin -u "$REPO_DIR/config/nvim/init.vim" -i NONE -n '+qa!'
    else
        SKIPPED=$((SKIPPED + 1))
        printf '%s\n' 'SKIP isolated Neovim startup: nvim not installed'
    fi
}

test_integration() {
    local suite executable
    for suite in test-safety test-security; do
        if mkdir "$TEST_ROOT/$suite-home"; then
            check "$suite ($BASH)" isolated "$TEST_ROOT/$suite-home" \
                "$BASH" --noprofile --norc "$REPO_DIR/scripts/$suite.sh"
        else
            fail "$suite fixture setup"
        fi
    done
    executable="$(type -P zsh)" || { fail 'Zsh is required for OS detection'; return; }
    if ! mkdir "$TEST_ROOT/os-home"; then
        fail 'OS detection fixture setup'
        return
    fi
    check 'isolated Zsh OS detection' isolated "$TEST_ROOT/os-home" "$executable" -d -f -c '
        source "$1" || exit 1
        (( $+functions[is_macos] && $+functions[is_linux] )) || exit 1
        case "$(uname -s)" in
            Darwin*) [[ "$DOTFILES_OS" == macos ]] && is_macos && ! is_linux || exit 1 ;;
            Linux*) [[ "$DOTFILES_OS" == linux ]] && is_linux && ! is_macos || exit 1 ;;
            *) [[ -n "$DOTFILES_OS" ]] || exit 1 ;;
        esac
        [[ "$DOTFILES_ARCH" == "$(uname -m)" ]]
    ' os-detection-test "$REPO_DIR/config/zsh/os-detection.zsh"
}

test_performance() {
    SKIPPED=$((SKIPPED + 1))
    printf '%s\n' 'SKIP performance: unavailable until a dedicated opt-in isolated startup benchmark exists.'
}

case "$MODE" in
    --all)
        test_structure
        test_shells --all
        test_vim
        test_shells --lint
        test_integration
        test_performance
        ;;
    --quick) test_structure; test_shells --all ;;
    --zsh|--scripts|--lint) test_shells "$MODE" ;;
    --vim) test_vim ;;
    --integration) test_integration ;;
    --performance) test_performance ;;
esac

printf '\nResults: %s passed; %s failed; %s skipped (Bash %s)\n' "$PASSED" "$FAILED" "$SKIPPED" "$BASH_VERSION"
[[ "$FAILED" -eq 0 ]]
