---
description: "Create pull request with auto-generated description"
argument_hint: "[issue-number]"
---

# /hansolo:ship

## Squadron Identity

Display Red Squadron identity:
```
echo ""
echo "Red Leader, standing by..."
echo ""
cat .claude/lib/banners/shipping.txt
echo ""
```

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

1. **If on main/master branch** OR **If PR already merged**:
   - **IMPORTANT**: Execute the command `/hansolo:launch --json`
   - DO NOT create the branch directly with git commands
   - DO NOT generate or pass a branch name
   - Parse the JSON response from /hansolo:launch
   - If JSON response received:
     - Display Gold Squadron identity from JSON:
       ```bash
       echo ""
       echo "Gold Leader, standing by..."
       echo ""
       cat .claude/lib/banners/launching.txt
       echo ""
       ```
     - Handle any user prompts from the JSON response
   - Wait for /hansolo:launch to complete before proceeding
   - Then continue with shipping process

3. **If open PR exists**:
   - Show the existing PR URL
   - Stop (no duplicate PR needed)

4. **If ready to ship**:
   - Invoke Red Squadron to create PR

## Ready to Ship

When branch is ready, the banner is already displayed from the squadron identity section above.
███████║██║  ██║██║██║     ██║     ██║██║ ╚████║╚██████╔╝
╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
```

## Red Squadron Invocation

Invoke the hansolo-red-squadron subagent to:
1. Analyze changes with git diff
2. Generate PR title and description
3. Link to related issues if provided
4. Create PR using GitHub CLI
5. Attempt to enable auto-merge
6. Return PR number and URL

Optional: Pass issue number as $1 to auto-link

## Post-flight: Monitor and Sync

After Red Squadron creates the PR, the ship command performs post-flight operations:

1. **Extract PR details from Red Squadron**:
   - Parse the JSON response for PR number and URL
   - If JSON_MODE not available, extract from text output

2. **Monitor PR until merged**:
   ```bash
   # Monitor PR with configurable timeout
   echo "🔄 Monitoring PR for merge completion..."
   .claude/scripts/monitor-pr-merge.sh $PR_NUMBER 300
   MERGE_STATUS=$?
   ```

3. **Handle merge results**:
   - **Success (0)**: PR merged → Call `/hansolo:sync` for cleanup
   - **Timeout (2)**: Suggest manual merge options
   - **Error (1)**: Show failure reason and next steps

4. **Auto-sync on success**:
   When PR is successfully merged, automatically execute `/hansolo:sync` to:
   - Switch back to main branch
   - Pull latest changes
   - Delete the merged feature branch
   - Prepare for next feature

**Implementation**:
```bash
# After PR creation, extract PR number
PR_NUMBER=<from-red-squadron>
PR_URL=<from-red-squadron>

# Monitor the PR
echo "🔄 Monitoring PR #$PR_NUMBER for merge..."
.claude/scripts/monitor-pr-merge.sh "$PR_NUMBER" 300
MERGE_STATUS=$?

if [[ $MERGE_STATUS -eq 0 ]]; then
    echo "✅ PR #$PR_NUMBER has been merged!"
    echo ""
    echo "🔄 Running /hansolo:sync to complete cleanup..."

    # Execute sync command for post-merge cleanup
    # The sync command will detect the merged branch and clean up
    /hansolo:sync

    echo ""
    echo "🚀 Ship complete! You're on updated main, ready for the next feature."

elif [[ $MERGE_STATUS -eq 2 ]]; then
    echo "⏱ Monitoring timed out. The PR is not merged yet."
    echo ""
    echo "You can:"
    echo "1. Check PR status: gh pr view $PR_NUMBER --web"
    echo "2. Merge manually: gh pr merge $PR_NUMBER --squash"
    echo "3. After merge, run: /hansolo:sync"

else
    echo "❌ PR merge failed or was closed without merging."
    echo "View details: $PR_URL"
fi
```

## Complete Workflow

The ship command provides a complete end-to-end workflow:

1. **Pre-flight** - Validates you're on a shippable branch (or creates one via launch)
2. **PR Creation** - Red Squadron generates and submits the PR
3. **Auto-merge Attempt** - Tries to enable automatic merge
4. **Monitoring** - Waits for PR to be merged (up to 5 minutes)
5. **Auto-sync** - Calls `/hansolo:sync` to cleanup and return to main

After successful shipping:
- ✅ PR created and merged
- ✅ Automatically synced via `/hansolo:sync`
- ✅ On main branch with latest changes
- ✅ Feature branch cleaned up
- ✅ Ready for next feature immediately

## Automatic Branch Creation

When a new branch is needed, the ship command will:
1. Execute `/hansolo:launch` without arguments
2. Let /hansolo:launch handle branch naming (it may prompt the user)
3. Wait for branch creation to complete
4. Continue with the shipping process once on the new branch