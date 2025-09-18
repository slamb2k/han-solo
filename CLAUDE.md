# han-solo Project Context

## Overview
han-solo is an agentic orchestrator for modern software delivery built as a Claude Code extension. It enforces opinionated best practices, automates Git workflows, and maintains code quality through deterministic hooks.

## Architecture
- **Commands**: User-facing slash commands under /hansolo: namespace
- **Subagents**: Isolated execution contexts for complex operations (Squadron naming)
- **Hooks**: Deterministic workflow enforcement (pre-commit, push protection)
- **Status Line**: Real-time project awareness and warnings

## Technology Stack
- **Languages**: Bash/Shell Scripts, Markdown
- **Dependencies**: Claude Code CLI, Git, GitHub CLI (gh), jq
- **Platform**: macOS/Linux with Claude Code
- **Storage**: File-based configuration in .claude/ directory

## Key Features
- Linear Git history enforcement
- Automated quality checks before commits
- Pull request generation with AI descriptions
- CI/CD pipeline configuration
- Checkpoint commits with atomic squashing
- Interactive conflict resolution

## han-solo Workflow Commands

### Initialization
When the user says "initialize han-solo" or "set up the project", execute `/hansolo:init`

### Feature Development
- When the user says "start a new feature" or "create a branch", execute `/hansolo:launch`. Use subsequent words as the feature name.
- When the user says "I'm ready to commit" or "commit my work", execute `/hansolo:commit`
- When the user says "sync with main" or "update my branch", execute `/hansolo:sync`

### Deployment
- When the user says "create the PR" or "open a pull request", execute `/hansolo:ship`
- When the user says "set up CI" or "configure deployment", execute `/hansolo:ci-setup`

## Interaction Rules

### Permission Requirements
**Never commit and push changes unless explicitly asked by the user.**

Always ask for permission before (except when /hansolo:ship has been called):
- Running git commit
- Running git push
- Running gh pr create or any PR creation commands
- Creating pull requests

### Interactive Prompts
**⚠️ MANDATORY INTERACTION BEHAVIOR ⚠️**

When executing commands that contain:
- read -r statements
- (USER INTERACTION REQUIRED) markers
- Options presented as [1], [2], [3] etc.
- Interactive prompts for user decisions

**YOU MUST**:
1. **STOP IMMEDIATELY** at interaction points
2. **PRESENT THE OPTIONS** clearly to the user
3. **EXPLICITLY ASK** for their choice
4. **WAIT FOR USER RESPONSE** before continuing
5. **NEVER ASSUME DEFAULTS** for interactive prompts

### Special Cases
1. **Merged PR Detection in /ship**: Always requires user choice between fresh-start, skip-rebase, or auto-resolve
2. **Branch Deletion Confirmations**: Requires user confirmation for branches with unmerged commits
3. **Launch Conflicts**: Requires user decision on handling stash conflicts

## Recent Changes (2025-09-18)
- Initial han-solo architecture specification created
- Command/Subagent/Hook triad established
- Squadron naming convention adopted for subagents
- Deterministic enforcement patterns defined

## Testing Guidelines
- Hook scripts must exit with code 0 (success), 1 (warning), or 2 (block)
- Commands must validate YAML frontmatter
- Subagents must handle error states gracefully
- Status line must update within 100ms

## Project Structure
```
.claude/
├── commands/hansolo/     # Slash commands
├── agents/hansolo/        # Subagents (Squadrons)
├── hooks/                 # Hook scripts
├── settings.json          # Configuration
└── output-styles/         # Output modes

.github/
├── workflows/             # CI/CD pipelines
└── pull_request_template.md

specs/001-spec-md/         # Feature documentation
├── spec.md                # Specification
├── plan.md                # Implementation plan
├── research.md            # Technical decisions
├── data-model.md          # Entity definitions
├── contracts/             # API contracts
└── quickstart.md          # User guide
```

## Development Principles
1. **Determinism**: Critical workflow rules enforced by hooks, not prompts
2. **Linear History**: Rebase-only updates, squash merges
3. **User Control**: Explicit permission for destructive operations
4. **Isolation**: Complex logic in subagents, not main context
5. **Awareness**: Status line for continuous feedback

---
*This file is automatically loaded at session start to provide han-solo context to Claude Code.*