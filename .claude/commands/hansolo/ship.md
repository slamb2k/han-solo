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
5. Enable auto-merge with squash
6. Monitor PR until merged
7. Clean up branches after merge
8. Return to updated main branch

Optional: Pass issue number as $1 to auto-link

## Complete Workflow

The ship command now provides a complete end-to-end workflow:

1. **Pre-flight** - Ensures you're on a shippable branch
2. **Creation** - Generates and submits the PR
3. **Auto-merge** - Enables automatic squash merge when checks pass
4. **Monitoring** - Waits for CI completion and merge
5. **Cleanup** - Deletes branches and returns to main

After shipping completes, you'll be:
- On the main branch
- Synced with latest changes
- Ready for the next feature

No manual intervention needed for simple PRs!

## Interactive Prompts

When a new branch is needed:
```
(USER INTERACTION REQUIRED)
[Current situation: <state_message>]
Please enter a name for the new feature branch: _
```

The command will then automatically create the branch and proceed with shipping.