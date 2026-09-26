# .dotfiles Makefile
# Provides convenient commands for managing .dotfiles installation and maintenance

.PHONY: help install update clean backup test lint docs doctor fonts plugins status deps restore list mcp-atlassian-setup mcp-atlassian-migrate mcp-atlassian-test
.PHONY: install-dry force packages test-all test-quick test-integration test-zsh test-vim test-scripts security perf dev-setup git-hooks

# Default target
.DEFAULT_GOAL := help

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[0;32m
RED := \033[0;31m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m

# Configuration
DOTFILES_DIR := $(CURDIR)

# OS Detection
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)

ifeq ($(OS),darwin)
	OS_NAME := macOS
	PACKAGE_MANAGER := brew
else ifeq ($(OS),linux)
	OS_NAME := Linux
	PACKAGE_MANAGER := unknown
	# Detect Linux distribution
	DISTRO := $(shell test -f /etc/os-release && grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' || echo unknown)
	ifneq ($(filter ubuntu debian,$(DISTRO)),)
		PACKAGE_MANAGER := apt
	else ifneq ($(filter fedora centos rhel,$(DISTRO)),)
		PACKAGE_MANAGER := dnf
	else ifneq ($(filter arch manjaro,$(DISTRO)),)
		PACKAGE_MANAGER := pacman
	endif
else
	OS_NAME := Unknown
	PACKAGE_MANAGER := unknown
endif

## Display this help message
help:
	@echo "$(YELLOW).dotfiles Management Commands$(NC)"
	@echo ""
	@echo "$(GREEN)System Info:$(NC)"
	@echo "  OS: $(OS_NAME) ($(ARCH))"
	@echo "  Package Manager: $(PACKAGE_MANAGER)"
	@echo ""
	@echo "$(GREEN)Installation:$(NC)"
	@echo "  make install        Install .dotfiles (full setup)"
	@echo "  make install-dry    Preview installation without making changes"
	@echo "  make update         Update existing symlinks only"
	@echo "  make force          Force installation, overwriting existing files"
	@echo "  make packages       Install packages only"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  make test           Test configuration files"
	@echo "  make test-all       Same complete offline suite as make test"
	@echo "  make test-quick     Required files and shell syntax"
	@echo "  make test-integration  Isolated recovery, security and OS checks"
	@echo "  make test-zsh       Zsh syntax checks"
	@echo "  make test-vim       Isolated Vim configuration check"
	@echo "  make test-scripts   Shell script syntax checks"
	@echo "  make lint           Lint shell scripts"
	@echo "  make security       Redacted working-tree secret scan"
	@echo "  make clean          List log cleanup candidates without deleting"
	@echo "  make dev-setup      Install development tools"
	@echo "  make git-hooks      Setup git pre-commit hooks"
	@echo ""
	@echo "$(GREEN)Maintenance:$(NC)"
	@echo "  make backup         Create backup of current configs"
	@echo "  make restore BACKUP=/path [CONFIRM=yes]  Preview or restore an explicit backup"
	@echo "  make doctor         Check system health and dependencies"
	@echo "  make plugins        Update ZSH plugins"
	@echo "  make fonts          Install Agave Nerd Font"
	@echo "  make mcp-atlassian-setup   Seed Atlassian tokens into macOS Keychain"
	@echo "  make mcp-atlassian-migrate Update MCPM Atlassian config to secure launcher"
	@echo "  make mcp-atlassian-test    Run Atlassian MCP server"
	@echo ""
	@echo "$(GREEN)Information:$(NC)"
	@echo "  make help           Show this help (the default target)"
	@echo "  make status         Show .dotfiles status"
	@echo "  make deps           Show dependencies"
	@echo "  make docs           Generate system info documentation"
	@echo "  make list           Show all available targets"
	@echo "  make perf           Report unavailable isolated performance benchmark"

## Install .dotfiles (full setup)
install:
	@echo "$(GREEN)Installing .dotfiles for $(OS_NAME)...$(NC)"
	@./install.sh
	@echo "$(YELLOW)If you see '?' instead of icons, run 'make fonts' and set your terminal font to Agave Nerd Font.$(NC)"

## Preview installation without making changes
install-dry:
	@echo "$(YELLOW)Dry run - preview installation$(NC)"
	@./install.sh --dry-run

## Update existing symlinks only
update:
	@echo "$(GREEN)Updating .dotfiles...$(NC)"
	@./install.sh --update

## Force installation, overwriting existing files
force:
	@echo "$(RED)Force installing .dotfiles...$(NC)"
	@./install.sh --force

## Install packages only
packages:
	@echo "$(GREEN)Installing packages for $(OS_NAME)...$(NC)"
	@./scripts/install-packages.sh

## Test configuration files
test:
	@bash scripts/test-dotfiles.sh

## Run comprehensive tests
test-all:
	@bash scripts/test-dotfiles.sh

## Run quick tests only
test-quick:
	@bash scripts/test-dotfiles.sh --quick

test-integration:
	@echo "$(GREEN)Running integration tests...$(NC)"
	@bash scripts/test-dotfiles.sh --integration

test-zsh:
	@bash scripts/test-dotfiles.sh --zsh

test-vim:
	@bash scripts/test-dotfiles.sh --vim

test-scripts:
	@bash scripts/test-dotfiles.sh --scripts

## Lint shell scripts
lint:
	@bash scripts/test-dotfiles.sh --lint

## Run security audit
security:
	@echo "$(GREEN)Running security audit...$(NC)"
	@bash scripts/security-audit.sh

## Seed Atlassian MCP tokens into macOS Keychain
mcp-atlassian-setup:
	@./scripts/mcpm-atlassian-keychain-setup.sh

## Migrate Atlassian MCP server config to secure launcher
mcp-atlassian-migrate:
	@./scripts/mcpm-atlassian-migrate.sh

## Run Atlassian MCP server for smoke testing
mcp-atlassian-test:
	@mcpm run atlassian

## List log cleanup candidates without deleting
clean:
	@echo "Backups are retained. Review and remove individual backups explicitly."
	@echo "Repository log candidates (no deletion performed):"
	@find . -maxdepth 2 -type f -name '*.log' -print

## Create backup of current configs
backup:
	@bash scripts/backup-dotfiles.sh

## Preview an explicit backup; restore only with CONFIRM=yes
restore:
	@bash scripts/restore-dotfiles.sh --backup "$(BACKUP)" $(if $(filter yes,$(CONFIRM)),--yes,--dry-run)

## Check system health and dependencies
doctor:
	@echo "$(GREEN)Running system health check...$(NC)"
	@echo ""
	@echo "$(YELLOW)System Information:$(NC)"
	@echo "OS: $(OS_NAME)"
	@echo "Architecture: $(ARCH)"
	@if [ "$(OS)" = "linux" ]; then \
		echo "Distribution: $(DISTRO)"; \
	fi
	@__login_shell="$$(getent passwd "$$(id -un)" 2>/dev/null | cut -d: -f7)"; \
	if [ -z "$$__login_shell" ] && [ "$(OS)" = "darwin" ]; then \
		__login_shell="$$(dscl . -read "/Users/$$(id -un)" UserShell 2>/dev/null | awk '{print $$2}')"; \
	fi; \
	if [ -z "$$__login_shell" ]; then \
		__login_shell="$${SHELL:-}"; \
	fi; \
	echo "Shell: $$__login_shell"; \
	if command -v zsh >/dev/null 2>&1; then \
		case "$$__login_shell" in \
			*zsh) \
				echo "$(GREEN)✅ zsh is the default shell$(NC)" ;; \
			"") \
				echo "$(YELLOW)⚪ Could not detect login shell; run: chsh -s $$(command -v zsh)$(NC)" ;; \
			*) \
				echo "$(RED)❌ Default shell is $$__login_shell, expected zsh$(NC)"; \
				echo "To change it explicitly, run: chsh -s $$(command -v zsh)"; exit 1 ;; \
		esac; \
	else \
		echo "$(RED)❌ zsh is not installed$(NC)"; exit 1; \
	fi
	@echo "Package Manager: $(PACKAGE_MANAGER)"
	@echo ""
	@echo "$(YELLOW)Required Tools:$(NC)"
	@failed=0; for cmd in git zsh vim curl; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo "✅ $$cmd: $$(command -v $$cmd)"; \
		else \
			echo "❌ $$cmd: not found"; failed=1; \
		fi; \
	done; exit $$failed
	@echo ""
	@echo "$(YELLOW)Modern CLI Tools:$(NC)"
	@for cmd in bat eza fd fzf rg jq gh; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo "✅ $$cmd: $$(command -v $$cmd)"; \
		elif command -v batcat >/dev/null 2>&1 && [ "$$cmd" = "bat" ]; then \
			echo "✅ bat (as batcat): $$(command -v batcat)"; \
		elif command -v fdfind >/dev/null 2>&1 && [ "$$cmd" = "fd" ]; then \
			echo "✅ fd (as fdfind): $$(command -v fdfind)"; \
		else \
			echo "⚪ $$cmd: not installed"; \
		fi; \
	done
	@echo ""
	@echo "$(YELLOW)Version Managers:$(NC)"
	@for cmd in nvm pyenv rbenv rustup; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo "✅ $$cmd: $$(command -v $$cmd)"; \
		elif [ "$$cmd" = "nvm" ] && [ -f "$${NVM_DIR:-$$HOME/.nvm}/nvm.sh" ]; then \
			echo "✅ nvm: $${NVM_DIR:-$$HOME/.nvm}"; \
		else \
			echo "⚪ $$cmd: not installed"; \
		fi; \
	done
	@echo ""
	@echo "$(YELLOW).dotfiles Status:$(NC)"
	@$(MAKE) -s status

