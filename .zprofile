
# ~/.zprofile - Login shell initialization
# This file is sourced for login shells before .zshrc
# Keep minimal - most configuration should be in .zshrc

# Source .zshrc for login shells that might not source it automatically
[[ -z "$ZSHRC_LOADED" && -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
