# ~/.config/zsh/vscode.zsh - VS Code terminal shell integration

# Load VS Code shell integration in VS Code terminals only
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    if [[ -z "${__vscode_shell_integration_loaded:-}" ]]; then
        __vscode_shell_integration_loaded=1

        if command -v code >/dev/null 2>&1; then
            __vscode_shell_integration_path="$(code --locate-shell-integration-path zsh 2>/dev/null)"
        elif command -v code-insiders >/dev/null 2>&1; then
            __vscode_shell_integration_path="$(code-insiders --locate-shell-integration-path zsh 2>/dev/null)"
        else
            __vscode_shell_integration_path=""
        fi

        if [[ -n "$__vscode_shell_integration_path" ]]; then
            source "$__vscode_shell_integration_path"
        fi

        unset __vscode_shell_integration_path
    fi
fi
