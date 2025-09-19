#!/bin/bash
# JSON utility functions for han-solo

# Validate JSON response against squadron schema
validate_squadron_response() {
    local json="$1"

    # Check required fields
    if ! echo "$json" | jq -e '.squadron.name' >/dev/null 2>&1; then
        echo "ERROR: Missing squadron.name in JSON response" >&2
        return 1
    fi

    if ! echo "$json" | jq -e '.status' >/dev/null 2>&1; then
        echo "ERROR: Missing status in JSON response" >&2
        return 1
    fi

    # Validate squadron name
    local squadron=$(echo "$json" | jq -r '.squadron.name')
    case "$squadron" in
        gold|red|blue|gray|green|rogue)
            ;;
        *)
            echo "ERROR: Invalid squadron name: $squadron" >&2
            return 1
            ;;
    esac

    # Validate status
    local status=$(echo "$json" | jq -r '.status')
    case "$status" in
        ready|awaiting_input|in_progress|completed|error)
            ;;
        *)
            echo "ERROR: Invalid status: $status" >&2
            return 1
            ;;
    esac

    return 0
}

# Extract and display banner from JSON response
display_json_banner() {
    local json="$1"
    local banner=$(echo "$json" | jq -r '.display.banner // empty')

    if [[ -n "$banner" ]]; then
        echo "$banner"
    fi
}

# Extract and display message from JSON response
display_json_message() {
    local json="$1"
    local message=$(echo "$json" | jq -r '.display.message // empty')

    if [[ -n "$message" ]]; then
        echo "$message"
    fi
}

# Extract and display prompt from JSON response
display_json_prompt() {
    local json="$1"
    local prompt=$(echo "$json" | jq -r '.display.prompt // empty')

    if [[ -n "$prompt" ]]; then
        echo "$prompt"
    fi
}

# Create error JSON response
create_error_json() {
    local squadron="$1"
    local error_code="$2"
    local error_message="$3"

    cat <<EOF
{
    "squadron": {
        "name": "$squadron"
    },
    "status": "error",
    "error": {
        "code": "$error_code",
        "message": "$error_message"
    }
}
EOF
}

# Parse squadron identity from JSON
parse_squadron_identity() {
    local json="$1"

    local squadron=$(echo "$json" | jq -r '.squadron.name // empty')
    local quote=$(echo "$json" | jq -r '.squadron.quote // empty')
    local banner_type=$(echo "$json" | jq -r '.squadron.banner_type // empty')

    if [[ -n "$squadron" && -n "$quote" ]]; then
        echo ""
        echo "$quote"
        if [[ -n "$banner_type" ]]; then
            source .claude/lib/squadron-utils.sh
            display_banner "$banner_type"
        fi
    fi
}

# Check if response needs user input
needs_user_input() {
    local json="$1"
    local status=$(echo "$json" | jq -r '.status')

    [[ "$status" == "awaiting_input" ]]
}

# Extract next action from JSON
get_next_action() {
    local json="$1"
    echo "$json" | jq -r '.next_action // empty'
}