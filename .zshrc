# ~/.zshrc - Main configuration file

# Prevent double-loading
export ZSHRC_LOADED=1

# Skip insecure directory warnings (common on Linux with mixed ownership)
export ZSH_DISABLE_COMPFIX=true

# History configuration
export HISTFILE="$XDG_DATA_HOME/zsh/history"
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
setopt CORRECT              # spell correction for commands
setopt CORRECT_ALL          # spell correction for all arguments
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
for config in "$ZDOTDIR"/{os-detection,exports,package-manager,prompt,aliases,functions,completions,vi-mode,history,python,version-managers,plugins,fzf,dev-tools,ssh-config,local}.zsh; do
    [[ -r "$config" ]] && source "$config"
done

# Package manager environment setup (after os-detection is loaded)
if command -v is_macos >/dev/null && is_macos 2>/dev/null; then
    # macOS - Homebrew is the standard package manager
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon macOS
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        # Intel macOS
        eval "$(/usr/local/bin/brew shellenv)"
    fi
elif command -v is_linux >/dev/null && is_linux 2>/dev/null; then
    # Linux - Native package managers don't need shellenv setup
    # Only set up Homebrew if explicitly installed by user
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
fi

# Initialize completions (after all config loaded)
autoload -Uz compinit

# Cross-platform completion loading (simplified for reliability)
if [[ -n "~/.zcompdump"(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Load version managers last (lazy loading)
[[ -f "$ZDOTDIR/version-managers.zsh" ]] && source "$ZDOTDIR/version-managers.zsh"

# Load local configurations (machine-specific)
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# Set up completion menu bindings after everything is loaded
if typeset -f setup_menuselect_bindings > /dev/null; then
    setup_menuselect_bindings
fi

# Performance monitoring (uncomment to debug startup time)
# if [[ -n "${ZSH_PROF:-}" ]]; then
#     zprof
# fi
