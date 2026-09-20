#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"

if [[ "${1:-}" != --isolated ]]; then
    TEST_ROOT="$(mktemp -d /tmp/dotfiles-security.XXXXXX)"
    trap 'rm -rf "$TEST_ROOT"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    mkdir -p "$TEST_ROOT/home with spaces" "$TEST_ROOT/tmp" "$TEST_ROOT/tools"
    for dependency in jq rg git zsh; do
        executable="$(PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin command -v "$dependency")" || {
            printf 'BLOCKED: missing dependency: %s\n' "$dependency" >&2
            exit 2
        }
        ln -s "$executable" "$TEST_ROOT/tools/$dependency"
    done
    ln -s "$BASH" "$TEST_ROOT/tools/bash"
    exit_code=0
    env -i HOME="$TEST_ROOT/home with spaces" TMPDIR="$TEST_ROOT/tmp" \
        PATH="$TEST_ROOT/tools:/usr/bin:/bin:/usr/sbin:/sbin" USER=fixture LOGNAME=fixture \
        SHELL=/bin/zsh LC_ALL=C GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
        "$BASH" --noprofile --norc "$SCRIPT_DIR/test-security.sh" --isolated "$TEST_ROOT" || exit_code=$?
    exit "$exit_code"
fi

TEST_ROOT="${2:?Missing temporary root}"
[[ "$TEST_ROOT" == /tmp/dotfiles-security.* && -d "$TEST_ROOT" && ! -L "$TEST_ROOT" && \
    "$HOME" == "$TEST_ROOT/home with spaces" && "$TMPDIR" == "$TEST_ROOT/tmp" ]] || exit 2
umask 077
TOOLS="$TEST_ROOT/tools"
PLATFORM="$(uname -s)"
ZSH="$TOOLS/zsh"
PASSED=0
FAILED=0
TOTAL=0

fail() {
    printf 'ASSERTION FAILED: %s\n' "$*" >&2
    exit 1
}

expect_failure() {
    local result=0
    "$@" || result=$?
    [[ "$result" -ne 0 ]] || fail 'Command unexpectedly succeeded'
}

assert_equal_files() {
    cmp -s "$1" "$2" || fail "Files differ: ${3:-fixture}"
}

file_mode() {
    if [[ "$PLATFORM" == Darwin ]]; then stat -f '%Lp' "$1"; else stat -c '%a' "$1"; fi
}

snapshot() {
    local root="$1" entry
    find "$root" -print | LC_ALL=C sort | while IFS= read -r entry; do
        printf '%s\n' "${entry#"$root"}"
        if [[ -L "$entry" ]]; then
            readlink "$entry"
        elif [[ -f "$entry" ]]; then
            file_mode "$entry"
            cksum < "$entry"
        elif [[ -d "$entry" ]]; then
            file_mode "$entry"
        else
            fail 'Unexpected fixture entry'
        fi
    done
}

zrun() {
    local code="$1"
    shift
    "$ZSH" -dfc 'source "$1"; shift; eval "$1"' security-test "$REPO_DIR/config/zsh/secrets.zsh" "$code" "$@"
}

new_fixture() {
    FIXTURE="$CASE_DIR/fixture with spaces"
    HOME="$FIXTURE/home with spaces"
    export HOME
    export ZDOTDIR="$HOME" XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache"
    export PATH="$CASE_DIR/bin:$TOOLS:/usr/bin:/bin:/usr/sbin:/sbin"
    export PROVIDER_VALUE='dummy provider output' PROVIDER_RESULT=0
    export STUB_LOG="$CASE_DIR/provider calls"
    mkdir -p "$HOME" "$CASE_DIR/bin" "$FIXTURE/external"
    : > "$STUB_LOG"
    cat > "$CASE_DIR/bin/provider" <<'STUB'
#!/bin/bash
set -euo pipefail
printf '%s\n' "${0##*/}" >> "$STUB_LOG"
printf '%s' "$PROVIDER_VALUE"
exit "$PROVIDER_RESULT"
STUB
    chmod 700 "$CASE_DIR/bin/provider"
    local provider
    for provider in pass op security secret-tool; do
        ln -s provider "$CASE_DIR/bin/$provider"
    done
    printf '#!/bin/bash\nexit 97\n' > "$CASE_DIR/bin/uvx"
    chmod 700 "$CASE_DIR/bin/uvx"
}

