# ~/.config/zsh/fzf.zsh - FZF specific configurations

# FZF key bindings and fuzzy completion
if command -v fzf &> /dev/null; then
    # Custom functions using FZF
    
    # Interactive git branch switching
    fbr() {
        local branches branch
        branches=$(git branch -vv) &&
        branch=$(echo "$branches" | fzf +m) &&
        git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
    }
    
    # Interactive git log browser
    fshow() {
        git log --graph --color=always \
            --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
        fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
            --bind "ctrl-m:execute:
                        (grep -o '[a-f0-9]\{7\}' | head -1 |
                        xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                        {}
FZF-EOF"
    }
    
    # Interactive file finder with preview
    ff() {
        fd --type f --hidden --follow --exclude .git |
        fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'
    }
    
    # Interactive directory finder
    fd_dir() {
        local dir
        dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) &&
        cd "$dir"
    }
    
    # Interactive process killer
    fkill() {
        local pid
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
        
        if [ "x$pid" != "x" ]; then
            echo $pid | xargs kill -${1:-9}
        fi
    }
    
    # Search in command history
    fh() {
        print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')
    }
    
    # Interactive environment variable viewer
    fenv() {
        env | fzf
    }
    
    # Interactive man page finder
    fman() {
        man -k . | fzf --prompt='Man> ' | awk '{print $1}' | xargs -r man
    }
fi
