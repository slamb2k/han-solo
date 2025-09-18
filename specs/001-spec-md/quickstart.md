# han-solo Quickstart Guide

**Version**: 1.0.0
**Date**: 2025-09-18

## Prerequisites

Before starting, ensure you have:
- Claude Code CLI installed and configured
- Git installed (version 2.30+)
- GitHub CLI (gh) installed and authenticated
- jq installed for JSON parsing
- A GitHub repository with admin permissions

## Installation

### Step 1: Initialize han-solo in Your Project

```bash
# Navigate to your project directory
cd your-project

# Run the initialization command
/hansolo:init
```

This will:
- Create `.gitignore`, `.gitconfig`, and `.gitmessage` files
- Set up `.github/pull_request_template.md`
- Configure CLAUDE.md with natural language triggers
- Set up GitHub branch protection rules

**Verification**: Check that all configuration files were created:
```bash
ls -la .gitignore .gitconfig .gitmessage
ls -la .github/pull_request_template.md
ls -la CLAUDE.md
```

### Step 2: Verify Branch Protection

```bash
# Check that branch protection is configured
gh api repos/:owner/:repo/branches/main/protection
```

You should see rules preventing direct pushes to main.

## Basic Workflow

### Starting a New Feature

```bash
# Method 1: Using slash command
/hansolo:launch user-authentication

# Method 2: Using natural language
"Start a new feature for user authentication"
```

**What happens**:
1. Checks if you're on main or a shipped branch
2. Syncs main with remote
3. Creates `feature/user-authentication` branch
4. Switches to the new branch

**Verification**:
```bash
git branch --show-current
# Should show: feature/user-authentication
```

### Making Changes and Committing

```bash
# Make your code changes
# Then commit with quality checks
/hansolo:commit

# Or use natural language
"I'm ready to commit my changes"
```

**What happens**:
1. Runs linters and formatters (auto-detected)
2. Blocks commit if quality checks fail
3. Creates atomic commit with generated message
4. Squashes any checkpoint commits

**Verification**:
```bash
git log --oneline -1
# Should show single, well-formatted commit
```

### Syncing with Main

```bash
# Keep your feature branch updated
/hansolo:sync
```

**What happens**:
1. Fetches latest from origin
2. Rebases your branch onto main
3. Guides through any conflicts

### Creating a Pull Request

```bash
# Ship your feature
/hansolo:ship

# Or use natural language
"Create the PR"
```

**What happens**:
1. Generates PR description from changes
2. Links to related issues
3. Creates PR on GitHub
4. Shows CI/CD status

**Verification**:
```bash
gh pr view
# Should display your new PR
```

## Advanced Features

### Setting Up CI/CD

```bash
/hansolo:ci-setup
```

This will:
1. Detect your project type
2. Generate GitHub Actions workflow
3. Help configure deployment secrets

### Switching Interaction Modes

```bash
# For detailed explanations (learning mode)
/output-style hansolo-tutor

# For concise responses (default)
/output-style hansolo-strict
```

### Viewing Status

The status line shows:
- Current branch
- PR status
- CI checks
- Context usage
- Warnings (e.g., "On main, use /hansolo:launch")

## Testing the Complete Workflow

Here's a complete end-to-end test:

```bash
# 1. Initialize (if not done)
/hansolo:init

# 2. Create a test feature
/hansolo:launch test-feature

# 3. Create a test file
echo "test content" > test.txt

# 4. Commit changes
/hansolo:commit

# 5. Create PR
/hansolo:ship

# 6. Verify PR exists
gh pr list

# 7. Clean up (after PR merge)
git switch main
git pull
git branch -d feature/test-feature
```

## Troubleshooting

### Commit Blocked by Linting

**Problem**: "Linting failed. Commit blocked."

**Solution**:
1. Check the linting errors in the output
2. Fix the issues
3. Re-run `/hansolo:commit`

### Rebase Conflicts

**Problem**: Conflicts during `/hansolo:sync`

**Solution**:
1. The tool will show conflict locations
2. Choose resolution option:
   - Keep your changes
   - Accept remote changes
   - Provide manual resolution
3. Continue with the rebase

### Cannot Push to Main

**Problem**: "Direct push to main branch forbidden"

**Solution**:
1. This is intentional! Use `/hansolo:ship` instead
2. Create a PR for code review
3. Merge via GitHub UI

### PR Checks Failing

**Problem**: Status line shows "🔥 PR #42 Checks Failed!"

**Solution**:
1. View detailed failure: `gh pr checks`
2. Fix the issues locally
3. Push fixes to update PR

## Command Reference

| Command | Description | Example |
|---------|-------------|---------|
| `/hansolo:init` | Initialize repository | `/hansolo:init` |
| `/hansolo:launch <name>` | Create feature branch | `/hansolo:launch user-auth` |
| `/hansolo:commit` | Commit with checks | `/hansolo:commit` |
| `/hansolo:sync` | Sync with main | `/hansolo:sync` |
| `/hansolo:ship` | Create pull request | `/hansolo:ship` |
| `/hansolo:ci-setup` | Setup CI/CD | `/hansolo:ci-setup` |

## Natural Language Triggers

Instead of commands, you can say:
- "Start a new feature called authentication"
- "I'm ready to commit"
- "Sync my branch with main"
- "Create the pull request"
- "Set up continuous integration"

## Best Practices

1. **Always work on feature branches** - Never commit directly to main
2. **Sync frequently** - Run `/hansolo:sync` daily to avoid conflicts
3. **Small, focused PRs** - Ship features incrementally
4. **Use descriptive branch names** - Makes PR tracking easier
5. **Review status line warnings** - Catch issues early

## Getting Help

- View this guide anytime: `cat specs/001-spec-md/quickstart.md`
- Check command options: `/help hansolo`
- View current status: Check the status line
- Report issues: Create an issue in the han-solo repository

---
*End of Quickstart Guide*