# han-solo User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Core Workflows](#core-workflows)
4. [Commands Reference](#commands-reference)
5. [Natural Language Usage](#natural-language-usage)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

## Introduction

han-solo is an agentic orchestrator for modern software delivery, built as a Claude Code extension. It automates Git workflows, enforces code quality standards, and maintains linear project history through opinionated best practices.

### Key Benefits
- **Automated Quality Checks**: Never commit broken code again
- **Linear History**: Clean, readable Git logs
- **Smart PR Generation**: AI-powered pull request descriptions
- **CI/CD Integration**: Automatic pipeline configuration
- **Conflict Resolution**: Guided merge conflict handling

## Getting Started

### Prerequisites
- Claude Code CLI (v1.0.117+)
- Git (v2.36+)
- GitHub CLI (`gh`) authenticated
- jq installed for JSON parsing

### Initial Setup

1. Navigate to your project:
```bash
cd your-project
```

2. Initialize han-solo:
```
/hansolo:init
```

This creates:
- `.gitignore` with common patterns
- `.gitconfig` enforcing linear history
- `.gitmessage` commit template
- `.github/pull_request_template.md`
- `CLAUDE.md` with project context
- Branch protection rules on GitHub

### Verify Installation

Check that configuration files exist:
```bash
ls -la .gitignore .gitconfig .gitmessage CLAUDE.md
ls -la .github/pull_request_template.md
```

## Core Workflows

### 1. Starting a New Feature

```
/hansolo:launch feature-name
```

Or use natural language:
- "Start a new feature called user-auth"
- "Create a branch for payment-system"
- "Begin working on dark-mode"

**What happens:**
1. Ensures you're on main branch
2. Syncs with remote main
3. Creates `feature/feature-name` branch
4. Switches to new branch

### 2. Committing Changes

After making changes:
```
/hansolo:commit
```

Or say:
- "I'm ready to commit"
- "Save my changes"
- "Commit my work"

**What happens:**
1. Runs linters (auto-detected)
2. Runs formatters if configured
3. Blocks commit if checks fail
4. Creates atomic commit
5. Squashes any checkpoint commits

### 3. Syncing with Main

Keep your branch updated:
```
/hansolo:sync
```

Or say:
- "Sync with main"
- "Update my branch"
- "Get latest from main"

**What happens:**
1. Fetches latest from origin
2. Rebases your branch onto main
3. Guides through any conflicts
4. Maintains linear history

### 4. Creating Pull Requests

When ready for review:
```
/hansolo:ship
```

Or say:
- "Create the PR"
- "Ship this feature"
- "Submit for review"

**What happens:**
1. Generates PR description from changes
2. Creates PR on GitHub
3. Links related issues
4. Shows CI/CD status

### 5. Setting Up CI/CD

Configure automated testing:
```
/hansolo:ci-setup
```

Or say:
- "Set up CI"
- "Configure GitHub Actions"
- "Setup automated tests"

**What happens:**
1. Detects project type
2. Generates appropriate workflow
3. Configures deployment if applicable
4. Sets up secrets guidance

## Commands Reference

### `/hansolo:init`
Initialize repository with han-solo configuration.

**Usage**: `/hansolo:init`

**Creates**:
- Git configuration files
- PR templates
- Branch protection rules

### `/hansolo:launch`
Create a new feature branch.

**Usage**: `/hansolo:launch <feature-name>`

**Example**: `/hansolo:launch user-authentication`

**Options**:
- Feature name (required)

### `/hansolo:commit`
Commit changes with quality checks.

**Usage**: `/hansolo:commit`

**Performs**:
- Linting
- Formatting
- Checkpoint squashing
- Commit message generation

### `/hansolo:sync`
Sync feature branch with main.

**Usage**: `/hansolo:sync`

**Actions**:
- Fetch latest
- Rebase on main
- Conflict resolution

### `/hansolo:ship`
Create pull request for current feature.

**Usage**: `/hansolo:ship`

**Generates**:
- PR title
- PR description
- Links to issues

### `/hansolo:ci-setup`
Configure CI/CD pipeline.

**Usage**: `/hansolo:ci-setup`

**Supports**:
- Node.js
- Python
- Go
- Java
- Rust
- Ruby

## Natural Language Usage

han-solo understands conversational commands:

### Starting Features
- "Let's work on authentication"
- "I need to create a login system"
- "Time to build the payment feature"

### Committing
- "Save my work"
- "I'm done with these changes"
- "Let's commit this"

### Syncing
- "Catch up with the team"
- "What's new in main?"
- "Update my workspace"

### Shipping
- "This is ready for review"
- "Let's get this merged"
- "Time to ship"

## Troubleshooting

### Common Issues

#### 1. Commit Blocked by Linting

**Problem**: "Linting failed. Commit blocked."

**Solution**:
1. Review the linting errors shown
2. Fix the issues in your code
3. Run `/hansolo:commit` again

#### 2. Rebase Conflicts

**Problem**: Conflicts during `/hansolo:sync`

**Solution**:
1. han-solo will show conflict locations
2. Choose resolution option:
   - [1] Keep your changes
   - [2] Accept remote changes
   - [3] Manual merge
3. Continue with rebase

#### 3. Cannot Push to Main

**Problem**: "Direct push to main forbidden"

**Solution**:
This is intentional! Always use `/hansolo:ship` to create a PR instead.

#### 4. PR Checks Failing

**Problem**: CI checks failing on PR

**Solution**:
1. View failures: `gh pr checks`
2. Fix issues locally
3. Push fixes to update PR

#### 5. GitHub API Rate Limits

**Problem**: "API rate limit exceeded"

**Solution**:
1. Wait for reset (shown in status line)
2. Use GraphQL instead of REST
3. Batch operations when possible

### Getting Help

- View status line for current state
- Check logs: `/tmp/han-solo-performance.log`
- Run tests: `bash tests/integration/test_complete_workflow.sh`

## Best Practices

### 1. Workflow Habits
- **Always work on feature branches**: Never commit to main
- **Sync frequently**: Run `/hansolo:sync` daily
- **Small, focused PRs**: Ship incrementally
- **Descriptive branch names**: Makes tracking easier

### 2. Commit Practices
- **Atomic commits**: One logical change per commit
- **Clear messages**: Follow conventional commits
- **Test before commit**: Ensure tests pass
- **Review before ship**: Self-review your PR

### 3. Collaboration
- **Communicate branch work**: Avoid conflicts
- **Review promptly**: Don't block teammates
- **Update PR descriptions**: Keep them current
- **Resolve feedback quickly**: Keep PRs moving

### 4. Maintenance
- **Clean old branches**: After PR merge
- **Update dependencies**: Keep tools current
- **Monitor performance**: Check hook execution times
- **Review git history**: Ensure it stays clean

### 5. Security
- **Never commit secrets**: Use environment variables
- **Review PR changes**: Check for sensitive data
- **Use branch protection**: Enforce code review
- **Rotate credentials**: Regular security hygiene

## Advanced Features

### Output Styles

Switch interaction modes:

**Verbose mode** (for learning):
```
/output-style hansolo-tutor
```

**Concise mode** (default):
```
/output-style hansolo-strict
```

### Status Line

The status line shows:
- Current branch
- PR status (🟢 passing, 🔴 failing)
- CI check status
- Context usage percentage
- Warnings (e.g., "On main, use /hansolo:launch")

### Checkpoint Commits

han-solo creates temporary checkpoint commits during work sessions:
- Automatically created after file edits
- Squashed into atomic commits when shipping
- Provides granular history during development
- Clean final history for review

### Squadron Agents

Specialized agents handle complex tasks:
- **Red-Squadron**: Project initialization
- **Gold-Squadron**: Git operations
- **Blue-Squadron**: PR generation
- **Green-Squadron**: CI/CD setup
- **Gray-Squadron**: Commit messages
- **Rogue-Squadron**: Conflict resolution

## Integration with Other Tools

### VS Code
- Works alongside VS Code Git integration
- Respects `.vscode/settings.json`
- Compatible with GitLens

### GitHub
- Full GitHub API integration
- Respects CODEOWNERS
- Works with GitHub Actions

### CI/CD Platforms
- GitHub Actions (primary)
- GitLab CI (compatible)
- CircleCI (compatible)
- Jenkins (manual setup)

## Performance Monitoring

Track han-solo performance:

```bash
# View performance stats
.claude/scripts/monitor-performance.sh analyze

# Real-time monitoring
.claude/scripts/monitor-performance.sh monitor

# Check GitHub rate limits
.claude/scripts/check-rate-limits.sh
```

---

For more information, see:
- [Quickstart Guide](../specs/001-spec-md/quickstart.md)
- [Technical Specification](../specs/001-spec-md/spec.md)
- [Troubleshooting Guide](./troubleshooting.md)