![han-solo logo](assets/logo.png)

# 🚀 han-solo

> **"Fly solo, fly fast, fly safe"** - A governed-but-fast Git workflow system for solo developers and small teams using Claude Code.

Han Solo provides two powerful commands that establish best practices while optimizing for developer velocity. Perfect for solo developers who want professional-grade governance without the overhead.

## 🎯 Philosophy

- **Solo-first, team-ready**: Zero friction for solo devs, easily scales to teams
- **Governed but fast**: Quality gates without bureaucracy
- **Convention over configuration**: Smart defaults that just work
- **Fail safely**: Use `--force-with-lease`, never raw `--force`
- **Clear feedback**: Comprehensive INFO/WARN/ERR reporting

## 📦 Installation

Place these files in your Claude Code project:

```
.claude/
├── agents/
│   ├── bootstrap-guardian.md    # Bootstrap sub-agent
│   └── git-shipper.md           # Shipping sub-agent
└── commands/
    └── git/
        ├── bootstrap.md         # /bootstrap command
        └── ship.md              # /ship command
```

## 🚀 Quick Start

```bash
# 1. Bootstrap your repo (one-time setup)
/bootstrap

# 2. Make your changes, commit with conventional commits
git add .
git commit -m "feat: add amazing new feature"

# 3. Ship it!
/ship

# That's it! Your code is reviewed, tested, and merged.
```

## 📚 Commands

### `/bootstrap` - Repository Setup

Sets up professional-grade repository governance optimized for solo developers.

#### What it does:
- ✅ **Branch protection** with strict required checks
- ✅ **Required status checks**: 🧹 Format, 🔎 Lint, 🧠 Typecheck, 🛠️ Build
- ✅ **Auto-merge** enabled (merges when checks pass)
- ✅ **Auto-delete** branches after merge
- ✅ **Husky hooks** for pre-commit and pre-push
- ✅ **CI workflow** with pnpm caching and emoji job names

#### Usage:
```bash
# Solo mode (default - no review required)
/bootstrap

# Team mode with 1 reviewer required
/bootstrap --team

# Team mode with 2 reviewers on develop branch
/bootstrap --branch develop --team --reviews 2

# Only install pre-push hooks
/bootstrap --hook pre-push
```

#### Options:
- `--branch <name>`: Branch to protect (default: auto-detected)
- `--team`: Require human reviews (default: solo mode)
- `--reviews <N>`: Number of required reviewers (default: 0 solo, 1 team)
- `--hook <both|pre-commit|pre-push>`: Which hooks to install (default: both)

### `/ship` - Ship Your Code

The Swiss Army knife for shipping code. Handles everything from commit to merge.

#### What it does:
- 🔄 **Rebases** onto latest default branch
- 🧪 **Runs checks** (Nx affected or standard scripts)
- 📝 **Creates PR** with auto-generated title and body
- ⏳ **Waits for checks** to pass (by default)
- ✅ **Auto-merges** when green
- 🧹 **Cleans up** branches automatically

#### Usage:
```bash
# Standard ship (wait for checks, then merge)
/ship

# Create PR without waiting for merge
/ship --nowait

# Ship with custom title
/ship --title "Add authentication system"

# Force merge despite check failures (use carefully!)
/ship --force

# Create draft PR for early feedback
/ship --draft --nowait
```

#### Options:
- `--nowait`: Create PR only, don't wait for merge
- `--force`: Merge even if checks fail (requires explicit intent)
- `--title "<text>"`: Custom PR title
- `--branch-name <name>`: Custom branch name (when creating new)
- `--body "<text>"`: Custom PR body
- `--draft`: Create as draft PR

## 🔄 Typical Workflow

### Solo Developer Flow
```bash
# One-time setup
/bootstrap

# Daily development
git switch -c feat/new-feature
# ... make changes ...
git add .
git commit -m "feat: implement new feature"
git commit -m "test: add test coverage"
git commit -m "docs: update README"

# Ship it (waits for checks, auto-merges)
/ship

# You're back on main with everything merged!
```

