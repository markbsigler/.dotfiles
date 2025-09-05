# .dotfiles Makefile
# Provides convenient commands for managing .dotfiles installation and maintenance

.PHONY: help install update clean backup test lint docs doctor fonts plugins status deps restore list

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
DOTFILES_DIR := $(HOME)/.dotfiles
BACKUP_DIR := $(HOME)/.dotfiles-backup-$(shell date +%Y%m%d-%H%M%S)

# OS Detection
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)

ifeq ($(OS),darwin)
	OS_NAME := macOS
	PACKAGE_MANAGER := brew
	STAT_CMD := stat -f '%Sm' -t '%j'
else ifeq ($(OS),linux)
	OS_NAME := Linux
	PACKAGE_MANAGER := apt
	STAT_CMD := stat -c '%Y' | xargs -I{} date -d @{} +'%j'
	# Detect Linux distribution
	DISTRO := $(shell test -f /etc/os-release && grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' || echo unknown)
	ifeq ($(DISTRO),ubuntu)
		PACKAGE_MANAGER := apt
	else ifeq ($(DISTRO),fedora)
		PACKAGE_MANAGER := dnf
	else ifeq ($(DISTRO),arch)
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
	@echo "  make lint           Lint shell scripts"
	@echo "  make clean          Clean up backup directories and logs"
	@echo "  make dev-setup      Install development tools"
	@echo "  make git-hooks      Setup git pre-commit hooks"
	@echo ""
	@echo "$(GREEN)Maintenance:$(NC)"
	@echo "  make backup         Create backup of current configs"
	@echo "  make restore        Restore from most recent backup"
	@echo "  make doctor         Check system health and dependencies"
	@echo "  make plugins        Update ZSH plugins"
	@echo "  make fonts          Install Agave Nerd Font"
	@echo ""
	@echo "$(GREEN)Information:$(NC)"
	@echo "  make status         Show .dotfiles status"
	@echo "  make deps           Show dependencies"
	@echo "  make docs           Generate system info documentation"
	@echo "  make list           Show all available targets"
	@echo "  make perf           Run performance tests"

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
test: test-zsh test-vim test-scripts test-integration

## Run comprehensive tests
test-all:
	@./scripts/test-dotfiles.sh

## Run quick tests only
test-quick:
	@./scripts/test-dotfiles.sh --quick

test-integration:
	@echo "$(GREEN)Running integration tests...$(NC)"
	@./scripts/test-dotfiles.sh --integration

test-zsh:
	@echo "$(GREEN)Testing ZSH configuration...$(NC)"
	@if [ -f config/zsh/os-detection.zsh ]; then \
		zsh -n config/zsh/os-detection.zsh && echo "✅ ZSH OS detection syntax OK" || echo "❌ ZSH OS detection syntax error"; \
	fi
	@if [ -f config/zsh/aliases.zsh ]; then \
		zsh -n config/zsh/aliases.zsh && echo "✅ ZSH aliases syntax OK" || echo "❌ ZSH aliases syntax error"; \
	fi
	@if [ -f config/zsh/functions.zsh ]; then \
		zsh -n config/zsh/functions.zsh && echo "✅ ZSH functions syntax OK" || echo "❌ ZSH functions syntax error"; \
	fi
	@if [ -f config/zsh/exports.zsh ]; then \
		zsh -n config/zsh/exports.zsh && echo "✅ ZSH exports syntax OK" || echo "❌ ZSH exports syntax error"; \
	fi
	@if [ -f config/zsh/prompt.zsh ]; then \
		zsh -n config/zsh/prompt.zsh && echo "✅ ZSH prompt syntax OK" || echo "❌ ZSH prompt syntax error"; \
	fi
	@if [ -f config/zsh/plugins.zsh ]; then \
		zsh -n config/zsh/plugins.zsh && echo "✅ ZSH plugins syntax OK" || echo "❌ ZSH plugins syntax error"; \
	fi

test-vim:
	@echo "$(GREEN)Testing Vim configuration...$(NC)"
	@if [ -f config/vim/vimrc ]; then \
		vim -e -T dumb --cmd 'try | source config/vim/vimrc | catch | cquit | endtry' +qall && \
		echo "✅ Vim config OK" || echo "❌ Vim config error"; \
	fi

test-scripts:
	@echo "$(GREEN)Testing shell scripts...$(NC)"
	@for script in install.sh scripts/*.sh; do \
		if [ -f "$$script" ]; then \
			bash -n "$$script" && echo "✅ $$script syntax OK" || echo "❌ $$script syntax error"; \
		fi; \
	done

## Lint shell scripts
lint:
	@echo "$(GREEN)Linting shell scripts...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -exec shellcheck {} + && echo "✅ Shellcheck passed"; \
	else \
		echo "$(YELLOW)Warning: shellcheck not installed$(NC)"; \
		echo "Install with:"; \
		if [ "$(OS)" = "darwin" ]; then \
			echo "  brew install shellcheck"; \
		elif [ "$(DISTRO)" = "ubuntu" ]; then \
			echo "  sudo apt install shellcheck"; \
		elif [ "$(DISTRO)" = "fedora" ]; then \
			echo "  sudo dnf install shellcheck"; \
		elif [ "$(DISTRO)" = "arch" ]; then \
			echo "  sudo pacman -S shellcheck"; \
		fi; \
	fi

## Clean up backup directories and logs
clean:
	@echo "$(GREEN)Cleaning up...$(NC)"
	@find $(HOME) -name ".dotfiles-backup-*" -type d -mtime +30 -print0 2>/dev/null | xargs -0 rm -rf
	@rm -f install.log logs/*.log
	@echo "✅ Cleaned old backups and logs"

## Create backup of current configs
backup:
	@echo "$(GREEN)Creating backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@if [ -f $(HOME)/.zshrc ]; then cp $(HOME)/.zshrc $(BACKUP_DIR)/; fi
	@if [ -f $(HOME)/.gitconfig ]; then cp $(HOME)/.gitconfig $(BACKUP_DIR)/; fi
	@if [ -f $(HOME)/.vimrc ]; then cp $(HOME)/.vimrc $(BACKUP_DIR)/; fi
	@if [ -d $(HOME)/.config/zsh ]; then cp -r $(HOME)/.config/zsh $(BACKUP_DIR)/; fi
	@echo "✅ Backup created at $(BACKUP_DIR)"

## Restore from most recent backup
restore:
	@echo "$(GREEN)Restoring from backup...$(NC)"
	@LATEST_BACKUP=$$(ls -dt $(HOME)/.dotfiles-backup-* 2>/dev/null | head -n1); \
	if [ -n "$$LATEST_BACKUP" ]; then \
		echo "Restoring from $$LATEST_BACKUP"; \
		cp -r $$LATEST_BACKUP/* $(HOME)/; \
		echo "✅ Restored from backup"; \
	else \
		echo "❌ No backup found"; \
	fi

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
	@echo "Shell: $$SHELL"
	@echo "Package Manager: $(PACKAGE_MANAGER)"
	@echo ""
	@echo "$(YELLOW)Required Tools:$(NC)"
	@for cmd in git zsh vim curl; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo "✅ $$cmd: $$(command -v $$cmd)"; \
		else \
			echo "❌ $$cmd: not found"; \
		fi; \
	done
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
		elif [ "$$cmd" = "nvm" ] && [ -d "$$HOME/.nvm" ]; then \
			echo "✅ nvm: $$HOME/.nvm"; \
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
	@for link in \
		"$(HOME)/.config/zsh:$(DOTFILES_DIR)/config/zsh" \
		"$(HOME)/.zshrc:$(DOTFILES_DIR)/config/zsh/.zshrc" \
		"$(HOME)/.gitconfig:$(DOTFILES_DIR)/config/git/gitconfig" \
		"$(HOME)/.vimrc:$(DOTFILES_DIR)/config/vim/vimrc" \
		"$(HOME)/.config/nvim:$(DOTFILES_DIR)/config/nvim" \
	; do \
		target="$${link%%:*}"; \
		source="$${link##*:}"; \
		if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$source" ]; then \
			echo "✅ $$target → $$source"; \
		elif [ -e "$$target" ]; then \
			echo "⚠️  $$target exists but is not linked"; \
		else \
			echo "❌ $$target not found"; \
		fi; \
	done
	@echo ""
	@echo "$(YELLOW)Git Repository:$(NC)"
	@if [ -d .git ]; then \
		echo "Branch: $$(git branch --show-current 2>/dev/null || echo 'detached HEAD')"; \
		if git remote | grep -q origin 2>/dev/null; then \
			echo "Remote: $$(git remote get-url origin)"; \
		else \
			echo "Remote: No remote configured"; \
		fi; \
		echo ""; \
		echo "$(YELLOW)Working Tree Status:$(NC)"; \
		if git status --porcelain | grep -q .; then \
			git status --porcelain | head -5; \
			file_count=$$(git status --porcelain | wc -l); \
			if [ "$$file_count" -gt 5 ]; then \
				remaining=$$(( $$file_count - 5 )); \
				echo "... and $$remaining more files"; \
			fi; \
		else \
			echo "✅ Working tree is clean"; \
		fi; \
	else \
		echo "❌ Not a git repository"; \
	fi

## Install Nerd Fonts (Agave Nerd Font)
fonts:
	@echo "$(GREEN)Installing Agave Nerd Font...$(NC)"
	@if [ "$(OS_NAME)" = "macOS" ]; then \
		if command -v brew >/dev/null 2>&1; then \
			echo "Installing Agave Nerd Font via Homebrew..."; \
			brew install --cask font-agave-nerd-font; \
			echo "$(YELLOW)✅ Agave Nerd Font installed via Homebrew$(NC)"; \
			echo "$(YELLOW)📝 To set in Terminal: Terminal > Preferences > Profiles > Text > Change Font$(NC)"; \
			echo "$(YELLOW)📝 To set in iTerm2: iTerm2 > Preferences > Profiles > Text > Change Font$(NC)"; \
			echo "$(YELLOW)📝 Font name: 'AgaveNerdFont-Regular' or 'Agave Nerd Font'$(NC)"; \
		else \
			echo "$(YELLOW)Homebrew not found. Installing manually...$(NC)"; \
			echo "Downloading Agave Nerd Font..."; \
			curl -L -o /tmp/Agave.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Agave.zip; \
			mkdir -p $$HOME/Library/Fonts; \
			unzip -o /tmp/Agave.zip -d /tmp/AgaveNerdFont; \
			mv /tmp/AgaveNerdFont/*.ttf $$HOME/Library/Fonts/ 2>/dev/null || true; \
			rm -rf /tmp/Agave.zip /tmp/AgaveNerdFont; \
			echo "$(YELLOW)✅ Agave Nerd Font installed manually$(NC)"; \
		fi; \
	elif [ "$(OS_NAME)" = "Linux" ]; then \
		echo "Downloading Agave Nerd Font..."; \
		curl -L -o /tmp/Agave.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Agave.zip; \
		mkdir -p $$HOME/.local/share/fonts; \
		unzip -o /tmp/Agave.zip -d $$HOME/.local/share/fonts/AgaveNerdFont; \
		fc-cache -fv; \
		rm -f /tmp/Agave.zip; \
		echo "$(YELLOW)✅ Agave Nerd Font installed$(NC)"; \
		echo "$(YELLOW)📝 Set your terminal font to 'Agave Nerd Font' in preferences$(NC)"; \
	else \
		echo "$(YELLOW)Please manually install Agave Nerd Font from https://www.nerdfonts.com/font-downloads$(NC)"; \
	fi

## Update ZSH plugins
plugins:
	@echo "$(GREEN)Updating ZSH plugins...$(NC)"
	@if [ -d "$(HOME)/.local/share/zsh/plugins" ]; then \
		for plugin in $(HOME)/.local/share/zsh/plugins/*; do \
			if [ -d "$$plugin/.git" ]; then \
				plugin_name=$$(basename "$$plugin"); \
				echo "Updating $$plugin_name..."; \
				(cd "$$plugin" && git pull --quiet) && echo "✅ $$plugin_name updated" || echo "❌ $$plugin_name failed"; \
			fi; \
		done; \
	else \
		echo "❌ No plugins directory found. Run 'make install' first."; \
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
	@echo "$(YELLOW)Package Manager Specific:$(NC)"
	@if [ "$(OS)" = "darwin" ]; then \
		echo "  brew      - Package manager (Homebrew)"; \
	elif [ "$(DISTRO)" = "ubuntu" ]; then \
		echo "  apt       - Package manager"; \
	elif [ "$(DISTRO)" = "fedora" ]; then \
		echo "  dnf       - Package manager"; \
	elif [ "$(DISTRO)" = "arch" ]; then \
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
	@echo "# System Information" > SYSTEM_INFO.md
	@echo "" >> SYSTEM_INFO.md
	@echo "Generated on $$(date) for $(OS_NAME)" >> SYSTEM_INFO.md
	@echo "" >> SYSTEM_INFO.md
	@echo "## System Details" >> SYSTEM_INFO.md
	@echo "- OS: $(OS_NAME)" >> SYSTEM_INFO.md
	@echo "- Architecture: $(ARCH)" >> SYSTEM_INFO.md
	@if [ "$(OS)" = "linux" ]; then \
		echo "- Distribution: $(DISTRO)" >> SYSTEM_INFO.md; \
	fi
	@echo "- Package Manager: $(PACKAGE_MANAGER)" >> SYSTEM_INFO.md
	@echo "" >> SYSTEM_INFO.md
	@echo "## XDG Base Directory Specification" >> SYSTEM_INFO.md
	@echo "- XDG_CONFIG_HOME: $${XDG_CONFIG_HOME:-$$HOME/.config}" >> SYSTEM_INFO.md
	@echo "- XDG_DATA_HOME: $${XDG_DATA_HOME:-$$HOME/.local/share}" >> SYSTEM_INFO.md
	@echo "- XDG_CACHE_HOME: $${XDG_CACHE_HOME:-$$HOME/.cache}" >> SYSTEM_INFO.md
	@echo "- XDG_STATE_HOME: $${XDG_STATE_HOME:-$$HOME/.local/state}" >> SYSTEM_INFO.md
	@echo "" >> SYSTEM_INFO.md
	@echo "## Configuration Files" >> SYSTEM_INFO.md
	@find config -name "*.zsh" -o -name "*.vim" -o -name "gitconfig" 2>/dev/null | while read file; do \
		echo "- $$file" >> SYSTEM_INFO.md; \
	done
	@echo "✅ System documentation generated as SYSTEM_INFO.md"

## Install development tools
dev-setup:
	@echo "$(GREEN)Setting up development environment for $(OS_NAME)...$(NC)"
	@if [ "$(OS)" = "darwin" ] && command -v brew >/dev/null 2>&1; then \
		brew install shellcheck pre-commit; \
	elif [ "$(DISTRO)" = "ubuntu" ]; then \
		sudo apt install -y shellcheck; \
	elif [ "$(DISTRO)" = "fedora" ]; then \
		sudo dnf install -y shellcheck; \
	elif [ "$(DISTRO)" = "arch" ]; then \
		sudo pacman -S shellcheck; \
	fi
	@if command -v npm >/dev/null 2>&1; then \
		npm install -g markdownlint-cli; \
	fi
	@echo "✅ Development tools installed"

## Setup git hooks
git-hooks:
	@echo "$(GREEN)Setting up git hooks...$(NC)"
	@if [ -d .git ]; then \
		echo '#!/bin/bash' > .git/hooks/pre-commit; \
		echo 'make test' >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "✅ Pre-commit hook installed"; \
	else \
		echo "❌ Not a git repository"; \
	fi

## Performance test
perf:
	@echo "$(GREEN)Running performance tests...$(NC)"
	@echo "ZSH startup time (5 runs):"
	@for i in 1 2 3 4 5; do \
		(time zsh -i -c exit) 2>&1 | grep real; \
	done

## Show make targets (alternative help)  
list:
	@grep -E '^[a-zA-Z_-]+:' $(MAKEFILE_LIST) | cut -d: -f1 | sort | uniq
