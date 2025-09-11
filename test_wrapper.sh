#!/usr/bin/env bash
source "$1"

# Track when functions are called
PUSH_CALLED=false
PR_CHECK_CALLED=false

# Override git push
git() {
    if [[ "$1" == "push" ]]; then
        PUSH_CALLED=true
        echo "PUSH_ATTEMPTED"
    else
        command git "$@"
    fi
}

# Override gh pr list for merged check
gh() {
    if [[ "$*" == *"--state merged"* ]]; then
        PR_CHECK_CALLED=true
        echo "MERGED_PR_CHECK"
        # Simulate a merged PR exists
        echo '{"number": 42}'
    else
        echo ""
    fi
}

# Export tracking variables
export -f git gh