run_case() {
    local label="$1" result
    shift
    TOTAL=$((TOTAL + 1))
    CASE_DIR="$TEST_ROOT/case $TOTAL"
    mkdir "$CASE_DIR"
    set +e
    (set -e; new_fixture; "$@") > "$CASE_DIR/output" 2>&1
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

seed_store() {
    printf '%s' 'dummy existing value' | zrun 'secret_add FIXTURE_VALUE' > /dev/null
}

test_literal_roundtrip() {
    printf '%s\n\n\n' 'literal $(touch "$HOME/command executed") `touch "$HOME/backtick executed"` "quoted" \ slash; ${HOME} * ~' > "$CASE_DIR/expected"
    zrun 'secret_add FIXTURE_VALUE' < "$CASE_DIR/expected" > /dev/null
    zrun 'secret_load FIXTURE_VALUE && print -rn -- "$FIXTURE_VALUE"' > "$CASE_DIR/actual"
    assert_equal_files "$CASE_DIR/expected" "$CASE_DIR/actual" 'literal bytes and trailing newlines'
    [[ ! -e "$HOME/command executed" && ! -e "$HOME/backtick executed" ]] || fail 'Secret was executed'
    [[ "$(file_mode "$HOME/.secrets")" == 700 && "$(file_mode "$HOME/.secrets/env.json")" == 600 ]] || fail 'Store permissions'
    zrun 'secret_list' > "$CASE_DIR/list"
    printf 'FIXTURE_VALUE\n' > "$CASE_DIR/keys"
    assert_equal_files "$CASE_DIR/keys" "$CASE_DIR/list" 'key-only list'
    printf '%s' 'dummy retained value' | zrun 'secret_add RETAINED' > /dev/null
    zrun 'secret_remove FIXTURE_VALUE' > /dev/null
    jq -e '. == {"RETAINED":"dummy retained value"}' "$HOME/.secrets/env.json" > /dev/null
    expect_failure zrun 'secret_load FIXTURE_VALUE'
}

test_startup() {
    if [[ "$1" == existing ]]; then
        seed_store
        printf 'touch "$HOME/legacy executed"\nexport FIXTURE_AUTO=executed\n' > "$HOME/.secrets/env"
    fi
    snapshot "$HOME" > "$CASE_DIR/before"
    zrun '[[ -z ${FIXTURE_AUTO+x} && -z ${FIXTURE_VALUE+x} ]]'
    snapshot "$HOME" > "$CASE_DIR/after"
    assert_equal_files "$CASE_DIR/before" "$CASE_DIR/after" 'startup must not write or execute legacy env'
    [[ ! -s "$STUB_LOG" ]] || fail 'Startup contacted a provider'
}

test_invalid_names() {
    seed_store
    snapshot "$HOME" > "$CASE_DIR/before"
    zrun '
        for name in "" 1BAD BAD-NAME "BAD;touch injected" "BAD=VALUE" "BAD[1]"; do
            for operation in secret_add secret_load secret_remove; do
                "$operation" "$name" </dev/null && exit 80
            done
            for operation in secret_from_pass secret_from_1password secret_from_keychain secret_from_keyring; do
                if [[ "$operation" == secret_from_keyring ]]; then OSTYPE=linux-gnu; else OSTYPE=darwin; fi
                "$operation" "$name" fixture-service && exit 81
            done
        done
        secret_add FIXTURE_VALUE "dummy forbidden argument" && exit 82
        exit 0
    '
    snapshot "$HOME" > "$CASE_DIR/after"
    assert_equal_files "$CASE_DIR/before" "$CASE_DIR/after" 'invalid name rejection'
    [[ ! -s "$STUB_LOG" ]] || fail 'Invalid name reached provider'
}

test_store_rejection() {
    seed_store
    case "$1" in
        directory-link) mv "$HOME/.secrets" "$FIXTURE/external/store"; ln -s "$FIXTURE/external/store" "$HOME/.secrets" ;;
        file-link) mv "$HOME/.secrets/env.json" "$FIXTURE/external/store.json"; ln -s "$FIXTURE/external/store.json" "$HOME/.secrets/env.json" ;;
        directory-mode) chmod 755 "$HOME/.secrets" ;;
        file-mode) chmod 644 "$HOME/.secrets/env.json" ;;
        malformed) printf '{invalid\n' > "$HOME/.secrets/env.json" ;;
        invalid-key) printf '{"BAD-NAME":"dummy value"}\n' > "$HOME/.secrets/env.json" ;;
        nonstring) printf '{"FIXTURE_VALUE":42}\n' > "$HOME/.secrets/env.json" ;;
        *) fail 'Unknown store rejection case' ;;
    esac
    snapshot "$FIXTURE" > "$CASE_DIR/before"
    expect_failure zrun 'secret_load FIXTURE_VALUE'
    expect_failure zrun 'secret_add FIXTURE_VALUE' < /dev/null
    expect_failure zrun 'secret_remove FIXTURE_VALUE'
    expect_failure zrun 'secret_list'
    snapshot "$FIXTURE" > "$CASE_DIR/after"
    assert_equal_files "$CASE_DIR/before" "$CASE_DIR/after" 'rejected store must remain unchanged'
}

