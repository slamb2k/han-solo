# Ship All Things: Complete Shipping Workflow Enhancement

## Overview
Enhancement to make `/hansolo:ship` a complete workflow orchestrator that handles the entire shipping process from branch creation to post-merge cleanup.

## Design Philosophy
- `/hansolo:ship` becomes the "do everything" command
- Individual commands (`/hansolo:launch`, `/hansolo:sync`) remain available for manual control
- Ship orchestrates: launch (if needed) → PR → monitor → sync (automatic cleanup)

## Workflow Design

### `/hansolo:ship` - Full Shipping Workflow
1. **Pre-flight checks** (current branch state)
2. **Launch if needed** (already implemented - keep it!)
3. **Create PR** (via Red Squadron)
4. **Monitor until merged** (new)
5. **Auto-sync after merge** (new - calls `/hansolo:sync`)
6. **End state**: User is back on main with latest changes

### `/hansolo:sync` - Multi-Purpose Synchronization
Can be called:
- **Manually by user** at any time
- **Automatically by ship** after successful merge

Handles three modes based on context:
- **Cleanup Mode**: Branch was merged → switch to main, pull, delete branch
- **Rebase Mode**: Branch not merged → rebase onto main
- **Update Mode**: Already on main → just pull latest

## Benefits

1. **Zero Friction Workflow**:
   ```bash
   /hansolo:ship  # Does EVERYTHING: launch → PR → monitor → sync
   # User is back on clean main, ready for next feature
   ```

2. **Flexibility Preserved**:
   - Power users can still manually `/hansolo:launch` and `/hansolo:sync`
   - Beginners get the complete workflow with one command
   - Ship handles all the orchestration intelligently

3. **Natural Command Hierarchy**:
   - `/ship` = Complete workflow (may invoke launch and sync)
   - `/launch` = Just create branch (can be standalone)
   - `/sync` = Just synchronize (can be standalone)

## Implementation Plan

### Phase 1: Create Monitoring Script
**File**: `.claude/scripts/monitor-pr-merge.sh`
```bash
#!/bin/bash
# Poll PR status using gh pr view
# Support configurable timeout (default 5 minutes)
# Show progress indicators
# Return exit codes: 0=merged, 1=failed, 2=timeout
```

### Phase 2: Enhance Ship Command
**File**: `.claude/commands/hansolo/ship.md`
- Keep existing launch delegation (working well!)
- Add monitoring after PR creation
- Add sync delegation after successful merge
- Complete workflow in one command

### Phase 3: Enhance Sync Command
**File**: `.claude/commands/hansolo/sync.md`
- Detect if called manually or by ship
- Add cleanup mode for merged branches
- Keep rebase mode for unmerged branches
- Make it idempotent (safe to call multiple times)

### Phase 4: Update Gold Squadron
**File**: `.claude/agents/hansolo/gold-squadron.md`
- Add branch state detection
- Support cleanup operations
- Return appropriate JSON responses for each mode

### Phase 5: Update Red Squadron
**File**: `.claude/agents/hansolo/red-squadron.md`
- Remove references to ship command handling monitoring
- Focus solely on PR creation and auto-merge enablement
- Update success metrics to reflect new scope

## Files to Create/Modify
1. CREATE: `.claude/scripts/monitor-pr-merge.sh` - PR monitoring script
2. UPDATE: `.claude/commands/hansolo/ship.md` - Add monitoring and sync orchestration
3. UPDATE: `.claude/commands/hansolo/sync.md` - Add cleanup mode
4. UPDATE: `.claude/agents/hansolo/gold-squadron.md` - Add cleanup support
5. UPDATE: `.claude/agents/hansolo/red-squadron.md` - Clarify scope

## Example User Experience

### Before Enhancement
```bash
/hansolo:ship              # Creates PR, exits
# User manually checks GitHub for merge
# User manually switches to main
# User manually pulls latest
# User manually deletes branch
```

### After Enhancement
```bash
/hansolo:ship              # Creates PR, waits, merges, syncs
# "✓ PR #123 merged and synced! You're on main."
/hansolo:ship              # Ready for next feature immediately
```

## Success Metrics
- Ship command completes entire workflow
- User ends on clean, updated main branch
- No manual GitHub checking required
- No manual branch cleanup needed
- Next feature can start immediately

## Edge Cases to Handle
- PR merge timeout (offer manual merge option)
- CI failures (provide clear next steps)
- Merge conflicts (delegate to Rogue Squadron)
- Network interruptions (graceful recovery)
- User cancellation (Ctrl+C handling)

## JSON Mode Communication
When commands call each other with JSON_MODE=true:
- Launch returns branch creation status
- Sync returns cleanup/rebase status
- Ship can parse and relay progress to user

## Timeline
Implementation should take approximately 30-45 minutes:
- 10 min: Create monitor script
- 10 min: Update ship command
- 10 min: Update sync command
- 10 min: Update squadron agents
- 5 min: Testing and verification

## Future Enhancements
- Progress bars during monitoring
- Estimated time remaining
- Auto-retry on transient failures
- Batch shipping multiple PRs
- Integration with CI/CD status