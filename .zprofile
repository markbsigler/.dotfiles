
# ~/.zprofile - Login shell initialization
# This file is sourced for login shells before .zshrc
# On macOS Terminal.app, login shells don't automatically source .zshrc

# Ensure .zshrc is sourced for interactive login shells
if [[ -o interactive && -z "$ZSHRC_LOADED" ]]; then
    [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
fi