test_provider_failure() {
    export PROVIDER_RESULT=73
    export TEST_OPERATION="$1"
    zrun '
        if [[ "$TEST_OPERATION" == secret_from_keyring ]]; then OSTYPE=linux-gnu; else OSTYPE=darwin; fi
        export FIXTURE_VALUE="dummy original value"
        "$TEST_OPERATION" FIXTURE_VALUE fixture-service && exit 80
        [[ "$FIXTURE_VALUE" == "dummy original value" ]]
    '
    [[ "$(wc -l < "$STUB_LOG" | tr -d ' ')" == 1 ]] || fail 'Expected one failed provider call'
}

write_migration_fixture() {
    export MCPM_SERVERS_FILE="$HOME/.config/mcpm/server config.json"
    export MCPM_BACKUP_DIR="$HOME/.config/mcpm/private backups"
    mkdir -p "$MCPM_BACKUP_DIR"
    jq -n --arg value "$PROVIDER_VALUE" --argjson confluence "$1" '
        {
            other: {command: "fixture-command", args: ["unchanged"], env: {FIXTURE: "keep"}},
            atlassian: {
                command: "old-command",
                args: ["--jira-url=https://jira.example.invalid", "--jira-username=fixture-user",
                    "--jira-personal-token=" + $value, "--confluence-api-token=" + $value],
                env: {
                    JIRA_API_TOKEN: $value, JIRA_PERSONAL_TOKEN: $value,
                    CONFLUENCE_API_TOKEN: $value, CONFLUENCE_PERSONAL_TOKEN: $value,
                    READ_ONLY_MODE: "false", ENABLED_TOOLS: "jira_create_issue"
                }
            }
        }
        | if $confluence then .atlassian.env += {
            CONFLUENCE_URL: "https://wiki.example.invalid", CONFLUENCE_USERNAME: "fixture-user",
            ATL_MCP_CONFLUENCE_TOKEN_SERVICE: "fixture confluence service",
            ATL_MCP_JIRA_TOKEN_SERVICE: "fixture jira service"
        } else . end
    ' > "$MCPM_SERVERS_FILE"
    chmod 644 "$MCPM_SERVERS_FILE"
}

migrate() {
    "$BASH" --noprofile --norc "$SCRIPT_DIR/mcpm-atlassian-migrate.sh" < /dev/null
}