## Show .dotfiles status
status:
	@echo "$(GREEN).dotfiles Status:$(NC)"
	@echo ""
	@echo "$(YELLOW)Symlinks:$(NC)"
	@failed=0; for link in \
		"$(HOME)/.config/zsh:$(DOTFILES_DIR)/config/zsh" \
		"$(HOME)/.zshrc:$(DOTFILES_DIR)/config/zsh/.zshrc" \
		"$(HOME)/.zshenv:$(DOTFILES_DIR)/config/zsh/.zshenv" \
		"$(HOME)/.zprofile:$(DOTFILES_DIR)/config/zsh/.zprofile" \
		"$(HOME)/.gitconfig:$(DOTFILES_DIR)/config/git/gitconfig" \
		"$(HOME)/.config/git:$(DOTFILES_DIR)/config/git" \
		"$(HOME)/.config/mcpm/servers.json:$(DOTFILES_DIR)/config/mcpm/servers.json" \
		"$(HOME)/.local/bin/mcpm-atlassian-secure:$(DOTFILES_DIR)/scripts/mcpm-atlassian-secure.sh" \
		"$(HOME)/.vimrc:$(DOTFILES_DIR)/config/vim/vimrc" \
		"$(HOME)/.config/nvim:$(DOTFILES_DIR)/config/nvim" \
	; do \
		target="$${link%%:*}"; \
		source="$${link##*:}"; \
		if [ -L "$$target" ] && [ -e "$$target" ] && [ "$$(readlink "$$target")" = "$$source" ]; then \
			echo "✅ $$target → $$source"; \
		elif [ -e "$$target" ] || [ -L "$$target" ]; then \
			echo "❌ $$target is not a valid link to $$source"; failed=1; \
		else \
			echo "❌ $$target not found"; failed=1; \
		fi; \
	done; exit $$failed
	@echo ""
	@echo "$(YELLOW)Git Repository:$(NC)"
	@set -eu; \
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
		branch=$$(git branch --show-current); \
		echo "Branch: $${branch:-detached HEAD}"; \
		if remote=$$(git remote get-url origin 2>/dev/null); then \
			echo "Remote: $$remote"; \
		else \
			echo "Remote: No remote configured"; \
		fi; \
		echo ""; \
		echo "$(YELLOW)Working Tree Status:$(NC)"; \
		working_tree=$$(git --no-optional-locks status --porcelain); \
		if [ -n "$$working_tree" ]; then \
			printf '%s\n' "$$working_tree" | head -5; \
			file_count=$$(printf '%s\n' "$$working_tree" | wc -l); \
			if [ "$$file_count" -gt 5 ]; then \
				remaining=$$(( $$file_count - 5 )); \
				echo "... and $$remaining more files"; \
			fi; \
		else \
			echo "✅ Working tree is clean"; \
		fi; \
	else \
		echo "❌ Not a git repository"; exit 1; \
	fi

