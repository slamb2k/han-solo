#!/bin/bash
set -euo pipefail

# GitHub API Rate Limit Checker
# Used by status line and Blue-Squadron for API management

# Check if gh is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo '{"error": "GitHub CLI not authenticated"}' | jq .
    exit 1
fi

# Get rate limit information
RATE_LIMIT=$(gh api /rate_limit 2>/dev/null || echo '{}')

if [[ -z "$RATE_LIMIT" ]] || [[ "$RATE_LIMIT" == "{}" ]]; then
    echo '{"error": "Could not fetch rate limit information"}' | jq .
    exit 1
fi

# Extract core API limits
CORE_LIMIT=$(echo "$RATE_LIMIT" | jq -r '.rate.limit // 0')
CORE_REMAINING=$(echo "$RATE_LIMIT" | jq -r '.rate.remaining // 0')
CORE_RESET=$(echo "$RATE_LIMIT" | jq -r '.rate.reset // 0')

# Extract search API limits
SEARCH_LIMIT=$(echo "$RATE_LIMIT" | jq -r '.search.limit // 0')
SEARCH_REMAINING=$(echo "$RATE_LIMIT" | jq -r '.search.remaining // 0')
SEARCH_RESET=$(echo "$RATE_LIMIT" | jq -r '.search.reset // 0')

# Extract GraphQL API limits
GRAPHQL_LIMIT=$(echo "$RATE_LIMIT" | jq -r '.graphql.limit // 0')
GRAPHQL_REMAINING=$(echo "$RATE_LIMIT" | jq -r '.graphql.remaining // 0')
GRAPHQL_RESET=$(echo "$RATE_LIMIT" | jq -r '.graphql.reset // 0')

# Calculate percentages
if [[ $CORE_LIMIT -gt 0 ]]; then
    CORE_PERCENT=$((CORE_REMAINING * 100 / CORE_LIMIT))
else
    CORE_PERCENT=0
fi

if [[ $SEARCH_LIMIT -gt 0 ]]; then
    SEARCH_PERCENT=$((SEARCH_REMAINING * 100 / SEARCH_LIMIT))
else
    SEARCH_PERCENT=0
fi

if [[ $GRAPHQL_LIMIT -gt 0 ]]; then
    GRAPHQL_PERCENT=$((GRAPHQL_REMAINING * 100 / GRAPHQL_LIMIT))
else
    GRAPHQL_PERCENT=0
fi

# Calculate time until reset
CURRENT_TIME=$(date +%s)
if [[ $CORE_RESET -gt $CURRENT_TIME ]]; then
    CORE_RESET_MINUTES=$(( (CORE_RESET - CURRENT_TIME) / 60 ))
else
    CORE_RESET_MINUTES=0
fi

# Determine warning level
WARNING_LEVEL="ok"
WARNING_MESSAGE=""

if [[ $CORE_PERCENT -lt 10 ]]; then
    WARNING_LEVEL="critical"
    WARNING_MESSAGE="Critical: API limit nearly exhausted!"
elif [[ $CORE_PERCENT -lt 25 ]]; then
    WARNING_LEVEL="warning"
    WARNING_MESSAGE="Warning: API limit running low"
elif [[ $CORE_PERCENT -lt 50 ]]; then
    WARNING_LEVEL="caution"
    WARNING_MESSAGE="Caution: Over half of API limit used"
fi

# Function to format time until reset
format_reset_time() {
    local minutes=$1
    if [[ $minutes -gt 60 ]]; then
        echo "$((minutes / 60))h $((minutes % 60))m"
    else
        echo "${minutes}m"
    fi
}

# Output JSON format
cat <<EOF | jq .
{
  "core": {
    "limit": $CORE_LIMIT,
    "remaining": $CORE_REMAINING,
    "percent": $CORE_PERCENT,
    "reset_in": "$(format_reset_time $CORE_RESET_MINUTES)"
  },
  "search": {
    "limit": $SEARCH_LIMIT,
    "remaining": $SEARCH_REMAINING,
    "percent": $SEARCH_PERCENT
  },
  "graphql": {
    "limit": $GRAPHQL_LIMIT,
    "remaining": $GRAPHQL_REMAINING,
    "percent": $GRAPHQL_PERCENT
  },
  "warning": {
    "level": "$WARNING_LEVEL",
    "message": "$WARNING_MESSAGE"
  },
  "recommendations": $(
    if [[ $WARNING_LEVEL != "ok" ]]; then
      cat <<RECS | jq -R . | jq -s .
Use GraphQL API instead of REST when possible
Batch API requests where feasible
Cache API responses locally
Wait $(format_reset_time $CORE_RESET_MINUTES) for limit reset
RECS
    else
      echo "[]"
    fi
  )
}
EOF

# Exit with warning code if limits are low
if [[ $WARNING_LEVEL == "critical" ]]; then
    exit 2
elif [[ $WARNING_LEVEL == "warning" ]]; then
    exit 1
fi

exit 0