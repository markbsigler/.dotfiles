# ~/.config/zsh/vi-mode.zsh - Enhanced vi mode configuration

# Enable vi mode
bindkey -v

# Reduce ESC delay
export KEYTIMEOUT=1

# Change cursor shape for different vi modes
function zle-keymap-select {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block cursor
        viins|main) echo -ne '\e[5 q';; # beam cursor
    esac
}

function zle-line-init {
    echo -ne "\e[5 q" # beam cursor on startup
}

function zle-line-finish {
    echo -ne '\e[1 q' # block cursor
}

zle -N zle-keymap-select
zle -N zle-line-init
zle -N zle-line-finish

# Better vi mode bindings
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# Allow backspace and ^h to delete backwards from insert mode
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^h' backward-delete-char

# Allow ctrl-a and ctrl-e to move to beginning/end of line
bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line

# Allow ctrl-r to perform backwards search in history
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward

# Allow v to edit the command line (standard behaviour)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Text objects for quotes and brackets
autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
    for c in {a,i}{\',\",\`}; do
        bindkey -M $m $c select-quoted
    done
done

autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
        bindkey -M $m $c select-bracketed
    done
done

# Surround text objects
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround

# Show mode in prompt
function vi_mode_prompt_info() {
    echo "${${KEYMAP/vicmd/[% NORMAL %]}/(main|viins)/[% INSERT %]}"
}

# Define the prompt (this will be overridden by prompt.zsh if it comes after)
# RPS1='$(vi_mode_prompt_info)'
