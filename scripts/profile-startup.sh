#!/usr/bin/env bash
# Profile zsh startup time
# Cross-platform shell performance profiling script

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
RUNS=10
DETAILED=false
SHELL_PATH="${SHELL:-/bin/zsh}"

# Logging functions
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }
section() { echo -e "${CYAN}━━━ $* ━━━${NC}"; }

# Show help
show_help() {
    cat << EOF
Shell Startup Profiler - Cross-Platform

Profile and analyze shell startup time to identify performance bottlenecks.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -n, --runs N        Number of runs (default: 10)
    -d, --detailed      Show detailed profiling with zprof
    -s, --shell PATH    Shell to profile (default: \$SHELL)

PROFILING MODES:

  1. Basic (default)
     - Runs shell N times
     - Reports average startup time
     - Shows min/max times

  2. Detailed (--detailed)
     - Loads zprof module
     - Shows function call times
     - Identifies slow functions

EXAMPLES:
    $0                      # Basic profiling (10 runs)
    $0 -n 20                # 20 runs for better average
    $0 --detailed           # Detailed function profiling
    $0 -s /bin/bash         # Profile bash instead of zsh

PERFORMANCE TARGETS:
    Excellent: < 0.1s
    Good:      0.1s - 0.3s
    Acceptable: 0.3s - 0.5s
    Slow:      > 0.5s (needs optimization)

OPTIMIZATION TIPS:
    - Use lazy loading for version managers
    - Enable completion caching
    - Minimize plugin count
    - Profile with --detailed to find bottlenecks

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--runs)
            RUNS="$2"
            shift 2
            ;;
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -s|--shell)
            SHELL_PATH="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate shell exists
if [[ ! -x "$SHELL_PATH" ]]; then
    error "Shell not found or not executable: $SHELL_PATH"
    exit 1
fi

# Check for time command
if ! command -v time &> /dev/null; then
    error "The 'time' command is required but not found"
    exit 1
fi

# Detect time command type (GNU vs BSD)
detect_time_cmd() {
    if time --version &> /dev/null; then
        echo "gnu"
    else
        echo "bsd"
    fi
}

# Basic profiling
profile_basic() {
    section "Basic Startup Profiling"
    info "Shell: $SHELL_PATH"
    info "Runs: $RUNS"
    echo
    
    local time_cmd
    time_cmd=$(detect_time_cmd)
    
    local times=()
    local total=0
    
    info "Running $RUNS iterations..."
    for i in $(seq 1 "$RUNS"); do
        if [[ "$time_cmd" == "gnu" ]]; then
            # GNU time (Linux)
            local elapsed
            elapsed=$( (time -p "$SHELL_PATH" -i -c exit) 2>&1 | awk '/^real/ {print $2}')
        else
            # BSD time (macOS)
            local elapsed
            elapsed=$( (time "$SHELL_PATH" -i -c exit) 2>&1 | awk '/real/ {print $2}')
        fi
        
        times+=("$elapsed")
        total=$(echo "$total + $elapsed" | bc)
        
        # Show progress
        printf "."
    done
    echo
    echo
    
    # Calculate statistics
    local average
    average=$(echo "scale=3; $total / $RUNS" | bc)
    
    # Find min and max
    local min max
    min=$(printf '%s\n' "${times[@]}" | sort -n | head -1)
    max=$(printf '%s\n' "${times[@]}" | sort -n | tail -1)
    
    # Display results
    section "Results"
    echo "Average: ${average}s"
    echo "Min:     ${min}s"
    echo "Max:     ${max}s"
    echo
    
    # Performance assessment
    if (( $(echo "$average < 0.1" | bc -l) )); then
        success "Excellent performance! Your shell starts very quickly."
    elif (( $(echo "$average < 0.3" | bc -l) )); then
        success "Good performance. Shell startup is fast."
    elif (( $(echo "$average < 0.5" | bc -l) )); then
        warning "Acceptable performance, but there's room for improvement."
        info "Run with --detailed to identify bottlenecks."
    else
        warning "Slow startup detected. Optimization recommended."
        info "Run with --detailed to identify bottlenecks."
    fi
    echo
    
    # Show all times if verbose
    if [[ "${VERBOSE:-false}" == true ]]; then
        info "Individual run times:"
        for i in "${!times[@]}"; do
            echo "  Run $((i+1)): ${times[$i]}s"
        done
        echo
    fi
}

# Detailed profiling with zprof
profile_detailed() {
    section "Detailed Profiling (zprof)"
    info "This will show which functions are taking the most time"
    echo
    
    # Check if shell is zsh
    if [[ ! "$SHELL_PATH" =~ zsh ]]; then
        warning "Detailed profiling only works with zsh"
        return 1
    fi
    
    info "Running detailed profiling..."
    echo
    
    # Run zsh with zprof enabled
    "$SHELL_PATH" -i -c 'zmodload zsh/zprof && zprof' 2>&1 | grep -v "^$"
    
    echo
    info "Interpretation:"
    echo "  - 'calls' shows how many times each function was called"
    echo "  - 'time self' shows time spent in the function itself"
    echo "  - 'time total' shows time including called functions"
    echo "  - Focus on optimizing functions with high 'time total'"
    echo
}

# Main function
main() {
    echo
    info "🔍 Shell Startup Profiler"
    echo
    
    if [[ "$DETAILED" == true ]]; then
        profile_detailed
    else
        profile_basic
    fi
    
    section "Optimization Tips"
    cat << 'EOF'
1. Lazy load version managers (nvm, pyenv, rbenv)
   - Load on first use instead of at startup

2. Enable completion caching
   - Use compinit -C to skip security checks

3. Minimize plugins
   - Remove unused plugins
   - Update plugins regularly

4. Profile config files
   - Comment out sections to find slow parts
   - Use 'zmodload zsh/zprof' for detailed analysis

5. Check for slow network calls
   - Avoid API calls during startup
   - Cache results when possible

For more help:
  Run with --detailed to see function-level profiling
  Check ~/.config/zsh/ files for optimization opportunities
  Use 'time zsh -i -c exit' to test after changes

EOF
}

# Run main function
main

exit 0

