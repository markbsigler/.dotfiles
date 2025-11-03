#!/usr/bin/env bash
# =============================================================================
# Profile Startup - Zsh Startup Performance Analysis
# =============================================================================
# Analyzes zsh startup time and identifies bottlenecks
# Supports: macOS and Linux
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
readonly ITERATIONS="${1:-10}"
readonly REPORT_FILE="$HOME/.dotfiles/logs/startup-profile-$(date +%Y%m%d-%H%M%S).txt"

# Ensure log directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# =============================================================================
# Logging Functions
# =============================================================================

info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

section() {
    echo -e "\n${CYAN}▶ $*${NC}\n"
}

# =============================================================================
# Performance Measurement Functions
# =============================================================================

measure_startup_time() {
    local iterations="$1"
    local shell="${2:-zsh}"
    
    section "Measuring $shell startup time ($iterations iterations)"
    
    local times=()
    local sum=0
    
    for i in $(seq 1 "$iterations"); do
        # Measure time in milliseconds
        if command -v gtime &> /dev/null; then
            # GNU time (more accurate)
            local time_ms=$(gtime -f "%e" "$shell" -i -c exit 2>&1 | tail -n1 | awk '{printf "%.0f", $1 * 1000}')
        else
            # Use time command (less accurate but available everywhere)
            local time_output=$( (time "$shell" -i -c exit) 2>&1 )
            # Parse real time from output
            local time_s=$(echo "$time_output" | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')
            local time_ms=$(echo "$time_s * 1000" | bc | cut -d. -f1)
        fi
        
        times+=("$time_ms")
        sum=$((sum + time_ms))
        
        # Progress indicator
        printf "  Run %2d/%d: %4d ms\n" "$i" "$iterations" "$time_ms"
    done
    
    # Calculate statistics
    local avg=$((sum / iterations))
    local min=$(printf '%s\n' "${times[@]}" | sort -n | head -1)
    local max=$(printf '%s\n' "${times[@]}" | sort -n | tail -1)
    
    # Calculate median
    local sorted=($(printf '%s\n' "${times[@]}" | sort -n))
    local median_idx=$((iterations / 2))
    local median=${sorted[$median_idx]}
    
    # Calculate standard deviation
    local variance_sum=0
    for time in "${times[@]}"; do
        local diff=$((time - avg))
        variance_sum=$((variance_sum + diff * diff))
    done
    local variance=$((variance_sum / iterations))
    local stddev=$(echo "sqrt($variance)" | bc)
    
    echo ""
    success "Statistics:"
    echo "  Average:  $avg ms"
    echo "  Median:   $median ms"
    echo "  Min:      $min ms"
    echo "  Max:      $max ms"
    echo "  Std Dev:  $stddev ms"
    
    # Performance rating
    echo ""
    if [[ $avg -lt 100 ]]; then
        success "Performance: Excellent (< 100ms)"
    elif [[ $avg -lt 200 ]]; then
        success "Performance: Good (< 200ms)"
    elif [[ $avg -lt 500 ]]; then
        warning "Performance: Acceptable (< 500ms)"
    else
        warning "Performance: Slow (> 500ms) - optimization recommended"
    fi
}

profile_with_zprof() {
    section "Detailed profiling with zprof"
    
    info "Running zsh with zprof enabled..."
    
    local zprof_output=$(zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof' 2>&1)
    
    echo "$zprof_output"
    echo ""
    
    # Extract top 5 slowest functions
    info "Top 5 slowest functions:"
    echo "$zprof_output" | grep -A 5 "num.*calls" | tail -n 5 || true
}

profile_individual_files() {
    section "Profiling individual configuration files"
    
    local config_dir="${ZDOTDIR:-$HOME/.config/zsh}"
    
    if [[ ! -d "$config_dir" ]]; then
        warning "Config directory not found: $config_dir"
        return 0
    fi
    
    info "Testing load time for each config file..."
    echo ""
    
    # Test each .zsh file individually
    for config_file in "$config_dir"/*.zsh; do
        if [[ ! -f "$config_file" ]]; then
            continue
        fi
        
        local filename=$(basename "$config_file")
        
        # Measure time to source the file
        local total_time=0
        local iterations=5
        
        for i in $(seq 1 $iterations); do
            local start=$(date +%s%N)
            zsh -c "source '$config_file'" 2>/dev/null || true
            local end=$(date +%s%N)
            local duration=$(( (end - start) / 1000000 ))  # Convert to ms
            total_time=$((total_time + duration))
        done
        
        local avg_time=$((total_time / iterations))
        
        # Color code based on time
        if [[ $avg_time -lt 10 ]]; then
            printf "  ${GREEN}%-30s %4d ms${NC}\n" "$filename" "$avg_time"
        elif [[ $avg_time -lt 50 ]]; then
            printf "  ${YELLOW}%-30s %4d ms${NC}\n" "$filename" "$avg_time"
        else
            printf "  ${RED}%-30s %4d ms${NC}\n" "$filename" "$avg_time"
        fi
    done
}

check_completion_cache() {
    section "Checking completion cache"
    
    local compdump_file="${COMPDUMP:-$HOME/.zcompdump}"
    
    if [[ -f "$compdump_file" ]]; then
        local age_days=$(( ($(date +%s) - $(stat -f %m "$compdump_file" 2>/dev/null || stat -c %Y "$compdump_file")) / 86400 ))
        
        info "Completion cache file: $compdump_file"
        info "Cache age: $age_days days"
        info "Cache size: $(du -h "$compdump_file" | cut -f1)"
        
        if [[ $age_days -gt 7 ]]; then
            warning "Cache is older than 7 days - consider rebuilding"
            info "Rebuild with: rm $compdump_file && zsh"
        else
            success "Cache is fresh"
        fi
    else
        warning "No completion cache found"
    fi
}

check_plugin_load_times() {
    section "Checking plugin load times"
    
    local plugin_dir="$HOME/.local/share/zsh/plugins"
    
    if [[ ! -d "$plugin_dir" ]]; then
        info "No plugin directory found: $plugin_dir"
        return 0
    fi
    
    info "Analyzing plugins..."
    echo ""
    
    for plugin in "$plugin_dir"/*; do
        if [[ ! -d "$plugin" ]]; then
            continue
        fi
        
        local plugin_name=$(basename "$plugin")
        local plugin_file=""
        
        # Find main plugin file
        for file in "$plugin/$plugin_name.plugin.zsh" "$plugin/$plugin_name.zsh" "$plugin/init.zsh"; do
            if [[ -f "$file" ]]; then
                plugin_file="$file"
                break
            fi
        done
        
        if [[ -z "$plugin_file" ]]; then
            continue
        fi
        
        # Measure load time
        local start=$(date +%s%N)
        zsh -c "source '$plugin_file'" 2>/dev/null || true
        local end=$(date +%s%N)
        local duration=$(( (end - start) / 1000000 ))  # Convert to ms
        
        printf "  %-40s %4d ms\n" "$plugin_name" "$duration"
    done
}

generate_recommendations() {
    section "Recommendations"
    
    cat << EOF
Performance Optimization Tips:

1. Lazy Loading:
   - Use lazy loading for version managers (nvm, pyenv, rbenv)
   - Defer loading of heavy plugins

2. Completion System:
   - Cache completions (already done if using .zcompdump)
   - Use compinit -C to skip security checks

3. Plugin Management:
   - Remove unused plugins
   - Consider async loading for non-critical plugins
   - Use plugin managers that support lazy loading

4. Configuration:
   - Move expensive operations to background
   - Reduce number of sourced files
   - Combine small config files

5. Version Managers:
   - Use lazy loading wrappers instead of full initialization
   - Initialize only when needed

6. History:
   - Limit HISTSIZE if very large
   - Use HIST_IGNORE_DUPS and other options to reduce size

Run this script periodically to track improvements:
  ./scripts/profile-startup.sh

Compare results over time using logs in:
  ~/.dotfiles/logs/startup-profile-*.txt

EOF
}

generate_report() {
    section "Generating report"
    
    {
        echo "Zsh Startup Performance Report"
        echo "======================================================================="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "OS: $(uname -s)"
        echo "Zsh Version: $(zsh --version)"
        echo ""
        echo "======================================================================="
        echo ""
    } > "$REPORT_FILE"
    
    # Append all output to report
    {
        measure_startup_time "$ITERATIONS"
        echo ""
        profile_individual_files
        echo ""
        check_completion_cache
        echo ""
        check_plugin_load_times
        echo ""
        generate_recommendations
    } | tee -a "$REPORT_FILE"
    
    echo ""
    success "Report saved to: $REPORT_FILE"
}

# =============================================================================
# Help Function
# =============================================================================

show_help() {
    cat << EOF
Profile Startup - Zsh Startup Performance Analysis

USAGE:
    $0 [ITERATIONS]

ARGUMENTS:
    ITERATIONS          Number of startup tests to run (default: 10)

EXAMPLES:
    $0                  # Run 10 iterations
    $0 20               # Run 20 iterations for more accurate results

WHAT IT MEASURES:
    - Average startup time over multiple runs
    - Statistical analysis (min, max, median, std dev)
    - Individual config file load times
    - Plugin load times
    - Completion cache status
    - Detailed profiling with zprof

OUTPUT:
    - Console output with color-coded results
    - Report file: ~/.dotfiles/logs/startup-profile-*.txt

INTERPRETING RESULTS:
    < 100ms: Excellent performance
    < 200ms: Good performance
    < 500ms: Acceptable performance
    > 500ms: Slow - optimization recommended

OPTIMIZATION:
    Run this script before and after making changes to measure impact

EOF
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Check for help flag
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # Print banner
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║            ZSH STARTUP PERFORMANCE PROFILER                  ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    info "Analyzing zsh startup performance..."
    info "Iterations: $ITERATIONS"
    echo ""
    
    # Run profiling
    generate_report
    
    echo ""
    info "To view detailed profiling, run:"
    echo "  zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof'"
}

# Run main function
main "$@"

