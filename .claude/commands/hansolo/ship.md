---
description: "Create pull request with auto-generated description"
argument_hint: "[issue-number]"
---

# /hansolo:ship

Smart shipping command that ensures you're on a proper feature branch before creating a PR.

## Pre-flight Checks

First, check the current branch state:
```bash
BRANCH_STATE=$(.claude/scripts/check-branch-state.sh)
NEEDS_NEW_BRANCH=$(echo "$BRANCH_STATE" | jq -r '.needs_new_branch')
STATE_MESSAGE=$(echo "$BRANCH_STATE" | jq -r '.message')
```

## Branch State Handling

Based on the branch state, take appropriate action:

1. **If on main/master branch**:
   - Inform user they need a feature branch
   - Prompt for feature name
   - Execute `/hansolo:launch <feature-name>`
   - Then proceed with shipping

2. **If PR already merged**:
   - Inform user the branch was already shipped
   - Prompt for new feature name
   - Execute `/hansolo:launch <feature-name>`
   - Then proceed with shipping

3. **If open PR exists**:
   - Show the existing PR URL
   - Stop (no duplicate PR needed)

4. **If ready to ship**:
   - Invoke Blue Squadron to create PR

## Blue Squadron Invocation

When branch is ready, invoke the han-solo-blue-squadron subagent to:
1. Analyze changes with git diff
2. Generate PR title and description
3. Link to related issues if provided
4. Create PR using GitHub CLI
5. Attempt to enable auto-merge
6. Return PR number and URL

Optional: Pass issue number as $1 to auto-link

## Post-flight: Monitor and Complete

After Blue Squadron creates the PR, the ship command performs post-flight operations:

```bash
# Extract PR number from Blue Squadron output
PR_NUMBER=<from-blue-squadron>

# Monitor PR until merged (handles both auto-merge and manual merge)
echo "Monitoring PR #$PR_NUMBER for merge completion..."
.claude/scripts/monitor-pr-merge.sh $PR_NUMBER
MERGE_STATUS=$?

if [[ $MERGE_STATUS -eq 0 ]]; then
    # PR was successfully merged
    echo "✓ PR #$PR_NUMBER has been merged!"

    # Save current branch for cleanup
    CURRENT_BRANCH=$(git branch --show-current)

    # Switch to main and pull latest
    echo "Switching to main branch..."
    git checkout main
    git pull origin main

    # Delete local feature branch
    echo "Cleaning up local branch..."
    git branch -D "$CURRENT_BRANCH" 2>/dev/null || true

    # Verify remote deletion
    if ! git ls-remote --heads origin "$CURRENT_BRANCH" | grep -q "$CURRENT_BRANCH"; then
        echo "✓ Remote branch automatically deleted"
    fi

    echo "✓ Ship complete! You're on updated main."

elif [[ $MERGE_STATUS -eq 2 ]]; then
    # Timeout - attempt manual merge if possible
    echo "Checking if manual merge is possible..."

    if gh pr view $PR_NUMBER --json mergeable -q '.mergeable' | grep -q "MERGEABLE"; then
        echo "Attempting manual merge..."
        if gh pr merge $PR_NUMBER --squash --delete-branch; then
            # Perform cleanup after manual merge
            git checkout main
            git pull origin main
            git branch -D "$(git branch --show-current)" 2>/dev/null || true
            echo "✓ Manually merged and cleaned up!"
        else
            echo "✗ Manual merge failed. Check PR manually."
        fi
    fi
else
    echo "✗ PR merge failed. Manual intervention required."
    echo "View PR: gh pr view $PR_NUMBER --web"
fi
```

## Complete Workflow

The ship command provides a complete end-to-end workflow:

1. **Pre-flight** - Validates you're on a shippable branch
2. **PR Creation** - Blue Squadron generates and submits the PR
3. **Auto-merge Attempt** - Tries to enable automatic merge
4. **Post-flight Monitoring** - Waits for merge (auto or manual)
5. **Cleanup** - Returns to main with latest changes

After successful shipping:
- ✓ PR merged (automatically or manually)
- ✓ On main branch with latest changes
- ✓ Local and remote feature branches deleted
- ✓ Ready for next feature

## Interactive Prompts

When a new branch is needed:
```
(USER INTERACTION REQUIRED)
[Current situation: <state_message>]
Please enter a name for the new feature branch: _
```

The command will then automatically create the branch and proceed with shipping.