### Quick Iteration Flow
```bash
# Make changes on main
# ... edit files ...
git add .
git commit -m "fix: resolve critical bug"

# Ship directly from main (creates branch automatically)
/ship --title "Fix critical bug in payment system"
```

### Team Collaboration Flow
```bash
# Switch to team mode
/bootstrap --team --reviews 2

# Create PR for review
/ship --nowait

# After approval, checks will auto-merge
```

## 🎯 Conventional Commits

Han Solo works best with [Conventional Commits](https://www.conventionalcommits.org/):

```bash
feat: add new feature
fix: resolve bug
docs: update documentation
test: add tests
refactor: restructure code
perf: improve performance
build: update build config
ci: update CI/CD
chore: routine tasks
```

These automatically generate meaningful PR descriptions!

## 🛡️ Safety Features

### Protected by Default
- ✅ Strict status checks (base must be up-to-date)
- ✅ Required checks must pass before merge
- ✅ Linear history enforced
- ✅ Force pushes blocked on protected branches

### Safe Operations
- Uses `--force-with-lease` (never raw `--force`)
- Rebases for clean history
- Squash merges to keep main clean
- Automatic branch cleanup

### Clear Reporting
Every operation ends with a comprehensive report:
```
===== 🚢 git-shipper report =====
INFO (8 items):
  • Repository: owner/repo
  • Created branch: feat/new-feature
  • Rebased onto origin/main
  • All checks passed
  • PR created successfully
  • PR merged successfully
  • Deleted local branch
  • Ship complete!
==================================
✨ Ship completed successfully!
```

## 🔧 Troubleshooting

### Common Issues

#### Rebase Conflicts
```bash
# If rebase fails during /ship
git rebase --abort  # Cancel the rebase
# Fix conflicts manually, then:
git rebase --continue
/ship  # Try again
```

#### Check Failures
```bash
# View which checks failed
gh pr checks

# Fix the issues, push, and checks re-run automatically
git push

# Or force merge if you're certain (use sparingly!)
/ship --force
```

#### Authentication Issues
```bash
# Ensure GitHub CLI is authenticated
gh auth login
```

### Manual Recovery

If something goes wrong, you can always fall back to manual operations:

```bash
# Check PR status
gh pr view --web

# Manually merge if needed
gh pr merge --squash --delete-branch

# Return to main
git switch main
git pull
```

## 🎨 Customization

### CI Job Names
The emoji job names in CI must match exactly:
- `🧹 Format`
- `🔎 Lint`
- `🧠 Typecheck`
- `🛠️ Build`

### Package Scripts
Ensure your `package.json` has these scripts:
```json
{
  "scripts": {
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "build": "vite build"
  }
}
```

### Nx Monorepos
Han Solo automatically detects and uses Nx for optimized checks:
- Runs only affected projects
- Parallelizes execution
- Caches results

## 📋 Requirements

- **Git** repository
- **GitHub** repository (public or private)
- **GitHub CLI** (`gh`) authenticated
- **Node.js** and **pnpm** (recommended)
- **Claude Code** with agents enabled

## 🚁 Advanced Usage

### Environment Variables
```bash
# Use environment variables instead of flags
NOWAIT=true /ship
FORCE=true /ship
TEAM=true REVIEWS=2 /bootstrap
```

### Debugging
```bash
# Enable debug output
DEBUG=true /ship
```

### Custom Contexts
Both commands auto-collect context about your repository. This is shown in the Claude Code interface and helps the agents make better decisions.

## 📖 Best Practices

1. **Commit Often**: Smaller commits make better PR descriptions
2. **Use Conventional Commits**: Enables automatic PR generation
3. **Ship Small**: Smaller PRs = fewer conflicts, faster reviews
4. **Trust the Process**: Let checks run, don't abuse `--force`
5. **Stay Current**: Regular rebasing prevents conflicts

## 🤝 Contributing

Han Solo is designed to be extended. Feel free to:
- Add new required checks
- Customize commit message parsing
- Extend the agent capabilities
- Add new commands

## 📝 License

Use freely in your Claude Code projects. Solo-first, always.

---

**Remember**: With great velocity comes great responsibility. Ship fast, but ship safe! 🚀