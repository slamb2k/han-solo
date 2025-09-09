# scrub

Comprehensive branch scrubbing tool that safely removes merged and orphaned branches while preserving uncommitted work.

## Purpose
Clean up local and remote branches that have been fully merged, while protecting branches with unmerged commits. Provides detailed reporting of all cleanup actions.

**Note:** This command is automatically run with `--quiet` flag after successful `/ship` operations. You can also run it manually at any time for comprehensive branch cleanup.

## Usage
```bash
# Manual cleanup - prompts for questionable branches (recommended for periodic maintenance)
/scrub

# Force scrub - deletes even with potential data loss (use with caution!)
/scrub --force

# Quiet mode - no prompts, only safe deletions (used automatically by /ship)
/scrub --quiet

# Preview what would be deleted without making changes
/scrub --dry-run

# Combine flags for different behaviors
/scrub --quiet --dry-run  # Preview what quiet mode would delete
```

## Options
- `--force`: Delete branches even if they have unmerged commits (dangerous!)
- `--quiet`: Skip all prompts, only delete obviously safe branches (automatically used by `/ship`)
- `--dry-run`: Show what would be deleted without actually deleting

## When to Use Manually
- **Periodic maintenance**: Run `/scrub` weekly or monthly to keep your repository clean
- **After collaborative work**: Clean up feature branches from merged PRs
- **Before starting new work**: Ensure a clean workspace
- **After manual PR merges**: If you merged PRs outside of `/ship`
- **After squash-merges**: Automatically detects and cleans squash-merged branches

## What it does
1. **Fetches and prunes** remote references
2. **Identifies orphaned remote branches** with merged PRs
3. **Detects squash-merged branches** using multiple methods:
   - Checks if commits are cherry-pick equivalent
   - Compares cumulative patches for identical changes
   - Searches for PR merge commits referencing the branch
4. **Prompts for confirmation** on questionable branches (unless --force or --quiet)
5. **Cleans local branches** that are fully merged or squash-merged
6. **Provides detailed summary** of all actions taken

## Safety Features
- Never deletes branches with open PRs
- Shows commit preview before asking for deletion
- Default answer is "No" for all prompts
- Preserves branches with unmerged work by default
- Reports all preserved branches for manual review

## Example Output

### Standard Mode
```
🔍 Analyzing branches...
✓ Found 5 remote branches to check
✓ Found 3 local branches to check

⚠️ Branch feat/experimental has 3 unmerged commit(s)
Recent commits:
  abc123 fix: typo
  def456 test: add test
Delete this branch? (y/N): n
⏭️ Preserved feat/experimental

🗑️ Deleted orphaned remote: feat/old-feature (PR #5 merged)
🧹 Deleted local branch: fix/typo

📊 Cleanup Summary:
  • Deleted 2 remote branch(es)
  • Deleted 1 local branch(es)
  • Preserved 1 branch(es) with unmerged commits
    - feat/experimental (3 commits)
```

### Example with Squash-Merged Branches
```
🔍 Analyzing branches...
✓ Found 5 remote branches to check
✓ Found 3 local branches to check

🗑️ Deleted squash-merged remote: feat/new-feature (PR #10)
🧹 Deleted squash-merged local: feat/new-feature
🧹 Deleted squash-merged local: fix/bug-123
🧹 Deleted local branch: chore/cleanup

📊 Cleanup Summary:
  • Deleted 1 remote branch(es)
  • Deleted 3 local branch(es)
  • All squash-merged branches detected and cleaned
```

## Invocation rule
Always delegate to a general-purpose agent for execution.

## Instructions
Execute the branch cleanup workflow with these steps:

1. Parse command flags (--force, --quiet, --dry-run)
2. Fetch latest remote state and prune deleted references
3. Analyze all remote branches (except main/master)
4. For each remote branch:
   - Skip if has open PR
   - Check if PR was merged
   - Count unmerged commits
   - Prompt user if questionable (unless --force or --quiet)
   - Delete if safe or confirmed
5. Analyze all local branches
6. For each local branch:
   - Check if fully merged
   - Check for remote tracking
   - Count unmerged commits
   - Prompt if has local-only commits (unless --force or --quiet)
   - Delete if safe or confirmed
7. Generate comprehensive report

## Implementation script
```bash
#!/bin/bash
set -e

# Use the scrub-core.sh script for implementation
if [ -f "./scripts/scrub-core.sh" ]; then
  ./scripts/scrub-core.sh "$@"
else
  echo "Error: scrub-core.sh script not found"
  echo "Please ensure han-solo is properly installed"
  exit 1
fi
```

## Allowed tools
- Bash
- Glob
- Grep
- Read