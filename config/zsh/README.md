# Enhanced Zsh Configuration 🌊

> **Note:** This is the Zsh-specific configuration documentation. For the main repository documentation, installation instructions, and getting started guide, see the [main README](../../README.md) and [docs directory](../../docs/README.md).

A comprehensive, modular shell configuration designed for modern development workflows. This document focuses on the Zsh configuration features, functions, and customization options.

## Features Overview

### 🔧 Zsh Configuration
- **Modular Design**: Clean separation of concerns across multiple files
- **XDG Compliance**: Follows XDG Base Directory specification
- **Performance Optimized**: Lazy loading, efficient completions, and startup optimization
- **Modern Tools Integration**: FZF, modern CLI replacements, development tools
- **Comprehensive History Management**: Advanced search, statistics, and management
- **Vi Mode Enhancement**: Full vi-mode with visual feedback and text objects

### 📝 Vim Configuration
- **Shared Vim/Neovim**: Works seamlessly with both Vim and Neovim
- **Modern Plugin Management**: Using vim-plug with curated plugin selection
- **Language Support**: Enhanced support for Python, JavaScript, Go, Rust, and more
- **Code Intelligence**: CoC.nvim for LSP support, syntax highlighting, and completion
- **Git Integration**: Fugitive and GitGutter for comprehensive git workflow
- **Fuzzy Finding**: FZF integration for files, buffers, and more

## File Structure

```
~/.config/zsh/
├── aliases.zsh           # Command aliases and shortcuts
├── completions.zsh       # Enhanced completion system
├── dev-tools.zsh         # Development workflow shortcuts
├── exports.zsh           # Environment variables
├── fzf.zsh              # FZF integration and custom functions
├── functions.zsh         # Custom shell functions
├── history.zsh          # History management and search
├── local.zsh            # Machine-specific configuration
├── plugins.zsh          # Plugin management and loading
├── prompt.zsh           # Custom prompt with git info
├── python.zsh           # Python-specific configuration
├── setup-tools.sh       # Automated setup script
├── version-managers.zsh # Version managers (nvm, pyenv, etc.)
└── vi-mode.zsh          # Enhanced vi-mode configuration

~/.vim/
├── backup/              # Backup files directory
├── swap/                # Swap files directory
├── undo/                # Undo files directory
└── plugged/             # Plugin installation directory
```

## Quick Start