test_migration() {
    write_migration_fixture "$1"
    cp "$MCPM_SERVERS_FILE" "$CASE_DIR/original"
    migrate > "$CASE_DIR/migration output"
    [[ "$(file_mode "$MCPM_SERVERS_FILE")" == 600 && "$(file_mode "$MCPM_BACKUP_DIR")" == 700 ]] || fail 'Migration permissions'
    set -- "$MCPM_BACKUP_DIR"/servers.json.*
    [[ "$#" -eq 1 && -f "$1" && ! -L "$1" && "$(file_mode "$1")" == 600 ]] || fail 'Expected one private regular backup'
    assert_equal_files "$CASE_DIR/original" "$1" 'migration backup preserves original bytes'
    jq -e --slurpfile original "$CASE_DIR/original" --arg value "$PROVIDER_VALUE" '
        .other == $original[0].other
        and .atlassian.command == "/bin/zsh"
        and .atlassian.args == ["-fc", "exec \"$HOME/.local/bin/mcpm-atlassian-secure\""]
        and .atlassian.env.JIRA_URL == "https://jira.example.invalid"
        and .atlassian.env.JIRA_USERNAME == "fixture-user"
        and .atlassian.env.READ_ONLY_MODE == "true"
        and .atlassian.env.ENABLED_TOOLS == "jira_search,jira_get_issue"
        and ([.atlassian.env | keys[] | select(test("^(JIRA|CONFLUENCE)_(API|PERSONAL)_TOKEN$"))] | length == 0)
        and ([.. | strings | select(contains($value))] | length == 0)
        and (if $original[0].atlassian.env.CONFLUENCE_URL then
            .atlassian.env.CONFLUENCE_URL == "https://wiki.example.invalid"
            and .atlassian.env.CONFLUENCE_USERNAME == "fixture-user"
            and .atlassian.env.ATL_MCP_CONFLUENCE_TOKEN_SERVICE == "fixture confluence service"
            and .atlassian.env.ATL_MCP_JIRA_TOKEN_SERVICE == "fixture jira service"
        else
            (.atlassian.env | has("CONFLUENCE_URL") or has("CONFLUENCE_USERNAME") | not)
            and .atlassian.env.ATL_MCP_JIRA_TOKEN_SERVICE == "atl_mcp_jira_token"
        end)
    ' "$MCPM_SERVERS_FILE" > /dev/null
    [[ -z "$(find "$HOME" -name '.servers.*' -print)" ]] || fail 'Migration staging file leaked'
}

test_migration_rejection() {
    write_migration_fixture false
    case "$1" in
        input-link)
            mv "$MCPM_SERVERS_FILE" "$FIXTURE/external/original.json"
            ln -s "$FIXTURE/external/original.json" "$MCPM_SERVERS_FILE"
            ;;
        backup-link)
            mv "$MCPM_BACKUP_DIR" "$FIXTURE/external/backups"
            ln -s "$FIXTURE/external/backups" "$MCPM_BACKUP_DIR"
            ;;
        malformed) printf '{invalid\n' > "$MCPM_SERVERS_FILE" ;;
        missing-jira) printf '{"atlassian":{"args":[],"env":{}}}\n' > "$MCPM_SERVERS_FILE" ;;
        *) fail 'Unknown migration rejection case' ;;
    esac
    cp "$MCPM_SERVERS_FILE" "$CASE_DIR/original"
    snapshot "$FIXTURE" > "$CASE_DIR/before"
    expect_failure migrate > "$CASE_DIR/migration output" 2>&1
    assert_equal_files "$CASE_DIR/original" "$MCPM_SERVERS_FILE" 'rejected migration preserves original bytes'
    snapshot "$FIXTURE" > "$CASE_DIR/after"
    assert_equal_files "$CASE_DIR/before" "$CASE_DIR/after" 'rejected migration preserves links, referents and permissions'
}

install_keychain_stubs() {
    export SECURITY_LOG="$CASE_DIR/security calls.jsonl" UVX_LOG="$CASE_DIR/uvx call.json"
    export ADD_RESULT=0 JIRA_RESULT=0 CONF_RESULT=0 UVX_RESULT=0
    export JIRA_VALUE='dummy jira from keychain' CONF_VALUE='dummy confluence from keychain'
    export ATL_MCP_JIRA_TOKEN_SERVICE='fixture jira service'
    export ATL_MCP_CONFLUENCE_TOKEN_SERVICE='fixture confluence service'
    : > "$SECURITY_LOG"
    rm "$CASE_DIR/bin/security"
    cat > "$CASE_DIR/bin/security" <<'STUB'
#!/bin/bash
set -euo pipefail
jq -cn --args '$ARGS.positional' -- "$@" >> "$SECURITY_LOG"
case "${1:-}" in
    add-generic-password) exit "$ADD_RESULT" ;;
    find-generic-password)
        [[ "$#" -eq 4 && "$2" == -s && "$4" == -w ]] || exit 96
        if [[ "$3" == "$ATL_MCP_JIRA_TOKEN_SERVICE" ]]; then
            [[ "$JIRA_RESULT" -eq 0 ]] || exit "$JIRA_RESULT"
            printf '%s' "$JIRA_VALUE"
        elif [[ "$3" == "$ATL_MCP_CONFLUENCE_TOKEN_SERVICE" ]]; then
            [[ "$CONF_RESULT" -eq 0 ]] || exit "$CONF_RESULT"
            printf '%s' "$CONF_VALUE"
        else
            exit 95
        fi
        ;;
    *) exit 94 ;;
