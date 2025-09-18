#!/bin/bash
set -euo pipefail

# Performance Monitoring Script
# Tracks hook execution times and system performance

LOG_FILE="${HAN_SOLO_LOG:-/tmp/han-solo-performance.log}"
THRESHOLD_MS=100  # Performance threshold in milliseconds

# Function to get nanosecond timestamp
get_nano_time() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Use python for nanosecond precision
        python3 -c 'import time; print(int(time.time() * 1e9))'
    else
        # Linux: Use date command
        date +%s%N
    fi
}

# Function to calculate duration in milliseconds
calc_duration_ms() {
    local start=$1
    local end=$2
    echo $(( (end - start) / 1000000 ))
}

# Function to log performance metric
log_metric() {
    local hook_name="$1"
    local duration_ms="$2"
    local status="${3:-success}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create log entry
    local log_entry=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "hook": "$hook_name",
  "duration_ms": $duration_ms,
  "status": "$status",
  "threshold_exceeded": $([ $duration_ms -gt $THRESHOLD_MS ] && echo "true" || echo "false")
}
EOF
    )

    # Append to log file
    echo "$log_entry" >> "$LOG_FILE"

    # Return warning if threshold exceeded
    if [[ $duration_ms -gt $THRESHOLD_MS ]]; then
        echo "WARNING: Hook '$hook_name' took ${duration_ms}ms (threshold: ${THRESHOLD_MS}ms)" >&2
        return 1
    fi
    return 0
}

# Function to analyze performance logs
analyze_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No performance logs found at: $LOG_FILE" >&2
        return 1
    fi

    # Parse logs and calculate statistics
    local total_executions=$(wc -l < "$LOG_FILE")
    local slow_executions=$(jq -s '[.[] | select(.threshold_exceeded == true)] | length' "$LOG_FILE" 2>/dev/null || echo 0)

    # Calculate average duration per hook
    local hook_stats=$(jq -s '
        group_by(.hook) |
        map({
            hook: .[0].hook,
            count: length,
            avg_ms: ([.[].duration_ms] | add / length | floor),
            max_ms: ([.[].duration_ms] | max),
            min_ms: ([.[].duration_ms] | min),
            slow_count: ([.[] | select(.threshold_exceeded == true)] | length)
        })
    ' "$LOG_FILE" 2>/dev/null || echo "[]")

    # Output analysis
    cat <<EOF | jq .
{
  "summary": {
    "total_executions": $total_executions,
    "slow_executions": $slow_executions,
    "performance_rate": $([ $total_executions -gt 0 ] && echo "scale=2; ($total_executions - $slow_executions) * 100 / $total_executions" | bc || echo 100)
  },
  "by_hook": $hook_stats,
  "recommendations": $(
    if [[ $slow_executions -gt 5 ]]; then
      cat <<RECS | jq -R . | jq -s .
Review hook implementations for optimization opportunities
Consider caching frequently accessed data
Move expensive operations to background tasks
Use early exit conditions where possible
RECS
    else
      echo '["Performance is within acceptable limits"]'
    fi
  )
}
EOF
}

# Function to clean old logs
clean_logs() {
    local days="${1:-7}"
    local cutoff_date=$(date -d "$days days ago" +%Y-%m-%d 2>/dev/null || date -v -${days}d +%Y-%m-%d)

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No logs to clean" >&2
        return 0
    fi

    # Create temp file with recent entries only
    local temp_file=$(mktemp)
    jq -s ".[] | select(.timestamp >= \"$cutoff_date\")" "$LOG_FILE" > "$temp_file" 2>/dev/null

    # Replace log file
    mv "$temp_file" "$LOG_FILE"
    echo "Cleaned logs older than $days days"
}

# Function to monitor hook execution
monitor_hook() {
    local hook_name="$1"
    shift  # Remove hook_name from arguments

    # Start timing
    local start_time=$(get_nano_time)

    # Execute the hook with remaining arguments
    local exit_code=0
    "$@" || exit_code=$?

    # End timing
    local end_time=$(get_nano_time)
    local duration_ms=$(calc_duration_ms $start_time $end_time)

    # Log the metric
    local status="success"
    [[ $exit_code -ne 0 ]] && status="failure"
    log_metric "$hook_name" "$duration_ms" "$status"

    # Return original exit code
    return $exit_code
}

# Function to show real-time monitoring
realtime_monitor() {
    echo "Monitoring han-solo performance (press Ctrl+C to stop)..."
    echo ""

    # Create named pipe for real-time updates
    local pipe=$(mktemp -u)
    mkfifo "$pipe"

    # Start background tail process
    tail -f "$LOG_FILE" 2>/dev/null > "$pipe" &
    local tail_pid=$!

    # Process incoming logs
    while IFS= read -r line; do
        local hook=$(echo "$line" | jq -r .hook 2>/dev/null || echo "unknown")
        local duration=$(echo "$line" | jq -r .duration_ms 2>/dev/null || echo "0")
        local status=$(echo "$line" | jq -r .status 2>/dev/null || echo "unknown")
        local exceeded=$(echo "$line" | jq -r .threshold_exceeded 2>/dev/null || echo "false")

        # Format output with color
        if [[ "$exceeded" == "true" ]]; then
            echo -e "\033[31m[SLOW]\033[0m $hook: ${duration}ms ($status)"
        elif [[ "$status" == "failure" ]]; then
            echo -e "\033[33m[FAIL]\033[0m $hook: ${duration}ms"
        else
            echo -e "\033[32m[OK]\033[0m   $hook: ${duration}ms"
        fi
    done < "$pipe"

    # Cleanup
    kill $tail_pid 2>/dev/null
    rm -f "$pipe"
}

# Main execution
main() {
    local command="${1:-help}"

    case "$command" in
        start)
            shift
            monitor_hook "$@"
            ;;

        analyze)
            analyze_logs
            ;;

        clean)
            clean_logs "${2:-7}"
            ;;

        monitor)
            realtime_monitor
            ;;

        test)
            # Test performance logging
            echo "Testing performance monitoring..."
            monitor_hook "test-hook" sleep 0.05
            monitor_hook "slow-test-hook" sleep 0.15
            echo "Test complete. Check analysis:"
            analyze_logs
            ;;

        help)
            cat <<EOF
Performance Monitoring Script

Usage: $0 <command> [options]

Commands:
  start <hook-name> <command>  Monitor hook execution
  analyze                       Analyze performance logs
  clean [days]                  Clean logs older than N days (default: 7)
  monitor                       Real-time performance monitoring
  test                          Test the monitoring system

Examples:
  $0 start pre-flight-check ./pre-flight-check.sh
  $0 analyze
  $0 clean 30
  $0 monitor

Environment Variables:
  HAN_SOLO_LOG    Log file path (default: /tmp/han-solo-performance.log)
EOF
            ;;

        *)
            echo "Unknown command: $command" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"