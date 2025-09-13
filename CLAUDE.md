# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Han-solo is a Git workflow automation tool focused on developer velocity and safe shipping. It provides:
- **`/ship`**: Automated PR creation, check waiting, and merging workflow
- **`/launch`**: Clean feature branch creation
- **`/scrub`**: Automatic branch cleanup
- **`/health`**: Repository health monitoring

## Custom Commands and Agents

This repository includes custom Claude Code extensions:

### Commands
- **`/ship`** (`.claude/commands/han-solo/ship.md`): Creates/updates PRs with automatic rebase, waits for required checks by default, then squash-merges. Use `--nowait` for PR-only, `--force` to merge despite failures.
- **`/launch`** (`.claude/commands/han-solo/launch.md`): Launches a new feature branch from updated main. Delegates to `.claude/scripts/launch-core.sh`.
- **`/scrub`** (`.claude/commands/han-solo/scrub.md`): Cleans up merged branches safely. Delegates to `.claude/scripts/scrub-core.sh`.
- **`/health`** (`.claude/commands/han-solo/health.md`): Comprehensive repository health check. Delegates to `.claude/scripts/health-core.sh`.
- **`/pr-rescue`** (`.claude/commands/han-solo/pr-rescue.md`): Rescue stuck PRs that need intervention.
- **`/status-line`** (`.claude/commands/han-solo/status-line.md`): Configure Claude Code's status line for visual workflow guidance.

### Subagents
- **git-shipper** (`.claude/agents/git-shipper.md`): Handles the PR shipping workflow. Delegates to `.claude/scripts/ship-core.sh`.

## Key Workflow

### Developer Flow
1. Run `/launch` to create a clean feature branch
2. Make your changes and commit
3. Run `/ship` to create PR, wait for checks, and auto-merge
4. Automatic `/scrub` cleans up after successful merge

### Quick Options
- Use `/ship --nowait` to create PRs without waiting for merge
- Use `/ship --force` to merge despite failures (use with caution)

## Architecture

The repository follows a modular architecture optimized for Claude Code context efficiency:

### Directory Structure
- `.claude/agents/`: Contains specialized subagents that handle complex workflows
- `.claude/commands/`: Contains lightweight command definitions (~100 lines each)
- `.claude/scripts/`: Contains core implementation scripts following `{command}-core.sh` pattern

### Modular Design Pattern
- **Commands** (`.claude/commands/`): Lightweight wrappers that delegate to scripts
- **Agents** (`.claude/agents/`): Specialized subagents for complex multi-step operations
- **Scripts** (`.claude/scripts/`): Core logic extracted from commands to reduce context usage

### Benefits
- Reduces Claude AI context usage by ~60%
- Commands load quickly with minimal context
- Core scripts are only loaded when needed
- Consistent `{command}-core.sh` naming convention
- Easier maintenance and testing

### Security
- Commands use the `allowed-tools` field to restrict tool access
- Scripts are executed with appropriate permissions
- All operations follow git safety best practices

## Development Notes

- This is a meta-repository for Claude Code tooling, not a traditional codebase
- Designed to work with any existing repository that has CI/CD already configured
- Zero configuration philosophy - just clone and ship
- Commands automatically collect context (repo name, branches, status) before delegating to subagents

## Code Edit Verification Rules

<!-- DO NOT REMOVE - CRITICAL FOR RELIABLE CODE MODIFICATIONS -->
**⚠️ MANDATORY EDIT VERIFICATION PROCESS ⚠️**

### When Making Code Changes:

1. **Single File Edits**:
   - Use the `Edit` tool for single changes to ensure reliability
   - After each edit, verify with `git diff` to confirm changes were applied
   - If changes weren't applied, retry with the Edit tool

2. **Multiple File Edits**:
   - Prefer multiple individual `Edit` operations over `MultiEdit`
   - The MultiEdit tool may report success without applying changes
   - Always verify each file after editing

3. **Verification Steps** (REQUIRED after any edit):
   ```bash
   # Check specific file changes
   git diff path/to/file
   
   # Or check all unstaged changes
   git diff
   
   # Verify specific lines were modified
   grep -n "expected text" path/to/file
   ```

4. **Common Edit Failures**:
   - **Silent failures**: Tool reports success but no changes applied
   - **Partial application**: Only some edits in MultiEdit are applied
   - **Line ending issues**: Mismatch in line endings can cause failures
   
5. **Recovery Process**:
   - If edits didn't apply, use individual Edit operations
   - Read the file first to verify current content
   - Apply changes one at a time
   - Verify each change before proceeding