esac
STUB
    cat > "$CASE_DIR/bin/uvx" <<'STUB'
#!/bin/bash
set -euo pipefail
jq -n --args '{args: $ARGS.positional, env: (env | with_entries(
    select(.key | test("^(JIRA_|CONFLUENCE_|READ_ONLY_MODE$|ENABLED_TOOLS$)"))))}' -- "$@" > "$UVX_LOG"
exit "$UVX_RESULT"
STUB
    chmod 700 "$CASE_DIR/bin/security" "$CASE_DIR/bin/uvx"
}

test_keychain_setup() {
    install_keychain_stubs
    export OSTYPE=darwin
    local scenario="$1" result=0 expected_result=0
    if [[ "$scenario" == optional || "$scenario" == optional-failure ]]; then
        printf 'custom confluence service\ncustom jira service\ny\n' > "$CASE_DIR/answers"
    else
        unset ATL_MCP_CONFLUENCE_TOKEN_SERVICE ATL_MCP_JIRA_TOKEN_SERVICE
        printf '\n\nn\n' > "$CASE_DIR/answers"
    fi
    case "$scenario" in
        *-failure) export ADD_RESULT=73; expected_result=73 ;;
    esac
    "$BASH" --noprofile --norc "$SCRIPT_DIR/mcpm-atlassian-keychain-setup.sh" \
        < "$CASE_DIR/answers" > "$CASE_DIR/setup output" 2>&1 || result=$?
    [[ "$result" -eq "$expected_result" ]] || fail 'Setup did not propagate security status'
    case "$scenario" in
        optional)
            jq -se --arg account "$USER" '. == [
                ["add-generic-password","-U","-a",$account,"-s","custom confluence service","-T","","-w"],
                ["add-generic-password","-U","-a",$account,"-s","custom jira service","-T","","-w"]
            ]' "$SECURITY_LOG" > /dev/null
            ;;
        optional-failure)
            jq -se --arg account "$USER" '. == [
                ["add-generic-password","-U","-a",$account,"-s","custom confluence service","-T","","-w"]
            ]' "$SECURITY_LOG" > /dev/null
            ;;
        *)
            jq -se --arg account "$USER" '. == [
                ["add-generic-password","-U","-a",$account,"-s","atl_mcp_jira_token","-T","","-w"]
            ]' "$SECURITY_LOG" > /dev/null
            ;;
    esac
    if [[ "$expected_result" -ne 0 ]]; then
        if rg -q 'Stored Keychain secrets' "$CASE_DIR/setup output"; then fail 'Setup reported false success'; fi
    fi
}

test_keychain_add() {
    install_keychain_stubs
    if [[ "$1" == failure ]]; then
        export ADD_RESULT=73
        expect_failure zrun 'OSTYPE=darwin; keychain_add "fixture service with spaces"' > "$CASE_DIR/add output" 2>&1
        if rg -q 'Secret added' "$CASE_DIR/add output"; then fail 'keychain_add reported false success'; fi
    elif [[ "$1" == invalid ]]; then
        expect_failure zrun 'OSTYPE=darwin; keychain_add'
        expect_failure zrun 'OSTYPE=darwin; keychain_add ""'
        expect_failure zrun 'OSTYPE=darwin; keychain_add fixture-service "dummy forbidden value"'
        [[ ! -s "$SECURITY_LOG" ]] || fail 'Invalid keychain_add reached security'
        return
    else
        zrun 'OSTYPE=darwin; keychain_add "fixture service with spaces"' > "$CASE_DIR/add output"
    fi
    jq -se --arg account "$USER" '. == [
        ["add-generic-password","-U","-s","fixture service with spaces","-a",$account,"-T","","-w"]
    ]' "$SECURITY_LOG" > /dev/null
}

