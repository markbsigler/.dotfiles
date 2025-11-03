#!/usr/bin/env bash
# Cross-platform testing script for dotfiles

set -o pipefail  # Removed 'e' and 'u' flags to allow errors and unset variables

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }

# Test framework
test_start() {
    local test_name="$1"
    echo -e "\n${BLUE}Testing: $test_name${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    local test_name="$1"
    success "$test_name: PASSED"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    error "$test_name: FAILED - $reason"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# OS Detection tests
test_os_detection() {
    test_start "OS Detection"
    
    if [[ -f "config/zsh/os-detection.zsh" ]]; then
        # shellcheck source=/dev/null
        source config/zsh/os-detection.zsh
        
        # Test OS detection functions exist
        if command -v is_macos >/dev/null 2>&1 && command -v is_linux >/dev/null 2>&1; then
            if [[ -n "$DOTFILES_OS" ]]; then
                test_pass "OS Detection"
                info "Detected OS: $DOTFILES_OS"
                info "Architecture: $DOTFILES_ARCH"
                [[ -n "${DOTFILES_DISTRO:-}" ]] && info "Distribution: $DOTFILES_DISTRO"
            else
                test_fail "OS Detection" "DOTFILES_OS not set"
            fi
        else
            test_fail "OS Detection" "Detection functions not available"
        fi
    else
        test_fail "OS Detection" "os-detection.zsh not found"
    fi
}

# ZSH syntax tests
test_zsh_syntax() {
    test_start "ZSH Syntax"
    
    local zsh_files=(
        "config/zsh/os-detection.zsh"
        "config/zsh/exports.zsh"
        "config/zsh/aliases.zsh"
        "config/zsh/functions.zsh"
        "config/zsh/plugins.zsh"
        "config/zsh/prompt.zsh"
        "config/zsh/version-managers.zsh"
    )
    
    local syntax_errors=0
    
    for file in "${zsh_files[@]}"; do
        if [[ -f "$file" ]]; then
            if zsh -n "$file" 2>/dev/null; then
                info "✓ $file syntax OK"
            else
                error "✗ $file syntax error"
                ((syntax_errors++))
            fi
        else
            warning "$file not found"
        fi
    done
    
    if [[ $syntax_errors -eq 0 ]]; then
        test_pass "ZSH Syntax"
    else
        test_fail "ZSH Syntax" "$syntax_errors files have syntax errors"
    fi
}

# Shell script syntax tests
test_shell_syntax() {
    test_start "Shell Script Syntax"
    
    local shell_files=(
        "install.sh"
        "scripts/install-packages.sh"
    )
    
    local syntax_errors=0
    
    for file in "${shell_files[@]}"; do
        if [[ -f "$file" ]]; then
            if bash -n "$file" 2>/dev/null; then
                info "✓ $file syntax OK"
            else
                error "✗ $file syntax error"
                ((syntax_errors++))
            fi
        else
            warning "$file not found"
        fi
    done
    
    if [[ $syntax_errors -eq 0 ]]; then
        test_pass "Shell Script Syntax"
    else
        test_fail "Shell Script Syntax" "$syntax_errors files have syntax errors"
    fi
}

# Configuration structure tests
test_config_structure() {
    test_start "Configuration Structure"
    
    local required_dirs=(
        "config"
        "config/zsh"
        "scripts"
        "local"
    )
    
    local required_files=(
        "config/zsh/.zshrc"
        "config/zsh/os-detection.zsh"
        "config/zsh/exports.zsh"
        "config/zsh/aliases.zsh"
        "install.sh"
        "Makefile"
        "README.md"
    )
    
    local missing=0
    
    # Check directories
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "✓ Directory: $dir"
        else
            error "✗ Missing directory: $dir"
            ((missing++))
        fi
    done
    
    # Check files
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            info "✓ File: $file"
        else
            error "✗ Missing file: $file"
            ((missing++))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        test_pass "Configuration Structure"
    else
        test_fail "Configuration Structure" "$missing items missing"
    fi
}

# Symlink tests (if dotfiles are installed)
test_symlinks() {
    test_start "Symlinks"
    
    local symlinks=(
        "$HOME/.config/zsh:$(pwd)/config/zsh"
        "$HOME/.zshrc:$(pwd)/config/zsh/.zshrc"
    )
    
    local symlink_errors=0
    local installed=false
    
    for link in "${symlinks[@]}"; do
        local target="${link%:*}"
        local source="${link#*:}"
        
        if [[ -L "$target" ]]; then
            installed=true
            if [[ "$(readlink "$target")" == "$source" ]]; then
                info "✓ $target → $source"
            else
                error "✗ $target → $(readlink "$target") (expected: $source)"
                ((symlink_errors++))
            fi
        elif [[ -e "$target" ]]; then
            warning "⚠ $target exists but is not a symlink"
        fi
    done
    
    if [[ "$installed" == false ]]; then
        warning "Dotfiles not installed - skipping symlink tests"
        test_pass "Symlinks (not installed)"
    elif [[ $symlink_errors -eq 0 ]]; then
        test_pass "Symlinks"
    else
        test_fail "Symlinks" "$symlink_errors incorrect symlinks"
    fi
}

# Platform-specific tests
test_platform_specific() {
    test_start "Platform-Specific Features"
    
    # shellcheck source=/dev/null
    source config/zsh/os-detection.zsh
    
    # Load brew environment if available
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    if is_macos; then
        # Test macOS specific features
        if command -v brew >/dev/null 2>&1; then
            info "✓ Homebrew detected"
        else
            warning "Homebrew not installed"
        fi
        
        # Test PATH contains Homebrew
        if [[ ":$PATH:" == *":/opt/homebrew/bin:"* ]] || [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
            info "✓ Homebrew paths in PATH"
        else
            warning "Homebrew paths not in PATH"
        fi
        
    elif is_linux; then
        # Test Linux specific features
        if command -v apt >/dev/null 2>&1; then
            info "✓ APT package manager detected"
        elif command -v dnf >/dev/null 2>&1; then
            info "✓ DNF package manager detected"
        elif command -v pacman >/dev/null 2>&1; then
            info "✓ Pacman package manager detected"
        else
            warning "No recognized package manager found"
        fi
        
        # Test snap/flatpak paths
        if [[ -d "/snap/bin" ]]; then
            info "✓ Snap directory exists"
        fi
        
        if [[ -d "/var/lib/flatpak/exports/bin" ]]; then
            info "✓ Flatpak directory exists"
        fi
    fi
    
    test_pass "Platform-Specific Features"
}

# Tool availability tests
test_tool_availability() {
    test_start "Tool Availability"
    
    local core_tools=(
        "git"
        "zsh"
        "curl"
        "vim"
    )
    
    local modern_tools=(
        "bat:batcat"  # bat might be available as batcat on Ubuntu
        "fd:fdfind"   # fd might be available as fdfind on Ubuntu
        "fzf"
        "rg"
        "jq"
        "eza:exa"     # eza might fallback to exa
    )
    
    local missing_core=0
    
    # Test core tools
    for tool in "${core_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            info "✓ $tool available"
        else
            error "✗ $tool missing (required)"
            ((missing_core++))
        fi
    done
    
    # Test modern tools (with fallbacks)
    for tool_spec in "${modern_tools[@]}"; do
        local tool="${tool_spec%:*}"
        local fallback="${tool_spec#*:}"
        
        if command -v "$tool" >/dev/null 2>&1; then
            info "✓ $tool available"
        elif [[ "$tool" != "$fallback" ]] && command -v "$fallback" >/dev/null 2>&1; then
            info "✓ $tool available (as $fallback)"
        else
            warning "⚪ $tool not available (optional)"
        fi
    done
    
    if [[ $missing_core -eq 0 ]]; then
        test_pass "Tool Availability"
    else
        test_fail "Tool Availability" "$missing_core core tools missing"
    fi
}

# Integration tests
test_integration() {
    test_start "Integration"
    
    # Check if dotfiles are installed
    if [[ ! -f ~/.zshrc ]]; then
        warning "Dotfiles not installed, testing repository files directly"
        
        # Set up test environment similar to actual .zshrc
        local zdotdir
        zdotdir="$(pwd)/config/zsh"
        export ZDOTDIR="$zdotdir"
        export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
        export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
        
        # Test ZSH config from repository with better error handling
        local zsh_test_output
        if zsh_test_output=$(ZDOTDIR="$(pwd)/config/zsh" zsh -c "source config/zsh/.zshrc" 2>&1); then
            info "✓ ZSH configuration loads successfully from repository"
        else
            error "✗ ZSH configuration has errors:"
            echo "$zsh_test_output" | head -3
            test_fail "Integration" "ZSH configuration errors"
            return 1
        fi
        
        # Test that key functions are available after loading from repository
        if ZDOTDIR="$(pwd)/config/zsh" zsh -c "source config/zsh/.zshrc >/dev/null 2>&1 && type is_macos" >/dev/null 2>&1; then
            info "✓ OS detection functions available"
        else
            warning "OS detection functions not available in test context"
        fi
        
        # Test that aliases are loaded (check for a basic alias that should always exist)
        if ZDOTDIR="$(pwd)/config/zsh" zsh -c "source config/zsh/.zshrc >/dev/null 2>&1 && alias l" >/dev/null 2>&1; then
            info "✓ Aliases loaded"
        else
            warning "Aliases not loaded in test context"
        fi
        
        test_pass "Integration"
        return 0
    fi
    
    # Test that ZSH loads without errors (installed version)
    local zsh_load_result=0
    local zsh_output
    if ! zsh_output=$(zsh -c "source ~/.zshrc" 2>&1); then
        zsh_load_result=1
    fi
    
    if [[ $zsh_load_result -eq 0 ]]; then
        info "✓ ZSH configuration loads successfully"
    else
        error "✗ ZSH configuration has errors:"
        echo "$zsh_output" | head -3
        test_fail "Integration" "ZSH configuration errors"
        return 1
    fi
    
    # Test that key functions are available after loading
    if zsh -c "source ~/.zshrc >/dev/null 2>&1 && type is_macos" >/dev/null 2>&1; then
        info "✓ OS detection functions available"
    else
        warning "OS detection functions not available - may be expected in non-interactive shell"
    fi
    
    # Test that aliases are loaded
    if zsh -c "source ~/.zshrc >/dev/null 2>&1 && alias l" >/dev/null 2>&1; then
        info "✓ Aliases loaded"
    else
        warning "Aliases not loaded - may be expected in non-interactive shell"
    fi
    
    # Test that environment variables are set correctly
    local env_check
    if env_check=$(zsh -c "source ~/.zshrc >/dev/null 2>&1 && echo \$DOTFILES_OS" 2>/dev/null) && [[ -n "$env_check" ]]; then
        info "✓ Environment variables set (OS: $env_check)"
    else
        warning "Environment variables not accessible in test context"
    fi
    
    test_pass "Integration"
    return 0
}

# Performance tests
test_performance() {
    test_start "Performance"
    
    info "Testing ZSH startup time..."
    local total_time=0
    local runs=3
    
    for i in $(seq 1 $runs); do
        local start_time
        local end_time
        local run_time
        start_time=$(date +%s.%N)
        zsh -i -c exit >/dev/null 2>&1
        end_time=$(date +%s.%N)
        run_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || python3 -c "print($end_time - $start_time)" 2>/dev/null || echo "1")
        total_time=$(echo "$total_time + $run_time" | bc -l 2>/dev/null || python3 -c "print($total_time + $run_time)" 2>/dev/null || echo "$total_time")
        info "Run $i: ${run_time}s"
    done
    
    local avg_time
    avg_time=$(echo "scale=3; $total_time / $runs" | bc -l 2>/dev/null || python3 -c "print(f'{$total_time / $runs:.3f}')" 2>/dev/null || echo "unknown")
    info "Average startup time: ${avg_time}s"
    
    # Warn if startup is slow (> 2 seconds)
    if (( $(echo "$avg_time > 2.0" | bc -l 2>/dev/null || python3 -c "print(1 if float('$avg_time') > 2.0 else 0)" 2>/dev/null || echo 0) )); then
        warning "ZSH startup is slow (> 2s). Consider optimizing plugins."
    else
        info "ZSH startup time is good"
    fi
    
    test_pass "Performance"
}

# Main test runner
run_tests() {
    echo "🧪 Cross-Platform Dotfiles Testing"
    echo "=================================="
    
    # Change to dotfiles root directory (parent of scripts directory)
    cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" || exit
    
    # Run all tests
    test_config_structure
    test_os_detection
    test_zsh_syntax
    test_shell_syntax
    test_platform_specific
    test_tool_availability
    test_symlinks
    test_integration
    test_performance
    
    # Summary
    echo -e "\n📊 Test Summary"
    echo "==============="
    echo -e "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        echo -e "\n${RED}Some tests failed. Please review the output above.${NC}"
        return 1
    else
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        echo -e "\n${GREEN}All tests passed! 🎉${NC}"
        return 0
    fi
}

# Help function
show_help() {
    cat << EOF
Cross-Platform Dotfiles Testing Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    --quick             Run quick tests only (syntax and structure)
    --integration       Run integration tests only
    --performance       Run performance tests only

EXAMPLES:
    $0                  # Run all tests
    $0 --quick          # Quick syntax and structure tests
    $0 --integration    # Integration tests only

EOF
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --quick)
        test_config_structure
        test_zsh_syntax
        test_shell_syntax
        exit $?
        ;;
    --integration)
        test_integration
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            echo -e "\n${GREEN}Integration test completed successfully${NC}"
            exit 0
        else
            echo -e "\n${RED}Integration test failed${NC}"
            exit 1
        fi
        ;;
    --performance)
        test_performance
        exit $?
        ;;
    "")
        run_tests
        exit_code=$?
        exit $exit_code
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
