# tmux Configuration

Modern tmux configuration with sensible defaults, vi-mode, and mouse support.

## Features

- **Custom Prefix**: `Ctrl-Space` (more ergonomic than default)
- **Vi Mode**: Vi-style navigation and copy mode
- **Mouse Support**: Full mouse support for pane/window management
- **Intuitive Splits**: `|` for vertical, `-` for horizontal
- **Smart Window Numbering**: Starts at 1, auto-renumbers
- **10,000 Line Scrollback**: Extensive history
- **Modern Styling**: Clean status bar with useful info

## Installation

The tmux configuration is installed automatically with `make install`.

Manual symlink:
```bash
ln -sf ~/.dotfiles/config/tmux/tmux.conf ~/.tmux.conf
```

## Key Bindings

### Prefix Key
- **Prefix**: `Ctrl-Space` (instead of `Ctrl-B`)

### Pane Management
- `Prefix |` - Split vertically (horizontal panes)
- `Prefix -` - Split horizontally (vertical panes)
- `Alt-Arrow` - Navigate panes (no prefix needed)
- `Prefix h/j/k/l` - Navigate panes (vi keys)
- `Prefix H/J/K/L` - Resize panes (hold for repeat)
- `Prefix x` - Kill current pane
- `Prefix S` - Synchronize panes (type in all at once)

### Window Management
- `Prefix c` - New window
- `Prefix ,` - Rename window
- `Prefix n/p` - Next/previous window
- `Prefix 0-9` - Go to window by number
- `Prefix X` - Kill current window

### Session Management
- `Prefix d` - Detach from session
- `Prefix (` - Previous session
- `Prefix )` - Next session
- `Prefix L` - Last session

### Copy Mode (Vi-style)
- `Prefix [` - Enter copy mode
- `Space` - Start selection
- `v` - Begin selection (vi-style)
- `y` - Copy selection
- `q` - Exit copy mode
- `Prefix ]` - Paste

### Other
- `Prefix r` - Reload config
- `Prefix ?` - List all key bindings

## Status Bar

The status bar shows:
- **Left**: Session name
- **Right**: Username@hostname | Day Date Time

Example: `❐ mysession | user@host | Mon Nov 03 14:30`

## Tips

### Create a New Session
```bash
tmux new -s mysession
```

### Attach to Existing Session
```bash
tmux attach -t mysession
# or
tmux a -t mysession
```

### List Sessions
```bash
tmux list-sessions
# or
tmux ls
```

### Kill a Session
```bash
tmux kill-session -t mysession
```

### Nested tmux Sessions
If you SSH into a remote machine with tmux, press the prefix twice:
- `Ctrl-Space Ctrl-Space c` - New window on remote
- `Ctrl-Space Ctrl-Space |` - Split pane on remote

## macOS Integration

For clipboard integration on macOS, install:
```bash
brew install reattach-to-user-namespace
```

This enables copying to system clipboard with `y` in copy mode.

## Linux Integration

For clipboard integration on Linux, install xclip or xsel:
```bash
# Ubuntu/Debian
sudo apt install xclip

# Fedora
sudo dnf install xclip

# Arch
sudo pacman -S xclip
```

## Plugins (Optional)

To use plugins with TPM (Tmux Plugin Manager):

1. Install TPM:
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. Uncomment plugin lines in `tmux.conf`

3. Reload tmux config: `Prefix r`

4. Install plugins: `Prefix I` (capital i)

### Recommended Plugins
- **tmux-sensible**: Basic tmux settings everyone agrees on
- **tmux-yank**: Enhanced clipboard integration
- **tmux-resurrect**: Save and restore sessions
- **tmux-continuum**: Automatic session saving/restoring

## Local Customization

For machine-specific customizations, create:
```bash
~/.tmux.conf.local
```

This file is automatically sourced if it exists.

Example:
```bash
# ~/.tmux.conf.local
# Machine-specific tmux settings

# Different status bar color on work machine
set -g status-style 'bg=#ff0000 fg=#ffffff'
```

## Troubleshooting

### Colors Not Working
Make sure your terminal supports 256 colors:
```bash
echo $TERM
# Should show something like: screen-256color or xterm-256color
```

### Mouse Not Working
Ensure mouse support is enabled:
```bash
tmux show -g | grep mouse
# Should show: mouse on
```

### Copy Mode Not Working
1. Enter copy mode: `Prefix [`
2. Navigate with vi keys: `h/j/k/l`
3. Start selection: `Space` or `v`
4. Copy: `y`
5. Exit: `q`
6. Paste: `Prefix ]`

## See Also

- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Awesome tmux](https://github.com/rothgar/awesome-tmux)
- [TPM](https://github.com/tmux-plugins/tpm)

