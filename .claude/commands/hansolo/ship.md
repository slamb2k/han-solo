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
5. Display PR URL and CI status

Optional: Pass issue number as $1 to auto-link

## Interactive Prompts

When a new branch is needed:
```
(USER INTERACTION REQUIRED)
[Current situation: <state_message>]
Please enter a name for the new feature branch: _
```

The command will then automatically create the branch and proceed with shipping.