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