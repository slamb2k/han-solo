#!/bin/bash
# Squadron utility functions for han-solo

# Display squadron quote based on squadron name
display_squadron_quote() {
    local squadron="$1"
    case "$squadron" in
        gold)
            echo "Gold Leader, standing by..."
            ;;
        red)
            echo "Red Leader, standing by..."
            ;;
        blue)
            echo "Blue Leader, standing by..."
            ;;
        gray)
            echo "Gray Leader, standing by..."
            ;;
        green)
            echo "Green Leader, standing by..."
            ;;
        rogue)
            echo "Rogue Leader, standing by..."
            ;;
        *)
            echo "Squadron Leader, standing by..."
            ;;
    esac
}

# Display banner for squadron action
display_banner() {
    local banner_type="$1"
    local banner_file=""

    case "$banner_type" in
        LAUNCHING|launching)
            banner_file=".claude/lib/banners/launching.txt"
            ;;
        SHIPPING|shipping)
            banner_file=".claude/lib/banners/shipping.txt"
            ;;
        INITIALIZING|initializing)
            banner_file=".claude/lib/banners/initializing.txt"
            ;;
        COMMITTING|committing)
            banner_file=".claude/lib/banners/committing.txt"
            ;;
        SYNCING|syncing)
            banner_file=".claude/lib/banners/syncing.txt"
            ;;
        CONFIGURING|configuring)
            banner_file=".claude/lib/banners/configuring.txt"
            ;;
    esac

    if [[ -n "$banner_file" && -f "$banner_file" ]]; then
        echo ""
        cat "$banner_file"
        echo ""
    fi
}

# Check if JSON mode is requested
is_json_mode() {
    for arg in "$@"; do
        if [[ "$arg" == "--json" ]]; then
            return 0
        fi
    done
    return 1
}

# Create JSON response
create_json_response() {
    local squadron="$1"
    local response_status="$2"
    local data="$3"

    # Get squadron quote
    local quote=$(display_squadron_quote "$squadron")

    # Build JSON response
    cat <<EOF
{
    "squadron": {
        "name": "$squadron",
        "quote": "$quote",
        "banner_type": "${4:-}"
    },
    "status": "$response_status",
    "data": $data
}
EOF
}

# Parse JSON response field
parse_json_field() {
    local json="$1"
    local field="$2"
    echo "$json" | jq -r "$field" 2>/dev/null
}

# Display squadron identity (quote + banner) for non-JSON mode
display_squadron_identity() {
    local squadron="$1"
    local banner_type="$2"

    echo ""
    display_squadron_quote "$squadron"
    display_banner "$banner_type"
}