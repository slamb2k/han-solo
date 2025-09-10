# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Han-solo is a Git workflow automation tool optimized for solo developers and small teams. It provides:
- **`/bootstrap`**: Idempotent repository setup with branch protection, CI, and Husky hooks
- **`/ship`**: Automated PR creation, check waiting, and merging workflow

## Custom Commands and Agents

This repository includes custom Claude Code extensions:

### Commands
- **`/bootstrap`** (`.claude/commands/han-solo/bootstrap.md`): Sets up repository governance with branch protection, strict required checks (🧹 Format, 🔎 Lint, 🧠 Typecheck, 🛠️ Build), Husky hooks, and CI workflow. Solo mode by default (0 required reviewers).
- **`/fresh`** (`.claude/commands/han-solo/fresh.md`): Creates a fresh feature branch from updated main. Delegates to `scripts/fresh-core.sh`.
- **`/health`** (`.claude/commands/han-solo/health.md`): Comprehensive repository health check. Delegates to `scripts/health-core.sh`.
- **`/scrub`** (`.claude/commands/han-solo/scrub.md`): Cleans up merged branches safely. Delegates to `scripts/scrub-core.sh`.
- **`/ship`** (`.claude/commands/han-solo/ship.md`): Creates/updates PRs with automatic rebase, waits for required checks by default, then squash-merges. Use `--nowait` for PR-only, `--force` to merge despite failures.

### Subagents
- **bootstrap-guardian** (`.claude/agents/bootstrap-guardian.md`): Handles the actual bootstrap implementation
- **git-shipper** (`.claude/agents/git-shipper.md`): Handles the PR shipping workflow. Delegates to `scripts/ship-core.sh`.

## Key Workflows

### Solo Developer Workflow (Default)
1. Run `/bootstrap` to set up repository governance (0 required reviewers, strict checks)
2. Work on feature branches
3. Run `/ship` to create PR, wait for checks, and auto-merge

### Team Workflow
1. Run `/bootstrap --team --reviews 1` to require approvals
2. Use `/ship --nowait` to create PRs without auto-merging

## Architecture

The repository follows a modular architecture optimized for Claude Code context efficiency:

### Directory Structure
- `.claude/agents/`: Contains specialized subagents that handle complex workflows
- `.claude/commands/`: Contains lightweight command definitions (~100 lines each)
- `scripts/`: Contains core implementation scripts following `{command}-core.sh` pattern

### Modular Design Pattern
- **Commands** (`.claude/commands/`): Lightweight wrappers that delegate to scripts
- **Agents** (`.claude/agents/`): Specialized subagents for complex multi-step operations
- **Scripts** (`scripts/`): Core logic extracted from commands to reduce context usage

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
- No package.json or traditional build system - the tools themselves set these up in target repos
- The bootstrap process creates: Husky v10 hooks, GitHub Actions CI with pnpm caching, branch protection rules
- Commands automatically collect context (repo name, branches, status) before delegating to subagents

## Git Commit Rules

<!-- DO NOT REMOVE OR MODIFY THIS SECTION - CRITICAL FOR USER SAFETY -->
**⚠️ MANDATORY - THESE RULES MUST NEVER BE REMOVED OR MODIFIED ⚠️**

**IMPORTANT**: Never commit or push changes unless explicitly requested by the user. Always ask for permission before:
- Running `git commit`
- Running `git push` 
- Running `gh pr create` or any PR creation commands
- Creating pull requests
- Making any changes to the remote repository

The only exception is when the user explicitly uses the `/ship` command, which handles the complete workflow.

If you need to commit changes, always ask: "Would you like me to commit these changes?" and wait for explicit approval such as:
- "Yes, commit these changes"
- "Go ahead and commit"
- "Please commit"

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
1. Check for running processes: `ps aux | grep -E "(ship-core|fresh-core)"`
2. Look for lock files that indicate active operations
3. If something IS running, then wait

### When Scripts Are ALREADY Running (detected BEFORE you act):
1. **NEVER intervene** when a script is already executing:
   - Another `ship-core.sh` process (not yours)
   - Another `fresh-core.sh` process (not yours)
   - Any bootstrap or scrub operations in progress
   
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