## Install Nerd Fonts (Agave Nerd Font)
fonts:
	@echo "$(GREEN)Installing Agave Nerd Font...$(NC)"
	@set -eu; \
	if [ "$(OS)" = darwin ] && command -v brew >/dev/null 2>&1; then \
		brew install --cask font-agave-nerd-font; \
	else \
		case "$(OS)" in \
			darwin) destination="$$HOME/Library/Fonts" ;; \
			linux) destination="$${XDG_DATA_HOME:-$$HOME/.local/share}/fonts/AgaveNerdFont"; command -v fc-cache >/dev/null ;; \
			*) echo "Unsupported OS: $(OS)" >&2; exit 1 ;; \
		esac; \
		command -v curl >/dev/null; command -v unzip >/dev/null; \
		umask 077; temporary=$$(mktemp -d "$${TMPDIR:-/tmp}/dotfiles-fonts.XXXXXX"); \
		trap 'rm -rf "$$temporary"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; \
		curl -fL --retry 2 -o "$$temporary/Agave.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Agave.zip; \
		unzip -oq "$$temporary/Agave.zip" '*.ttf' -d "$$temporary/fonts"; \
		set -- "$$temporary/fonts/"*.ttf; [ -f "$$1" ]; \
		mkdir -p "$$destination"; cp "$$@" "$$destination/"; \
		if [ "$(OS)" = linux ]; then fc-cache -f "$$destination"; fi; \
	fi; \
	echo "Agave Nerd Font installed; select it in your terminal preferences."

