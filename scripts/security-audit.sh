#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCAN_DIR="${1:-$REPO_DIR}"
for dependency in git rg jq; do
    command -v "$dependency" >/dev/null || { printf 'Required command missing: %s\n' "$dependency" >&2; exit 2; }
done
cd "$SCAN_DIR"
git rev-parse --show-toplevel >/dev/null

temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT
git ls-files -z --cached --others --exclude-standard > "$temporary/files"
errors=0
checked=0
key_pattern='(?:[a-z_][a-z0-9_]*[_-])?(?:password|secret|api[_-]?key|token|credentials|authorization)'
pattern="(?i)(?:\\b${key_pattern}\\s*=|[\"\\x27]${key_pattern}[\"\\x27]\\s*:|^\\s*${key_pattern}\\s*:)\\s*[\"\\x27]?([a-z0-9_+/=.:-]{8,})"
signature='(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[A-Z0-9]{16}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)'
placeholder='^(your[_-]|example|placeholder|dummy|test[_-]|changeme|x{8,}|ghp_x+|sk-x+|\*+|<)'

while IFS= read -r -d '' file; do
    [[ -e "$file" || -L "$file" ]] || continue
    if [[ -L "$file" ]]; then
        printf 'SKIP symlink (target not scanned): %s\n' "$file"
        continue
    fi
    [[ -f "$file" ]] || continue
    checked=$((checked + 1))
    case "$file" in
        .env|*/.env|.env.*|*/.env.*|.secrets/*|*/.secrets/*|*.pem|*.key|*.p12|*.pfx)
            printf 'REVIEW sensitive file in scan inventory: %s\n' "$file"
            errors=$((errors + 1)) ;;
    esac
    if rg --no-config --hidden --no-ignore --text --pcre2 -n -o -e "$pattern" -e "$signature" -- "$file" > "$temporary/matches"; then
        while IFS= read -r match; do
            line="${match%%:*}"
            value="${match#*:}"
            if ! printf '%s\n' "$value" | rg --no-config --pcre2 -q "$signature"; then
                value="$(printf '%s\n' "$value" | rg --no-config --pcre2 --replace '$1' -o "$pattern")"
                if printf '%s\n' "$value" | rg --no-config -iq "$placeholder"; then continue; fi
            fi
            printf 'REVIEW possible secret: %s:%s [REDACTED]\n' "$file" "$line"
            errors=$((errors + 1))
        done < "$temporary/matches"
    else
        exit_code=$?
        [[ "$exit_code" == 1 ]] || { printf 'Scan failed: %s\n' "$file" >&2; exit 2; }
    fi
    if [[ "$file" == *.json ]]; then
        if ! jq -e 'true' "$file" >/dev/null 2>&1; then
            printf 'REVIEW invalid JSON: %s\n' "$file"
            errors=$((errors + 1))
        elif jq -e '
            [.. | objects | to_entries[] |
             select(.key | test("(^|_)(password|secret|api_?key|token|credentials|authorization)$"; "i")) |
             select(.value | type == "string") |
             select(.value | length > 0) |
             select(.value | test("^(\\$|<|your[_-]|example|placeholder|dummy|test[_-]|changeme|x{8,})"; "i") | not)] |
            length > 0' "$file" >/dev/null 2>&1; then
            printf 'REVIEW JSON credential field: %s [REDACTED]\n' "$file"
            errors=$((errors + 1))
        fi
    fi
done < "$temporary/files"

for private_path in .secrets/probe.env local/local.zsh local/machine.info config/mcpm/servers.local.json; do
    if ! git check-ignore --no-index -q -- "$private_path"; then
        printf 'REVIEW missing ignore coverage: %s\n' "$private_path"
        errors=$((errors + 1))
    fi
done
printf 'Scanned %s working-tree files; %s findings. Values redacted.\n' "$checked" "$errors"
printf 'Heuristic scan only; ignored untracked files, Git history, and live host permissions are not audited.\n'
[[ "$errors" == 0 ]]