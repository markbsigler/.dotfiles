" Minimal Neovim init.vim
" Set leader key
let mapleader = ","

" Source shared .vimrc for consistency
if filereadable(expand("~/.vimrc"))
  source ~/.vimrc
endif

" Enable true color
if has('termguicolors')
  set termguicolors
endif

" Basic UI
set number
set relativenumber
set cursorline
set laststatus=2
set showmatch
set tabstop=2 shiftwidth=2 expandtab
set mouse=a
set hidden
set updatetime=300

" System clipboard support
set clipboard=unnamedplus

" Font for Neovide (GUI)
if exists('g:neovide')
  set guifont=Menlo:h14
endif

" Enable filetype plugins and syntax
filetype plugin on
syntax on

" Plugin management (vim-plug)
call plug#begin('~/.local/share/nvim/plugged')
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'lewis6991/gitsigns.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'folke/which-key.nvim'
call plug#end()

" Colorscheme
try
  colorscheme desert
catch
endtry

" Save/quit mappings
nnoremap <leader>q :q<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>wq :wq<CR>

" Reload and edit config mappings
nnoremap <leader>sv :source $MYVIMRC<CR>
nnoremap <leader>ev :edit $MYVIMRC<CR>

" Persistent undo support
if has('persistent_undo')
  set undodir=~/.local/share/nvim/undodir
  set undofile
endif

" Highlight on yank
augroup YankHighlight
  autocmd!
  autocmd TextYankPost * silent! lua vim.highlight.on_yank({ timeout = 150 })
augroup END

" Lua plugin setup
lua << EOF
require('nvim-tree').setup {}
require('gitsigns').setup {}
require('nvim-autopairs').setup {}
require('which-key').setup {}
require('nvim-treesitter.configs').setup {
  ensure_installed = { "lua", "vim", "python", "javascript", "typescript" },
  highlight = { enable = true },
}
EOF

" Key mappings for nvim-tree
nnoremap <leader>e :NvimTreeToggle<CR>
nnoremap <leader>f :NvimTreeFindFile<CR>