> **For initial installation**, use `make install` from the dotfiles repository root. See the [main README](../../README.md#-quick-start) for installation instructions.

### Reload Configuration

After making changes to Zsh configuration files:

```bash
source ~/.zshrc    # Reload configuration
```

### Optional: Setup Additional Tools

```bash
bash ~/.config/zsh/setup-tools.sh    # Install modern CLI tools
```

## Key Features & Commands

### 🔍 FZF Integration
- `ff` - Interactive file finder with preview
- `fbr` - Interactive git branch switcher
- `fshow` - Interactive git log browser
- `fkill` - Interactive process killer
- `fh` - Search command history
- `fman` - Interactive man page finder

### 📊 History Management
- `hist_top [n]` - Show most used commands
- `hist_stats` - Display history statistics
- `hexec` - Search and execute from history
- `clear_history` - Clear history with confirmation

### 🚀 Development Tools
- `init_project <type>` - Initialize projects (node, python, rust, go)
- `serve_static [port]` - Quick static file server
- `lint_check` - Run appropriate linters
- `test_run` - Run tests for current project
- `port_kill <port>` - Kill process on specific port
- `env_setup` - Setup .env files

### 📁 Directory Management
- `book <n>` - Bookmark current directory
- `go <n>` - Jump to bookmarked directory
- `clean_bookmarks` - Remove invalid bookmarks
- `mkcd <dir>` - Create and enter directory

### 🐙 Git Workflow
- `gwip` - Quick work-in-progress commit
- `gnb <branch>` - Create and push new branch
- `gdel <branch>` - Delete branch locally and remotely
- `glog` - Pretty git log graph
- Enhanced git aliases: `gs`, `ga`, `gc`, `gp`, `gd`, etc.

### 🐳 Docker Shortcuts
- `dps` - Pretty docker ps output
- `dcu` - Docker compose up -d
- `dcd` - Docker compose down
- `dclogs [service]` - Follow compose logs

## Vim Key Mappings

### Leader Key: `<Space>`

#### File Operations
- `<leader>w` - Save file
- `<leader>q` - Quit
- `<leader>wq` - Save and quit
- `<leader>Q` - Force quit

#### Navigation
- `<leader>n` - Toggle NERDTree
- `<leader>f` - Find current file in NERDTree
- `<C-p>` - Fuzzy find files
- `<leader>b` - Switch buffers
- `<leader>rg` - Search with ripgrep

#### Splits
- `<leader>v` - Vertical split
- `<leader>h` - Horizontal split
- `<leader>=` - Equalize splits
- `<C-h/j/k/l>` - Navigate splits

#### Code Navigation (CoC.nvim)
- `gd` - Go to definition
- `gy` - Go to type definition
- `gi` - Go to implementation
- `gr` - Find references
- `K` - Show documentation

#### Git
- `]h` - Next git hunk
- `[h` - Previous git hunk

#### Tabs
- `<leader>1-9` - Switch to tab 1-9
- `<leader>tn` - New tab
- `<leader>tc` - Close tab

## Plugin List

### Zsh Plugins
- **zsh-autosuggestions** - Fish-like autosuggestions
- **zsh-syntax-highlighting** - Syntax highlighting for commands
- **fzf-tab** - Replace tab completion with fzf

### Vim Plugins
- **vim-airline** - Status line enhancement
- **vim-fugitive** - Git integration
- **vim-gitgutter** - Git diff in gutter
- **nerdtree** - File explorer
- **fzf.vim** - Fuzzy finder integration
- **coc.nvim** - Language server protocol support
- **ale** - Asynchronous linting
- **vim-surround** - Surround text objects
- **vim-commentary** - Easy commenting
- **auto-pairs** - Auto-close brackets
- **gruvbox** - Color scheme

## Performance Features

### Zsh Optimizations
- Lazy loading of version managers (nvm, pyenv, etc.)
- Efficient completion caching
- Smart compinit loading
- Plugin update checking
- Startup time profiling with `zsh_startup_time`

### Vim Optimizations
- Fast startup with proper plugin loading
- Efficient backup/swap/undo file management
- Optimized for both terminal and GUI usage
- Project-specific .vimrc support

## Version Manager Support

- **NVM** - Node.js version management (lazy loaded)
- **Pyenv** - Python version management
- **jenv** - Java version management
- **rbenv** - Ruby version management

## Modern CLI Tools Integration

The configuration includes aliases and integration for:
- `bat` - Better cat with syntax highlighting
- `eza` - Modern ls replacement
- `fd` - Better find command
- `ripgrep` - Fast grep replacement
- `dust` - Better du command
- `delta` - Enhanced git diff

## Customization

### Machine-Specific Settings
Edit `~/.config/zsh/local.zsh` for machine-specific customizations:

```bash
# Add custom PATH
export PATH="$HOME/custom/bin:$PATH"

# Machine-specific aliases
alias deploy="ssh user@server 'cd /var/www && git pull'"

# Environment variables
export API_KEY="your-secret-key"
```

### Adding New Plugins

#### Zsh Plugins
Add to `~/.config/zsh/plugins.zsh`:
```bash
load_plugin "plugin-name" "https://github.com/user/plugin"
```

#### Vim Plugins
Add to `~/.vimrc` in the plug section:
```vim
Plug 'user/plugin-name'
```
Then run `:PlugInstall` in Vim.

## Maintenance

### Update Plugins
```bash
# Zsh plugins
update_plugins

# Check for outdated plugins
check_plugin_updates

# Vim plugins
vim +PlugUpdate +qall
```

### Performance Monitoring
```bash
# Check zsh startup time
zsh_startup_time

# Profile zsh loading
zprof_start

# View history statistics
hist_stats
```

## Troubleshooting

### Slow Startup
1. Run `zsh_startup_time` to identify bottlenecks
2. Check if version managers are loading properly
3. Ensure plugins are up to date with `update_plugins`

### Missing Commands
1. Run the setup script: `bash ~/.config/zsh/setup-tools.sh`
2. Check if tools are installed: `brew list`
3. Reload configuration: `source ~/.zshrc`

### Vim Issues
1. Ensure vim-plug is installed
2. Run `:PlugInstall` to install missing plugins
3. Check `:checkhealth` in Neovim for diagnostics

## Related Documentation

- **[Main README](../../README.md)** - Repository overview and installation
- **[Documentation Hub](../../docs/README.md)** - All documentation and quick reference
- **[CUSTOMIZATION.md](../../docs/CUSTOMIZATION.md)** - How to customize your dotfiles
- **[SECRETS.md](../../docs/SECRETS.md)** - Secrets management guide
- **[TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Contributing

This configuration is designed to be:
- **Modular** - Easy to modify individual components
- **Documented** - Clear comments explaining functionality
- **Performant** - Optimized for speed and efficiency
- **Cross-platform** - Works on macOS and Linux

See the [main repository](../../README.md#-contributing) for contribution guidelines.

---

**Last Updated:** November 2025

For planned improvements, see [ROADMAP.md](../../ROADMAP.md) | For completed changes, see [CHANGELOG.md](../../CHANGELOG.md)