test_launcher() {
    install_keychain_stubs
    export JIRA_URL=https://jira.example.invalid CONFLUENCE_URL=https://wiki.example.invalid
    export CONFLUENCE_USERNAME=fixture-user
    export JIRA_API_TOKEN='dummy inherited api value' JIRA_PERSONAL_TOKEN='dummy inherited personal value'
    export CONFLUENCE_API_TOKEN='dummy inherited api value' CONFLUENCE_PERSONAL_TOKEN='dummy inherited personal value'
    local scenario="$1" result=0 expected_result=0 expected_calls=2
    case "$scenario" in
        no-confluence) unset CONFLUENCE_URL; expected_calls=1 ;;
        missing-confluence) export CONF_RESULT=44 ;;
        empty-confluence) export CONF_VALUE='' ;;
        missing-jira) export JIRA_RESULT=45; expected_result=1; expected_calls=1 ;;
        empty-jira) export JIRA_VALUE=''; expected_result=1; expected_calls=1 ;;
        uvx-failure) export UVX_RESULT=72; expected_result=72 ;;
        available) ;;
        *) fail 'Unknown launcher case' ;;
    esac
    "$ZSH" -df "$SCRIPT_DIR/mcpm-atlassian-secure.sh" > "$CASE_DIR/launcher output" 2>&1 || result=$?
    [[ "$result" -eq "$expected_result" ]] || fail 'Launcher exit status'
    jq -se --argjson count "$expected_calls" --arg jira "$ATL_MCP_JIRA_TOKEN_SERVICE" \
        --arg confluence "$ATL_MCP_CONFLUENCE_TOKEN_SERVICE" '
        . == ([["find-generic-password","-s",$jira,"-w"],
            ["find-generic-password","-s",$confluence,"-w"]] | .[:$count])
    ' "$SECURITY_LOG" > /dev/null
    if [[ "$scenario" == missing-jira || "$scenario" == empty-jira ]]; then
        [[ ! -e "$UVX_LOG" ]] || fail 'Launcher started uvx without Jira credentials'
        return
    fi
    jq -e --arg jira "$JIRA_VALUE" '
        .args == ["--with", "mcp==1.30.0", "mcp-atlassian==0.23.1"]
        and .env.JIRA_URL == "https://jira.example.invalid"
        and .env.JIRA_PERSONAL_TOKEN == $jira
        and .env.READ_ONLY_MODE == "true"
        and .env.ENABLED_TOOLS == "jira_search,jira_get_issue"
        and (.env | has("JIRA_API_TOKEN") or has("CONFLUENCE_API_TOKEN") | not)
    ' "$UVX_LOG" > /dev/null
    case "$scenario" in
        no-confluence|missing-confluence|empty-confluence)
            jq -e '.env | (has("CONFLUENCE_URL") or has("CONFLUENCE_USERNAME")) | not' "$UVX_LOG" > /dev/null
            jq -e '.env.CONFLUENCE_PERSONAL_TOKEN // "" | . == ""' "$UVX_LOG" > /dev/null
            ;;
        *)
            jq -e --arg confluence "$CONF_VALUE" '
                .env.CONFLUENCE_URL == "https://wiki.example.invalid"
                and .env.CONFLUENCE_USERNAME == "fixture-user"
                and .env.CONFLUENCE_PERSONAL_TOKEN == $confluence
            ' "$UVX_LOG" > /dev/null
            ;;
    esac
}

