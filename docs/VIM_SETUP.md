# Vim Configuration Best Practices Guide

## Current Setup
Your vimrc is located at: `~/.dotfiles/config/vim/vimrc`

## Recommended Improvements

### 1. Add Plugin Manager

Add vim-plug (minimal, fast, parallel plugin manager):

```vim
" Add to top of vimrc
" Install vim-plug if not already installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugin section
call plug#begin('~/.vim/plugged')

" Essential plugins
Plug 'tpope/vim-sensible'          " Sensible defaults
Plug 'tpope/vim-fugitive'          " Git integration
Plug 'tpope/vim-surround'          " Surround text objects
Plug 'tpope/vim-commentary'        " Comment stuff out
Plug 'tpope/vim-repeat'            " Repeat plugin commands

" File navigation
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'            " Fuzzy finder

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Color schemes
Plug 'morhetz/gruvbox'
Plug 'joshdick/onedark.vim'
Plug 'sainnhe/everforest'

" LSP and completion (if using Vim 8.2+)
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" Syntax highlighting
Plug 'sheerun/vim-polyglot'        " Language pack

call plug#end()
```

### 2. MacVim-Specific Settings

Add to your vimrc:

```vim
" MacVim-specific settings
if has("gui_macvim")
    " Use macOS clipboard
    set clipboard=unnamed
    
    " Better font for MacVim
    set guifont=JetBrains\ Mono:h14,Menlo:h14
    
    " Remove toolbar and scrollbars
    set guioptions-=T
    set guioptions-=r
    set guioptions-=L
    
    " Transparency (0=opaque, 100=fully transparent)
    set transparency=5
    
    " Full screen options
    set fuoptions=maxvert,maxhorz
endif
```

### 3. Better Defaults for Modern Vim

```vim
" Modern Vim improvements
set hidden                    " Allow switching buffers without saving
set backup                    " Keep backup files
set backupdir=~/.vim/backup// " Backup directory
set directory=~/.vim/swap//   " Swap file directory
set undofile                  " Persistent undo
set undodir=~/.vim/undo//     " Undo directory
set updatetime=300            " Faster completion
set timeoutlen=500            " Faster key sequence completion

" Better search
set hlsearch                  " Highlight searches
set incsearch                 " Incremental search
set ignorecase                " Case insensitive
set smartcase                 " But case-sensitive if uppercase used

" Better display
set number relativenumber     " Hybrid line numbers
set cursorline                " Highlight current line
set showcmd                   " Show partial commands
set wildmenu                  " Enhanced command line completion
set wildmode=longest:full,full
set scrolloff=8               " Keep 8 lines above/below cursor
set sidescrolloff=8           " Keep 8 columns left/right of cursor

" Better editing
set autoread                  " Auto reload files changed outside vim
set mouse=a                   " Enable mouse support
set backspace=indent,eol,start " Intuitive backspace

" Create necessary directories
if !isdirectory($HOME . "/.vim/backup")
    call mkdir($HOME . "/.vim/backup", "p", 0700)
endif
if !isdirectory($HOME . "/.vim/swap")
    call mkdir($HOME . "/.vim/swap", "p", 0700)
endif
if !isdirectory($HOME . "/.vim/undo")
    call mkdir($HOME . "/.vim/undo", "p", 0700)
endif
```

### 4. Useful Keybindings

```vim
" Leader key
let mapleader = " "
let maplocalleader = "\\"

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Clear search highlighting
nnoremap <leader><space> :nohlsearch<CR>

" Quick buffer navigation
nnoremap <leader>n :bnext<CR>
nnoremap <leader>p :bprev<CR>
nnoremap <leader>d :bdelete<CR>

" Split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" FZF shortcuts (if installed)
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>r :Rg<CR>
```

## Installation

1. Install MacVim (if on macOS):
   ```bash
   brew install macvim
   ```

2. Create symlinks for Neovim to use Vim config:
   ```bash
   mkdir -p ~/.config/nvim
   ln -sf ~/.vim/vimrc ~/.config/nvim/init.vim
   ```

3. Install plugins:
   ```bash
   vim +PlugInstall +qall
   ```

## Testing

After updating, test with:
```bash
vim --version
mvim --version
echo $EDITOR
echo $VISUAL
```
