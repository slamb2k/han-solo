# Han-Solo Status Lines

Status lines provide real-time information about your git repository state directly in your terminal prompt. They help prevent common workflow issues and keep you informed about your current work context.

## Available Status Lines

### 🛡️ git-safety.sh
**Purpose:** Prevents merge conflicts and accidental commits to main

**Shows:**
- Current directory and branch name
- Warning when on main/master branch
- Uncommitted changes count
- Sync status (ahead/behind/diverged)
- Open PR status (mergeable/conflicting)
- Branch age warning (>3 days)
- Feature branch indicator (🌟 for feat/* or feature/* branches)

**Example Output:**
```
✅ han-solo/🌟feat/new-login (3 uncommitted) ↑2 PR#42→
```

### 💼 work-session.sh
**Purpose:** Tracks your current coding session productivity

**Shows:**
- Current directory and branch
- Session duration (time since session start)
- Number of files changed
- Lines added/removed in session
- Feature branch indicator

**Example Output:**
```
💼 han-solo/🌟feat/api 2h15m 📝5 +120/-45
```

### 🎯 pr-health.sh
**Purpose:** Monitors PR status and CI check health

**Shows:**
- Current directory and PR number
- CI check status (passing/failing/pending)
- Review approval status
- Merge readiness
- Draft status
- Conflict warnings

**Example Output:**
```
🎯 han-solo/PR#42 ✅4/4 ✅+2 Ready
```

### 📊 branch-metrics.sh
**Purpose:** Provides branch statistics and size metrics

**Shows:**
- Current directory and branch
- Commits ahead of main
- Files changed
- Total lines added/removed
- Branch age
- Size warnings for large branches

**Example Output:**
```
🌿 han-solo/feat/refactor 💾12 📄8 📈+450/-230 📅3d
```

## Installation

### Using the Interactive Installer

The easiest way to install status lines is through the interactive installer:

```bash
./scripts/install-interactive.sh
```

Select "Status Line (git-safety)" from the components menu to install all status lines.

### Manual Installation

1. Copy status line scripts to your Claude configuration:
```bash
cp .claude/status_lines/*.sh ~/.claude/status_lines/
chmod +x ~/.claude/status_lines/*.sh
```

2. Configure in Claude settings (`~/.claude/settings.toml`):
```toml
[status_line]
command = "~/.claude/status_lines/git-safety.sh"
refresh_interval = 5
```

## Configuration

Each status line can be configured with different refresh intervals:

- **git-safety.sh**: 5 seconds (fast updates for safety)
- **work-session.sh**: 10 seconds (moderate updates)
- **pr-health.sh**: 15 seconds (CI checks don't change rapidly)
- **branch-metrics.sh**: 30 seconds (metrics are stable)

## Switching Status Lines

To switch between status lines, update your Claude settings:

```toml
# For work session tracking
[status_line]
command = "~/.claude/status_lines/work-session.sh"
refresh_interval = 10

# For PR monitoring
[status_line]
command = "~/.claude/status_lines/pr-health.sh"
refresh_interval = 15

# For branch metrics
[status_line]
command = "~/.claude/status_lines/branch-metrics.sh"
refresh_interval = 30
```

## Features

### Current Directory Display
All status lines show the current working directory basename, making it easy to know which project you're in.

### Feature Branch Highlighting
Branches created with `/fresh` (feat/* or feature/*) are highlighted with a 🌟 star emoji.

### Smart Truncation
Long branch names are automatically truncated to fit terminal width while preserving readability.

### Non-Git Repository Handling
Status lines gracefully handle non-git directories with appropriate messages.

## Customization

You can modify any status line script to suit your needs:

1. Edit the script in `.claude/status_lines/`
2. Adjust colors, emojis, or information displayed
3. Change truncation lengths or warning thresholds
4. Add custom logic for your workflow

## Troubleshooting

### Status line not updating
- Check that the script is executable: `chmod +x ~/.claude/status_lines/*.sh`
- Verify the path in your settings file
- Test the script manually: `~/.claude/status_lines/git-safety.sh`

### GitHub CLI errors (pr-health.sh)
- Ensure GitHub CLI is installed: `gh --version`
- Authenticate with GitHub: `gh auth login`

### Session duration resets (work-session.sh)
- The session file is stored in `/tmp/` and may be cleared on reboot
- This is intentional to start fresh sessions daily

## Best Practices

1. **Use git-safety.sh** for general development to avoid conflicts
2. **Switch to pr-health.sh** when working on PR feedback
3. **Use work-session.sh** for time tracking and productivity
4. **Check branch-metrics.sh** before shipping to ensure reasonable PR size

## Contributing

To add a new status line:

1. Create a new script in `.claude/status_lines/`
2. Follow the existing pattern (show directory, handle non-git repos)
3. Keep output concise (terminal width matters)
4. Document in this README
5. Add to the installer component list