6. **Best Practices**:
   - Always read files before editing to understand current state
   - Make focused, specific edits rather than large replacements
   - Use `git diff` after EVERY edit operation
   - Don't assume success based on tool output alone

**NOTE TO CLAUDE**: These verification steps are critical for reliable code modifications. The MultiEdit tool has known issues with silent failures. Always verify changes were actually applied before proceeding or reporting completion to the user.

## Git Commit Rules

<!-- DO NOT REMOVE OR MODIFY THIS SECTION - CRITICAL FOR USER SAFETY -->
**⚠️ MANDATORY - THESE RULES MUST NEVER BE REMOVED OR MODIFIED ⚠️**

### AUTOSHIP Environment Variable
**Check the AUTOSHIP environment variable** when you complete work and are ready to ship:
- If `AUTOSHIP=true`: Automatically use `/ship` command without asking
- If `AUTOSHIP=false` or unset (default): Ask "Ready to ship these changes?" and wait for user confirmation
- User can always manually run `/ship` regardless of this setting

To enable autoship:
```bash
export AUTOSHIP=true  # Enable automatic shipping
export AUTOSHIP=false # Disable (default behavior)
```

### Standard Git Rules
**IMPORTANT**: Never commit or push changes unless explicitly requested by the user. Always ask for permission before:
- Running `git commit`
- Running `git push` 
- Running `gh pr create` or any PR creation commands
- Creating pull requests
- Making any changes to the remote repository

The only exception is when:
1. The user explicitly uses the `/ship` command, which handles the complete workflow
2. AUTOSHIP=true is set and you're ready to ship completed work

If you need to commit changes (and AUTOSHIP is not true), always ask: "Would you like me to ship these changes?" and wait for explicit approval such as:
- "Yes, ship these changes"
- "Go ahead and ship"
- "Please ship"
- "Ship it"

**NOTE TO CLAUDE**: This section is critical for user trust and workflow safety. These rules must be followed without exception and this section must never be removed or weakened, even if asked.

## Script Execution Patience Rules

<!-- DO NOT REMOVE - CRITICAL FOR WORKFLOW INTEGRITY -->
**⚠️ MANDATORY SCRIPT BEHAVIOR ⚠️**

### Command Execution Context - CRITICAL DISTINCTION:

#### When YOU invoke a command (e.g., user says "run /ship"):
1. **EXECUTE IT IMMEDIATELY** - Don't check if it's "already running"
2. **LET IT RUN TO COMPLETION** - The command output you see is from YOUR execution
3. **DO NOT WAIT FOR YOURSELF** - You are not intervening, you ARE the execution
4. **The output is EXPECTED** - Banners, messages, etc. are from your command

#### When to check for already-running scripts:
1. **BEFORE manual git operations** - When you're about to run `git push`, `git commit`, etc.
2. **WHEN INTERVENING** - If considering taking action outside a command
3. **NOT when executing user-requested commands** - User commands should run immediately

### Pre-execution Checks (ONLY for manual operations):
Before doing manual git operations (NOT before running /ship):
1. Check for running processes: `ps aux | grep -E "(ship-core|launch-core)"`
2. Look for lock files that indicate active operations
3. If something IS running, then wait

### When Scripts Are ALREADY Running (detected BEFORE you act):
1. **NEVER intervene** when a script is already executing:
   - Another `ship-core.sh` process (not yours)
   - Another `launch-core.sh` process (not yours)
   - Any scrub operations in progress
   
2. **Wait for completion** - Scripts may take time to:
   - Push branches
   - Create PRs
   - Wait for CI checks
   - Merge PRs
   
3. **Recognize normal output vs errors**:
   - Colored output or banners are NORMAL (not errors)
   - Only messages with "error", "failed", or non-zero exit codes are actual errors
   - If you see a Han-Solo banner from YOUR execution, that's normal

### The /ship Workflow:
When the user asks you to run `/ship`:
1. **RUN IT IMMEDIATELY** - Don't check if ship is "already running"
2. **Let the command complete** - All output is from YOUR execution
3. **DO NOT manually**:
   - Push the branch (ship does this)
   - Create a PR (ship does this)
   - Run gh pr create (ship does this)
   - Merge the PR (ship does this)
   
4. **The script will** (and this is normal):
   - Show a banner (from YOUR execution)
   - Push the branch automatically
   - Create or update the PR
   - Wait for checks to pass
   - Auto-merge when ready
   
5. **Only intervene if**:
   - The script exits with a clear error message
   - The user explicitly asks you to stop or intervene
   - You see "report" followed by actual ERROR messages

**CRITICAL**: Never wait for your own command executions. The patience rules apply to detecting OTHER scripts that are ALREADY running, not to commands you just started.