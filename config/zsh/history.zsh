# History search and navigation enhancements

# Enhanced history search with arrow keys
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search   # Up arrow
bindkey "^[[B" down-line-or-beginning-search # Down arrow

# Additional useful keybindings
bindkey "^R" history-incremental-search-backward  # Ctrl+R for reverse search
bindkey "^S" history-incremental-search-forward   # Ctrl+S for forward search

# Ensure Ctrl+S works (disable flow control)
stty -ixon

# History navigation aliases
alias h='history'
alias hg='history | grep'
alias hs='history | grep -i'  # case insensitive

# Advanced history functions
# Show most used commands
hist_top() {
    history | awk '{print $2}' | sort | uniq -c | sort -rn | head -${1:-10}
}

# Clear history (with confirmation)
clear_history() {
    echo "This will clear your entire shell history. Are you sure? (y/N)"
    read -q "REPLY?" && {
        echo "\nClearing history..."
        > "$HISTFILE"
        history -c
        fc -p
        echo "History cleared."
    } || echo "\nHistory not cleared."
}

# Search and execute from history
hexec() {
    local cmd
    cmd=$(history | fzf --height 40% | sed 's/^[[:space:]]*[0-9]\+[[:space:]]\+//')
    if [[ -n $cmd ]]; then
        print -z "$cmd"
    fi
}

# Show history stats
hist_stats() {
    echo "History file: $HISTFILE"
    echo "History size: $(wc -l < "$HISTFILE") lines"
    echo "Memory limit: $HISTSIZE lines"
    echo "File limit: $SAVEHIST lines"
    echo "\nMost used commands:"
    hist_top 5
}
