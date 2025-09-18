#!/bin/bash
set -euo pipefail

# Conflict Parser Utility
# Parses git conflict markers and provides structured output
# Used by Gold-Squadron and Rogue-Squadron

# Function to extract conflict sections
parse_conflict_file() {
    local file="$1"
    local line_num=0
    local in_conflict=false
    local conflict_num=0
    local current_section=""
    local ours_content=""
    local base_content=""
    local theirs_content=""
    local conflict_start=0

    while IFS= read -r line; do
        ((line_num++))

        if [[ "$line" =~ ^'<<<<<<< ' ]]; then
            in_conflict=true
            ((conflict_num++))
            conflict_start=$line_num
            current_section="ours"
            ours_content=""
            base_content=""
            theirs_content=""

        elif [[ "$line" =~ ^'||||||| ' ]] && [[ "$in_conflict" == true ]]; then
            current_section="base"

        elif [[ "$line" =~ ^'=======' ]] && [[ "$in_conflict" == true ]]; then
            current_section="theirs"

        elif [[ "$line" =~ ^'>>>>>>> ' ]] && [[ "$in_conflict" == true ]]; then
            in_conflict=false

            # Output conflict as JSON
            cat <<EOF
{
  "conflict_number": $conflict_num,
  "file": "$file",
  "start_line": $conflict_start,
  "end_line": $line_num,
  "sections": {
    "ours": $(echo "$ours_content" | jq -Rs .),
    "base": $(echo "$base_content" | jq -Rs .),
    "theirs": $(echo "$theirs_content" | jq -Rs .)
  }
}
EOF

        elif [[ "$in_conflict" == true ]]; then
            case "$current_section" in
                ours)
                    ours_content+="$line"$'\n'
                    ;;
                base)
                    base_content+="$line"$'\n'
                    ;;
                theirs)
                    theirs_content+="$line"$'\n'
                    ;;
            esac
        fi
    done < "$file"
}

# Function to analyze conflict type
analyze_conflict_type() {
    local ours="$1"
    local theirs="$2"
    local base="$3"

    if [[ -z "$ours" ]] && [[ -n "$theirs" ]]; then
        echo "add-remove"
    elif [[ -n "$ours" ]] && [[ -z "$theirs" ]]; then
        echo "remove-add"
    elif [[ "$ours" == "$theirs" ]]; then
        echo "identical"
    elif [[ -z "$base" ]]; then
        echo "both-added"
    else
        echo "both-modified"
    fi
}

# Function to suggest resolution
suggest_resolution() {
    local conflict_type="$1"
    local file="$2"

    case "$conflict_type" in
        identical)
            echo "Both sides made identical changes. Safe to keep either version."
            ;;
        add-remove)
            echo "One side added content, other side removed. Review if addition is needed."
            ;;
        remove-add)
            echo "One side removed content, other side added. Review if removal is intentional."
            ;;
        both-added)
            echo "Both sides added content at same location. May need to combine both additions."
            ;;
        both-modified)
            echo "Both sides modified same content differently. Manual review required."
            ;;
    esac
}

# Function to get conflict statistics
get_conflict_stats() {
    local total_conflicts=0
    local total_files=0

    for file in $(git diff --name-only --diff-filter=U); do
        ((total_files++))
        local file_conflicts=$(grep -c '^<<<<<<< ' "$file" 2>/dev/null || echo 0)
        ((total_conflicts += file_conflicts))
    done

    cat <<EOF
{
  "total_files_with_conflicts": $total_files,
  "total_conflict_blocks": $total_conflicts,
  "affected_files": [$(git diff --name-only --diff-filter=U | jq -R . | jq -s .)]
}
EOF
}

# Function to apply resolution strategy
apply_resolution() {
    local file="$1"
    local strategy="$2"
    local conflict_num="${3:-1}"

    case "$strategy" in
        ours)
            echo "Keeping our version (current branch)..."
            git checkout --ours "$file"
            ;;
        theirs)
            echo "Keeping their version (incoming branch)..."
            git checkout --theirs "$file"
            ;;
        base)
            echo "Reverting to base version..."
            git show :1:"$file" > "$file" 2>/dev/null || echo "No base version available"
            ;;
        manual)
            echo "Manual resolution required. Opening editor..."
            ${EDITOR:-vi} "$file"
            ;;
        *)
            echo "Unknown strategy: $strategy"
            return 1
            ;;
    esac
}

# Main execution
main() {
    local command="${1:-stats}"

    case "$command" in
        stats)
            get_conflict_stats
            ;;

        parse)
            local file="${2:-}"
            if [[ -z "$file" ]]; then
                echo "ERROR: File path required for parse command" >&2
                exit 1
            fi
            parse_conflict_file "$file"
            ;;

        list)
            git diff --name-only --diff-filter=U
            ;;

        analyze)
            for file in $(git diff --name-only --diff-filter=U); do
                echo "Analyzing: $file"
                parse_conflict_file "$file" | jq -r '.sections | to_entries | .[] | "\(.key): \(.value | split("\n") | length) lines"'
                echo ""
            done
            ;;

        resolve)
            local file="${2:-}"
            local strategy="${3:-manual}"
            if [[ -z "$file" ]]; then
                echo "ERROR: File path required for resolve command" >&2
                exit 1
            fi
            apply_resolution "$file" "$strategy"
            ;;

        help)
            cat <<EOF
Conflict Parser Utility

Usage: $0 <command> [options]

Commands:
  stats              Show conflict statistics (default)
  parse <file>       Parse conflicts in a specific file
  list               List all files with conflicts
  analyze            Analyze all conflicts
  resolve <file> <strategy>  Apply resolution strategy

Strategies:
  ours       Keep current branch version
  theirs     Keep incoming branch version
  base       Revert to common ancestor version
  manual     Open in editor for manual resolution

Examples:
  $0 stats
  $0 parse src/index.js
  $0 resolve src/index.js ours
  $0 analyze
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