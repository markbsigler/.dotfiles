# Quick Reference: Vim/MacVim Essentials

## Installation & Setup

### Install MacVim
```bash
brew install macvim
```

### Verify Installation
```bash
mvim --version
vim --version
which mvim vim
```

### Check Current Editor
```bash
echo $EDITOR
echo $VISUAL
echo $GIT_EDITOR
```

---

## Basic Vim Commands

### Essential Modes
- **Normal Mode**: `Esc` - Navigate and run commands
- **Insert Mode**: `i` - Type text
- **Visual Mode**: `v` - Select text
- **Command Mode**: `:` - Run ex commands

### Navigation (Normal Mode)
- `h` `j` `k` `l` - Left, Down, Up, Right
- `w` - Next word
- `b` - Previous word
- `0` - Start of line
- `$` - End of line
- `gg` - Top of file
- `G` - Bottom of file
- `Ctrl-d` - Scroll down half page
- `Ctrl-u` - Scroll up half page

### Editing (Normal Mode)
- `i` - Insert before cursor
- `a` - Insert after cursor
- `o` - New line below
- `O` - New line above
- `x` - Delete character
- `dd` - Delete line
- `yy` - Copy line
- `p` - Paste after cursor
- `u` - Undo
- `Ctrl-r` - Redo

### Search & Replace
- `/pattern` - Search forward
- `?pattern` - Search backward
- `n` - Next match
- `N` - Previous match
- `:%s/old/new/g` - Replace all in file
- `:%s/old/new/gc` - Replace with confirmation

### Save & Quit
- `:w` - Save
- `:q` - Quit
- `:wq` or `:x` - Save and quit
- `:q!` - Quit without saving
- `ZZ` - Save and quit (normal mode)

### Multiple Files
- `:e filename` - Edit file
- `:bn` - Next buffer
- `:bp` - Previous buffer
- `:bd` - Close buffer
- `:ls` - List buffers

### Splits
- `:sp filename` - Horizontal split
- `:vsp filename` - Vertical split
- `Ctrl-w h/j/k/l` - Navigate splits
- `Ctrl-w w` - Cycle splits
- `:close` - Close split

---

## MacVim Specific

### Launch MacVim
```bash
mvim                # GUI mode
mvim -v             # Terminal mode (vim mode)
mvim -v file.txt    # Edit in terminal
mvim file.txt       # Edit in GUI
```

### GUI Features
- File → Open Recent
- Edit → Select All (`Cmd-A`)
- Format → Font → Show Fonts
- Window → Minimize (`Cmd-M`)
- Full Screen: `Cmd-Ctrl-F`

### Clipboard Integration
MacVim automatically integrates with macOS clipboard:
- `"+y` - Copy to system clipboard
- `"+p` - Paste from system clipboard
- Or use visual mode + `Cmd-C/V`

---

## Recommended Plugins

### Using vim-plug

1. **Install vim-plug**:
```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

2. **Add to ~/.vim/vimrc**:
```vim
call plug#begin('~/.vim/plugged')

" Essential plugins
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'junegunn/fzf.vim'

call plug#end()
```

3. **Install plugins**:
```bash
vim +PlugInstall +qall
```

### Essential Plugins Explained

- **vim-sensible**: Sensible defaults
- **vim-fugitive**: Git integration (`:Git`, `:Gstatus`, `:Gdiff`)
- **vim-surround**: Surround text (cs"' changes "hello" to 'hello')
- **vim-commentary**: Comment code (gcc to toggle comment)
- **fzf.vim**: Fuzzy file finder (`:Files`, `:Buffers`, `:Rg`)

---

## Configuration Tips

### Create ~/.vim/vimrc
```vim
" Basic settings
set number relativenumber
set tabstop=4 shiftwidth=4 expandtab
set ignorecase smartcase
set hlsearch incsearch
set clipboard=unnamed

" Leader key
let mapleader = " "

" Quick save
nnoremap <leader>w :w<CR>

" Clear search highlight
nnoremap <leader><space> :nohlsearch<CR>
```

### MacVim GUI Settings
```vim
if has("gui_macvim")
    set guifont=JetBrains\ Mono:h14
    set guioptions-=T  " Remove toolbar
    set guioptions-=r  " Remove scrollbar
    set transparency=5
endif
```

---

## Useful Workflows

### Edit Config Files
```bash
# Quick edit shell config
vim ~/.zshrc

# Quick edit vim config  
vim ~/.vim/vimrc

# Quick edit git config
vim ~/.gitconfig
```

### Git Workflows
```vim
" Inside vim
:Git status
:Git add %
:Git commit
:Git push

" Or use terminal mode
:terminal
```

### Code Navigation
```vim
" Jump to definition (with LSP)
gd

" Find references
gr

" Go back
Ctrl-o

" Go forward
Ctrl-i
```

---

## Troubleshooting

### MacVim Won't Launch
```bash
# Check if installed
which mvim

# Reinstall
brew reinstall macvim

# Check for errors
mvim --version
```

### Colors Look Wrong
```vim
" In ~/.vim/vimrc
set termguicolors
colorscheme gruvbox
```

### Clipboard Not Working
```vim
" Check clipboard support
:echo has('clipboard')

" Should return 1
" If 0, reinstall vim/macvim with clipboard support
```

### Slow Startup
```bash
# Profile startup time
vim --startuptime vim.log

# Check what's slow
cat vim.log | sort -k2 -n
```

---

## Learning Resources

### Interactive Tutorials
- `vimtutor` - Built-in tutorial (run in terminal)
- [Vim Adventures](https://vim-adventures.com/) - Game to learn vim
- [OpenVim](https://www.openvim.com/) - Interactive tutorial

### Documentation
- `:help` - Built-in help
- `:help user-manual` - User manual
- `:help quickref` - Quick reference
- [Vim Tips Wiki](https://vim.fandom.com/)

### Books
- "Practical Vim" by Drew Neil
- "Modern Vim" by Drew Neil
- "Learning the vi and Vim Editors" by Arnold Robbins

### Cheat Sheets
- [Vim Cheat Sheet](https://vim.rtorr.com/)
- [Devhints Vim](https://devhints.io/vim)

---

## Quick Tips

1. **Use relative line numbers** for faster navigation
2. **Learn to use `.` command** to repeat last change
3. **Master text objects** (`ciw`, `ci"`, `ci{`, etc.)
4. **Use marks** (`ma` to set, `'a` to jump)
5. **Learn macros** (`qa` to record, `@a` to play)
6. **Use visual block mode** (`Ctrl-v`) for column editing
7. **Enable persistent undo** for undo history across sessions
8. **Use :earlier and :later** to time travel through changes

---

## Keyboard Shortcuts Summary

| Command | Mode | Action |
|---------|------|--------|
| `i` | Normal | Enter insert mode |
| `Esc` | Insert | Return to normal mode |
| `v` | Normal | Enter visual mode |
| `:` | Normal | Enter command mode |
| `h j k l` | Normal | Navigate left/down/up/right |
| `w b` | Normal | Next/previous word |
| `0 $` | Normal | Start/end of line |
| `gg G` | Normal | Top/bottom of file |
| `dd yy p` | Normal | Delete/copy/paste line |
| `u Ctrl-r` | Normal | Undo/redo |
| `/` `?` | Normal | Search forward/backward |
| `n N` | Normal | Next/previous search result |
| `:w` | Command | Save |
| `:q` | Command | Quit |
| `:wq` | Command | Save and quit |

---

**Remember**: Vim has a learning curve, but once mastered, it's incredibly efficient!

**Pro Tip**: Start with the basics, add one new command per day, and practice regularly.
