#!/usr/bin/env bash
# Han-Solo Test Runner
# Executes all tests with appropriate timing for each stage

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Timing
STAGE_START=0
TOTAL_START=$(date +%s)

# Stage timing requirements
declare -A STAGE_LIMITS=(
    ["syntax"]=1
    ["linting"]=5
    ["regression"]=30
    ["integration"]=60
    ["performance"]=10
)

# Helper functions
start_stage() {
    local stage="$1"
    echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  Stage: $stage${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    STAGE_START=$(date +%s)
}

end_stage() {
    local stage="$1"
    local stage_end=$(date +%s)
    local stage_duration=$((stage_end - STAGE_START))
    local limit="${STAGE_LIMITS[$stage]:-60}"
    
    if [ "$stage_duration" -le "$limit" ]; then
        echo -e "${GREEN}✅ Stage completed in ${stage_duration}s (limit: ${limit}s)${NC}"
    else
        echo -e "${YELLOW}⚠️  Stage took ${stage_duration}s (limit: ${limit}s)${NC}"
    fi
}

run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    echo -ne "  Running $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_cmd" > /tmp/test_output.log 2>&1; then
        echo -e "${GREEN}✅${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌${NC}"
        echo -e "${RED}    Error output:${NC}"
        head -10 /tmp/test_output.log | sed 's/^/      /'
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

skip_test() {
    local test_name="$1"
    local reason="$2"
    
    echo -e "  Skipping $test_name... ${YELLOW}⏭️${NC} ($reason)"
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
}

# Stage 1: Syntax Checking (< 1 second)
run_syntax_checks() {
    start_stage "Syntax Checking"
    
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            run_test "$(basename "$script")" "bash -n '$script'" || true
        fi
    done
    
    end_stage "syntax"
}

# Stage 2: Linting (< 5 seconds)
run_linting() {
    start_stage "Linting (ShellCheck)"
    
    if command -v shellcheck > /dev/null 2>&1; then
        for script in scripts/*.sh; do
            if [ -f "$script" ]; then
                run_test "$(basename "$script")" "shellcheck '$script'" || true
            fi
        done
    else
        skip_test "ShellCheck" "shellcheck not installed"
        echo -e "${YELLOW}    Install with: brew install shellcheck (macOS) or apt-get install shellcheck (Linux)${NC}"
    fi
    
    end_stage "linting"
}

# Stage 3: Regression Tests (< 30 seconds)
run_regression_tests() {
    start_stage "Regression Tests"
    
    if [ -d "tests/regression" ]; then
        for test in tests/regression/*.test.sh; do
            if [ -f "$test" ] && [ -x "$test" ]; then
                run_test "$(basename "$test" .test.sh)" "$test" || true
            elif [ -f "$test" ]; then
                skip_test "$(basename "$test" .test.sh)" "not executable"
            fi
        done
    else
        skip_test "Regression tests" "tests/regression directory not found"
    fi
    
    end_stage "regression"
}

# Stage 4: Unit Tests (< 10 seconds)
run_unit_tests() {
    start_stage "Unit Tests"
    
    if command -v bats > /dev/null 2>&1; then
        if [ -d "tests/unit" ] && ls tests/unit/*.bats > /dev/null 2>&1; then
            for test in tests/unit/*.bats; do
                run_test "$(basename "$test" .bats)" "bats '$test'" || true
            done
        else
            skip_test "BATS unit tests" "no .bats files found"
        fi
    else
        skip_test "BATS tests" "bats not installed"
        echo -e "${YELLOW}    Install with: npm install -g bats${NC}"
    fi
    
    end_stage "performance"
}

# Stage 5: Integration Tests (< 60 seconds)
run_integration_tests() {
    start_stage "Integration Tests"
    
    if [ -d "tests/integration" ]; then
        for test in tests/integration/*.test.sh; do
            if [ -f "$test" ] && [ -x "$test" ]; then
                if [[ "$(basename "$test")" == *"docker"* ]] && ! command -v docker > /dev/null 2>&1; then
                    skip_test "$(basename "$test" .test.sh)" "docker not available"
                else
                    run_test "$(basename "$test" .test.sh)" "$test" || true
                fi
            elif [ -f "$test" ]; then
                skip_test "$(basename "$test" .test.sh)" "not executable"
            fi
        done
    else
        skip_test "Integration tests" "tests/integration directory not found"
    fi
    
    end_stage "integration"
}

# Stage 6: Performance Tests (< 10 seconds)
run_performance_tests() {
    start_stage "Performance Tests"
    
    # Quick performance check of critical operations
    run_test "ship --check performance" "timeout 5 ./scripts/ship-core.sh --check 2>/dev/null || [ \$? -eq 1 ]" || true
    run_test "scrub --dry-run performance" "timeout 3 ./scripts/scrub-core.sh --dry-run" || true
    
    end_stage "performance"
}

# Main execution
main() {
    echo -e "${BOLD}${GREEN}🧪 Han-Solo Test Suite${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Determine which stages to run based on context
    STAGE="${1:-all}"
    
    case "$STAGE" in
        pre-commit)
            # Quick checks only (< 1 second)
            run_syntax_checks
            ;;
        pre-push)
            # Medium checks (< 10 seconds)
            run_syntax_checks
            run_linting
            ;;
        pr|ci)
            # Comprehensive checks (< 2 minutes)
            run_syntax_checks
            run_linting
            run_regression_tests
            run_unit_tests
            run_integration_tests
            ;;
        all|full)
            # Everything including performance
            run_syntax_checks
            run_linting
            run_regression_tests
            run_unit_tests
            run_integration_tests
            run_performance_tests
            ;;
        *)
            echo -e "${YELLOW}Usage: $0 [pre-commit|pre-push|pr|all]${NC}"
            exit 1
            ;;
    esac
    
    # Final report
    TOTAL_END=$(date +%s)
    TOTAL_DURATION=$((TOTAL_END - TOTAL_START))
    
    echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  Test Summary${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo "  Total Tests: $TOTAL_TESTS"
    echo -e "  Passed: ${GREEN}$PASSED_TESTS${NC}"
    [ "$FAILED_TESTS" -gt 0 ] && echo -e "  Failed: ${RED}$FAILED_TESTS${NC}" || echo "  Failed: $FAILED_TESTS"
    [ "$SKIPPED_TESTS" -gt 0 ] && echo -e "  Skipped: ${YELLOW}$SKIPPED_TESTS${NC}" || echo "  Skipped: $SKIPPED_TESTS"
    echo "  Duration: ${TOTAL_DURATION}s"
    
    # Determine stage limit for overall timing
    case "$STAGE" in
        pre-commit) MAX_TIME=1 ;;
        pre-push) MAX_TIME=10 ;;
        pr|ci) MAX_TIME=120 ;;
        all|full) MAX_TIME=300 ;;
        *) MAX_TIME=300 ;;
    esac
    
    if [ "$TOTAL_DURATION" -le "$MAX_TIME" ]; then
        echo -e "  ${GREEN}✅ Completed within time limit (${MAX_TIME}s)${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Exceeded time limit (${MAX_TIME}s)${NC}"
    fi
    
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Exit code
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "\n${GREEN}✨ All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed!${NC}"
        exit 1
    fi
}

# Check if running from repo root
if [ ! -f "scripts/ship-core.sh" ]; then
    echo -e "${RED}Error: Must run from repository root${NC}"
    exit 1
fi

# Run main with all arguments
main "$@"