test_audit() {
    local scenario="$1" repo="$FIXTURE/audit repo with spaces" result=0 expected_result=1 findings=0
    local canary json_value assignment_value
    canary="$(printf 'gh%s_' p)$(printf '%036d' 0)"
    json_value="$(printf '%s %s' audit canary)"
    assignment_value="$(printf '%s%s' audit canary)"
    mkdir -p "$repo/scripts" "$repo/.hidden ignored" "$CASE_DIR/empty git template"
    git -c init.defaultBranch=fixture -c core.hooksPath=/dev/null init --quiet \
        --template="$CASE_DIR/empty git template" "$repo"
    printf '%s\n' '.secrets/' 'local/local.zsh' 'local/machine.info' \
        'config/mcpm/servers.local.json' '.hidden ignored/' > "$repo/.gitignore"
    cp "$SCRIPT_DIR/security-audit.sh" "$SCRIPT_DIR/test-security.sh" "$repo/scripts/"
    printf '%s\n' "$canary" > "$repo/.hidden ignored/untracked.txt"
    if [[ "$scenario" == hidden || "$scenario" == combined ]]; then
        printf '%s\n' "$canary" > "$repo/.hidden ignored/tracked.txt"
        git -C "$repo" -c core.hooksPath=/dev/null add -f -- '.hidden ignored/tracked.txt'
        git -C "$repo" check-ignore --no-index -q -- '.hidden ignored/tracked.txt'
        findings=$((findings + 1))
    fi
    if [[ "$scenario" == json || "$scenario" == combined ]]; then
        jq -n --arg value "$json_value" '{nested: {credentials: $value}}' > "$repo/credential fixture.json"
        findings=$((findings + 1))
    fi
    case "$scenario" in
        shell-assignment)
            printf 'export API_%s=%s\n' KEY "$assignment_value" > "$repo/assignment.txt"
            findings=$((findings + 1)) ;;
        yaml-assignment)
            printf '  api_%s: %s\n' key "$assignment_value" > "$repo/assignment.txt"
            findings=$((findings + 1)) ;;
        json-assignment)
            printf '{"api_%s": "%s"}\n' key "$assignment_value" > "$repo/assignment.txt"
            findings=$((findings + 1)) ;;
        prose)
            printf '%s\n' 'Backups can contain credentials: restrict access and retire them.' > "$repo/guide.md"
            expected_result=0 ;;
        clean) expected_result=0 ;;
    esac
    "$BASH" --noprofile --norc "$repo/scripts/security-audit.sh" "$repo" > "$CASE_DIR/audit output" 2>&1 || result=$?
    [[ "$result" -eq "$expected_result" ]] || fail 'Audit exit status'
    rg -q -F "$findings findings. Values redacted." "$CASE_DIR/audit output" || fail 'Audit finding count'
    if [[ "$scenario" == hidden || "$scenario" == combined ]]; then
        rg -q -F 'REVIEW possible secret: .hidden ignored/tracked.txt:1 [REDACTED]' "$CASE_DIR/audit output" || fail 'Hidden tracked ignored canary was missed'
    fi
    if [[ "$scenario" == json || "$scenario" == combined ]]; then
        rg -q -F 'REVIEW JSON credential field: credential fixture.json [REDACTED]' "$CASE_DIR/audit output" || fail 'Structured JSON credential was missed'
    fi
    printf '%s\n' "$canary" "$json_value" "$assignment_value" > "$CASE_DIR/forbidden output"
    if rg -q -F -f "$CASE_DIR/forbidden output" "$CASE_DIR/audit output"; then fail 'Audit exposed a secret value'; fi
    if rg -q -F 'untracked.txt' "$CASE_DIR/audit output"; then fail 'Audit scanned ignored untracked content'; fi
}

run_case 'secrets: literal roundtrip, trailing newlines, list and remove' test_literal_roundtrip
run_case 'secrets: empty startup is read-only' test_startup empty
run_case 'secrets: legacy env is not executed or auto-loaded' test_startup existing
run_case 'secrets: invalid names and value arguments rejected' test_invalid_names
for scenario in directory-link file-link directory-mode file-mode malformed invalid-key nonstring; do
    run_case "secrets: reject $scenario without writes" test_store_rejection "$scenario"
done
for provider in secret_from_pass secret_from_1password secret_from_keychain secret_from_keyring; do
    run_case "secrets: $provider propagates failure without export" test_provider_failure "$provider"
done
run_case 'migration: regular input, private backup and optional Confluence absent' test_migration false
run_case 'migration: retain optional Confluence configuration' test_migration true
for scenario in input-link backup-link malformed missing-jira; do
    run_case "migration: reject $scenario and preserve original" test_migration_rejection "$scenario"
done
for scenario in default optional default-failure optional-failure; do
    run_case "keychain setup: $scenario, prompt-only argv" test_keychain_setup "$scenario"
done
for scenario in success invalid failure; do
    run_case "keychain_add: $scenario, prompt-only argv" test_keychain_add "$scenario"
done
for scenario in available no-confluence missing-confluence empty-confluence missing-jira empty-jira uvx-failure; do
    run_case "launcher: $scenario, pinned package and restricted defaults" test_launcher "$scenario"
done
for scenario in clean hidden json combined shell-assignment yaml-assignment json-assignment prose; do
    run_case "audit: $scenario, temporary Git inventory and redacted output" test_audit "$scenario"
done

printf '\nResults: %s passed, %s failed, %s total (Bash %s)\n' "$PASSED" "$FAILED" "$TOTAL" "$BASH_VERSION"
[[ "$FAILED" -eq 0 ]]