## Update ZSH plugins
plugins:
	@echo "$(GREEN)Updating ZSH plugins...$(NC)"
	@if [ -d "$(HOME)/.local/share/zsh/plugins" ]; then \
		failed=0; \
		for plugin in "$(HOME)/.local/share/zsh/plugins"/*; do \
			if [ -d "$$plugin/.git" ]; then \
				plugin_name=$$(basename "$$plugin"); \
				echo "Updating $$plugin_name..."; \
				if (cd "$$plugin" && git pull --quiet); then \
					echo "✅ $$plugin_name updated"; \
				else \
					echo "❌ $$plugin_name failed"; failed=1; \
				fi; \
			fi; \
		done; \
		exit $$failed; \
	else \
		echo "❌ No plugins directory found. Run 'make install' first."; \
		exit 1; \
	fi

## Show dependencies
deps:
	@echo "$(GREEN)Dependencies for $(OS_NAME):$(NC)"
	@echo ""
	@echo "$(YELLOW)Required:$(NC)"
	@echo "  git       - Version control"
	@echo "  zsh       - Shell"
	@echo "  vim       - Text editor"
	@echo "  curl      - Download tool"
	@echo ""
	@echo "$(YELLOW)Validation and Hooks:$(NC)"
	@echo "  make, bash, zsh, vim, git, jq, ripgrep, shellcheck - offline tests"
	@echo "  pre-commit - optional hooks (also downloads hook environments)"
	@echo "  mcpm, uvx, jq, zsh, macOS Keychain - Atlassian targets"
	@echo ""
	@echo "$(YELLOW)Package Manager Specific:$(NC)"
	@if [ "$(OS)" = "darwin" ]; then \
		echo "  brew      - Package manager (Homebrew)"; \
	elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
		echo "  apt       - Package manager"; \
	elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
		echo "  dnf       - Package manager"; \
	elif [ "$(PACKAGE_MANAGER)" = "pacman" ]; then \
		echo "  pacman    - Package manager"; \
	fi
	@echo ""
	@echo "$(YELLOW)Recommended CLI Tools:$(NC)"
	@echo "  bat       - Better cat"
	@echo "  eza       - Better ls"
	@echo "  fd        - Better find"
	@echo "  fzf       - Fuzzy finder"
	@echo "  ripgrep   - Better grep"
	@echo "  jq        - JSON processor"
	@echo "  gh        - GitHub CLI"
	@echo ""
	@echo "$(YELLOW)Development Tools:$(NC)"
	@echo "  node      - JavaScript runtime"
	@echo "  python3   - Python interpreter"
	@echo "  go        - Go compiler"
	@echo "  rust      - Rust compiler"
	@echo ""
	@echo "$(CYAN)XDG Support:$(NC)"
	@echo "  Most applications listed above support XDG Base Directory Specification"

## Generate system documentation
docs:
	@echo "$(GREEN)Generating system documentation...$(NC)"
	@set -eu; umask 077; \
	[ ! -L SYSTEM_INFO.md ] && [ ! -d SYSTEM_INFO.md ] || { echo "Refusing linked/directory SYSTEM_INFO.md" >&2; exit 1; }; \
	temporary=$$(mktemp ./SYSTEM_INFO.md.XXXXXX); \
	trap 'rm -f "$$temporary"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; \
	{ \
		printf '# System Information\n\nGenerated on %s for %s\n\n' "$$(date)" "$(OS_NAME)"; \
		printf '## System Details\n- OS: %s\n- Architecture: %s\n' "$(OS_NAME)" "$(ARCH)"; \
		if [ "$(OS)" = linux ]; then printf '%s\n' "- Distribution: $(DISTRO)"; fi; \
		printf '%s\n' "- Package Manager: $(PACKAGE_MANAGER)" "" "## XDG Base Directory Specification" \
			"- XDG_CONFIG_HOME: $${XDG_CONFIG_HOME:-$$HOME/.config}" \
			"- XDG_DATA_HOME: $${XDG_DATA_HOME:-$$HOME/.local/share}" \
			"- XDG_CACHE_HOME: $${XDG_CACHE_HOME:-$$HOME/.cache}" \
			"- XDG_STATE_HOME: $${XDG_STATE_HOME:-$$HOME/.local/state}" "" "## Configuration Files"; \
		find config -type f \( -name '*.zsh' -o -name '*.vim' -o -name '.zsh*' -o -name '.zprofile' -o -name 'vimrc' -o -name 'gitconfig*' \) -exec printf -- '- %s\n' {} +; \
	} > "$$temporary"; \
	mv -f "$$temporary" SYSTEM_INFO.md
	@echo "✅ System documentation generated as SYSTEM_INFO.md"

## Install development tools
dev-setup:
	@echo "$(GREEN)Setting up development environment for $(OS_NAME)...$(NC)"
	@set -eu; \
	case "$(PACKAGE_MANAGER)" in \
		brew) brew install make bash zsh vim git jq ripgrep shellcheck pre-commit ;; \
		apt) sudo apt update; sudo apt install -y make bash zsh vim git jq ripgrep shellcheck pre-commit ;; \
		dnf) sudo dnf install -y make bash zsh vim git jq ripgrep ShellCheck pre-commit ;; \
		pacman) sudo pacman -Syu --needed make bash zsh vim git jq ripgrep shellcheck pre-commit ;; \
		*) echo "Unsupported development setup: $(OS)/$(DISTRO)" >&2; exit 1 ;; \
	esac
	@echo "✅ Development tools installed"

## Setup git hooks
git-hooks:
	@bash scripts/setup-pre-commit.sh

## Performance test
perf:
	@bash scripts/test-dotfiles.sh --performance

## Show make targets (alternative help)
list:
	@awk '/^[a-zA-Z_-]+:/ { sub(/:.*/, ""); print }' Makefile | sort -u
