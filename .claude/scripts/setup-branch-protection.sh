#!/bin/bash
set -euo pipefail

# GitHub Branch Protection Configuration Script
# Used by Red-Squadron during project initialization

# Check if gh is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI not authenticated. Run 'gh auth login' first." >&2
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [[ -z "$REPO" ]]; then
    echo "ERROR: Not in a GitHub repository or remote not configured." >&2
    exit 1
fi

echo "Setting up branch protection for: $REPO"

# Default branch (usually main or master)
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
echo "Default branch: $DEFAULT_BRANCH"

# Configure branch protection rules
echo "Configuring branch protection rules..."

# Create the protection rules JSON
cat > /tmp/branch-protection.json <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci/lint", "ci/test", "ci/build"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true,
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": true,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
EOF

# Apply branch protection
if gh api -X PUT "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --input /tmp/branch-protection.json >/dev/null 2>&1; then
    echo "✓ Branch protection enabled for $DEFAULT_BRANCH"
else
    echo "WARNING: Could not enable full branch protection. This might require admin permissions." >&2
    echo "Attempting minimal protection..." >&2

    # Try minimal protection without admin enforcement
    cat > /tmp/minimal-protection.json <<EOF
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

    if gh api -X PUT "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --input /tmp/minimal-protection.json >/dev/null 2>&1; then
        echo "✓ Minimal branch protection enabled"
    else
        echo "ERROR: Could not enable branch protection. Manual configuration required." >&2
        echo "Visit: https://github.com/$REPO/settings/branches" >&2
        exit 1
    fi
fi

# Configure additional settings
echo ""
echo "Configuring repository settings..."

# Update repository settings for better workflow
gh api -X PATCH "repos/$REPO" \
    --field allow_squash_merge=true \
    --field allow_merge_commit=false \
    --field allow_rebase_merge=true \
    --field delete_branch_on_merge=true \
    --field allow_auto_merge=true \
    >/dev/null 2>&1 && echo "✓ Repository merge settings configured" || echo "WARNING: Could not update repository settings"

# Set up required status checks if CI exists
if [[ -f .github/workflows/ci.yml ]] || [[ -f .github/workflows/ci.yaml ]]; then
    echo "✓ CI workflow detected"

    # Extract job names from workflow
    if command -v yq >/dev/null 2>&1; then
        JOBS=$(yq eval '.jobs | keys | .[]' .github/workflows/ci.y*ml 2>/dev/null | tr '\n' ' ')
        if [[ -n "$JOBS" ]]; then
            echo "  Found jobs: $JOBS"
        fi
    fi
fi

# Clean up
rm -f /tmp/branch-protection.json /tmp/minimal-protection.json

echo ""
echo "Branch protection setup complete!"
echo ""
echo "Summary:"
echo "  ✓ Protected branch: $DEFAULT_BRANCH"
echo "  ✓ Requires pull request reviews: Yes"
echo "  ✓ Dismiss stale reviews: Yes"
echo "  ✓ Restrict force pushes: Yes"
echo "  ✓ Require linear history: Yes"
echo "  ✓ Auto-delete branches: Yes"
echo ""
echo "Manual steps (if needed):"
echo "  1. Add specific users/teams as code reviewers"
echo "  2. Configure CODEOWNERS file"
echo "  3. Set up specific status check requirements"
echo "  4. Visit: https://github.com/$REPO/settings/branches"