#!/usr/bin/env zsh
# .zshrc in ZDOTDIR - Interactive shell configuration

# Prevent double-loading
[[ -n "$ZSHRC_LOADED" ]] && return
ZSHRC_LOADED=1

umask 077
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# History configuration
# HISTFILE is set in .zshenv for early availability
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry
setopt HIST_BEEP                 # Beep when accessing non-existent history

# Zsh options
setopt AUTO_CD              # cd by typing directory name if it's not a command
# Disable spell correction in VS Code, enable elsewhere
if [[ "$TERM_PROGRAM" != "vscode" ]] && [[ -z "$VSCODE_SIMPLE_PROMPT" ]]; then
    setopt CORRECT              # spell correction for commands
    setopt CORRECT_ALL          # spell correction for all arguments
fi
setopt AUTO_LIST            # automatically list choices on ambiguous completion
setopt AUTO_MENU            # automatically use menu completion
setopt ALWAYS_TO_END        # move cursor to end if word had one match
setopt COMPLETE_IN_WORD     # complete from both ends of a word
setopt COMPLETE_ALIASES     # complete alisases
setopt EXTENDED_GLOB        # use extended globbing syntax

# Additional modern options
setopt AUTO_PUSHD           # Push the current directory visited on the stack
setopt PUSHD_IGNORE_DUPS    # Don't push the same dir twice
setopt PUSHD_MINUS          # Reference stack entries with "-"
setopt GLOB_DOTS            # Include dotfiles in globbing
setopt NUMERIC_GLOB_SORT    # Sort filenames numerically
setopt HIST_EXPIRE_DUPS_FIRST  # Expire duplicate entries first
setopt HIST_FIND_NO_DUPS    # Don't display duplicates during search

# Load configurations in order (os-detection must be first)
# Use an explicit list to avoid relying on brace expansion being enabled
configs=(
    "$ZDOTDIR/os-detection.zsh"
    "$ZDOTDIR/vscode.zsh"
    "$ZDOTDIR/secrets.zsh"
    "$ZDOTDIR/exports.zsh"
    "$ZDOTDIR/package-manager.zsh"
    "$ZDOTDIR/aliases.zsh"
    "$ZDOTDIR/functions.zsh"
    "$ZDOTDIR/completions.zsh"
    "$ZDOTDIR/vi-mode.zsh"
    "$ZDOTDIR/history.zsh"
    "$ZDOTDIR/atuin.zsh"
    "$ZDOTDIR/python.zsh"
    "$ZDOTDIR/version-managers.zsh"
    "$ZDOTDIR/plugins.zsh"
    "$ZDOTDIR/fzf.zsh"
    "$ZDOTDIR/dev-tools.zsh"
    "$ZDOTDIR/ssh-config.zsh"
)

for config in "${configs[@]}"; do
    [[ -r "$config" ]] && source "$config"
done

# Package manager setup is handled in .zprofile for login shells
# This ensures PATH is set correctly before any other initialization

# Load local configurations (machine-specific)
[[ -f "${ZDOTDIR:A:h:h}/local/local.zsh" ]] && source "${ZDOTDIR:A:h:h}/local/local.zsh"

# Load prompt last to ensure it doesn't get overridden
[[ -f "$ZDOTDIR/prompt.zsh" ]] && source "$ZDOTDIR/prompt.zsh"

# Set up completion menu bindings after everything is loaded
if typeset -f setup_menuselect_bindings > /dev/null; then
    setup_menuselect_bindings
fi

# Performance monitoring (uncomment to debug startup time)
# if [[ -n "${ZSH_PROF:-}" ]]; then
#     zprof
# fi
# Added by Antigravity
add_to_path "/Users/msigler/.antigravity/antigravity/bin"

# Ensure PATH gets deduped on load and before each prompt
clean_path_once() {
    typeset -f clean_path >/dev/null 2>&1 && clean_path
}

clean_path_once
typeset -ga precmd_functions
precmd_functions+=clean_path_once

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/msigler/.lmstudio/bin"
# End of LM Studio CLI section


# opencode
export PATH=/Users/msigler/.opencode/bin:$PATH

# Added by git-ai installer on Sat May  9 13:46:35 EDT 2026
export PATH="/Users/msigler/.git-ai/bin:$PATH"

# Hermes Agent — ensure ~/.local/bin is on PATH
export PATH="$HOME/.local/bin:$PATH"
