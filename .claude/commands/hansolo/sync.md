---
description: "Sync repository - cleanup merged branches or rebase unmerged ones"
---

# /hansolo:sync

Multi-purpose synchronization command that adapts to your current branch state.

## Branch State Detection

First, determine what type of sync is needed:
1. Check current branch
2. If on main → Update mode
3. If on feature branch → Check if merged
4. Choose appropriate sync strategy

## Sync Modes

### 1. Cleanup Mode (Post-Merge)
When on a feature branch that has been merged:
- Display Gold Squadron "mission complete" banner
- Switch to main branch
- Pull latest changes from origin
- Delete local feature branch
- Verify remote branch deletion
- Leave you on updated main

### 2. Rebase Mode (Pre-Merge)
When on an unmerged feature branch:
- Fetch latest from origin
- Rebase onto origin/main
- Handle conflicts if they arise
- Maintain linear history

### 3. Update Mode (On Main)
When already on main branch:
- Pull latest changes
- Show current status

## Gold Squadron Invocation

Invoke the hansolo-gold-squadron subagent with the detected mode:
- Pass current branch and merge status
- Let Gold Squadron handle the appropriate sync operation
- Display squadron identity based on operation type

## Usage Patterns

### Manual Usage
```bash
/hansolo:sync  # Manually sync at any time
```

### Automatic Usage
Called automatically by `/hansolo:ship` after successful PR merge to complete the workflow.

## Complete Workflow Integration

When called by ship command:
1. Ship creates and monitors PR
2. After merge, ship calls sync
3. Sync detects merged branch
4. Performs cleanup automatically
5. Returns to main, ready for next feature

Note: This command is idempotent - safe to run multiple times.