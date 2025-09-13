![han-solo logo](assets/logo.png)

# 🚀 Han-Solo

> **"Never tell me the odds!"** - Opinionated Git workflow automation that ships features, not excuses

Han-Solo is your co-pilot for shipping code at lightspeed. Stop fighting Git, start shipping features. Built specifically for Claude Code, it leverages AI memory and hooks to ensure your workflow stays on track, every time.

## 🎯 Why Han-Solo?

**You're here to ship features, not wrestle with Git.** Han-Solo provides an opinionated, battle-tested workflow that eliminates decision fatigue and Git anxiety. 

### The Problem
- 😩 **Git Confusion**: Merge conflicts, orphaned branches, forgotten stashes
- 🤯 **Process Overhead**: Manual PR creation, waiting for checks, remembering to cleanup
- 😱 **Production Breaks**: Code goes to main without proper checks
- 🔄 **Half-Baked States**: Incomplete workflows leaving you in limbo
- 🧹 **Technical Debt**: Orphaned branches, failed deployments, inconsistent practices

### The Solution
Han-Solo implements a **complete, opinionated workflow** that:
- ✅ **Ships or fails completely** - no half-baked states
- 🤖 **Uses Claude Code's memory** - stays on track across sessions
- 🛡️ **Shifts left on quality** - catches issues before they reach main
- 🚀 **Automates everything** - from branch creation to deployment
- 🧹 **Cleans up after itself** - no orphaned branches or forgotten PRs

## ✨ Core Features

### 🎯 Opinionated Workflow
**Stop debating process, start shipping features.** Han-Solo implements a proven workflow:
1. Create feature branch → 2. Make changes → 3. Ship → 4. Auto-merge → 5. Deploy → 6. Cleanup

No decisions needed. Just `/ship` and move on to the next story.

### 🤖 Claude Code Integration
**Leverages Claude's memory and hooks** to ensure consistent workflow:
- Remembers your preferences across sessions
- Uses hooks to enforce safety rules
- Prevents accidental commits to main
- Maintains workflow continuity even after context switches

### 🛡️ Shift-Left Quality Gates
**Catch issues before they reach production:**
- **Husky hooks** run checks before commit/push
- **Required CI checks** must pass before merge
- **Automated testing** on every PR
- **Build validation** ensures deployable code
- **Customizable definition of "working"** - you define the complexity

### 🚢 Complete Shipping Pipeline
**One command ships everything:**
```bash
/ship  # That's it. Really.
```
- Commits all changes
- Creates/updates PR with auto-generated description
- Waits for required checks
- Auto-merges when green
- Triggers deployment
- Cleans up branches
- **Never leaves you hanging** - completes or rolls back cleanly

### 👥 Solo & Team Ready
**Optimized for solo devs, scales to teams:**
- Works with your existing CI/CD setup
- Respects your current branch protection rules
- Adapts to solo or team review requirements automatically

### 📦 Smart Deployment
**Auto-detected deployment targets with GitHub Releases:**
- **GitHub Pages** - Static sites and docs
- **Container Registry** - Docker images to GHCR
- **Release Packages** - Versioned ZIP artifacts
- **Release History** - Every merge creates a traceable release
- Coming soon: Vercel, NPM, AWS, Azure

### 🧹 Automatic Cleanup
**Never wonder "did that code make it to prod?"**
- Runs after every successful ship
- Removes merged branches locally and remotely
- Cleans up squash-merged branches
- Detects orphaned work
- Manual cleanup anytime: `/scrub`

### 📊 Smart Status Line
**Visual workflow guidance in your terminal:**
- **Real-time context tracking** - See how much context remains before compaction
- **Branch warnings** - Red alerts when on main, reminders to use `/launch`
- **PR status** - Shows CI checks, review status, mergeability
- **Work tracking** - Uncommitted changes, sync status, divergence warnings
- **Model awareness** - Displays active Claude model (Opus 4.1, Sonnet 3.5, etc.)
- **Smart hints** - Visual cues guide you through the workflow:
  - ⚠️ **Red on main** - "USE /launch TO START WORK"
  - 🌟 **Feature branches** - Shows you're in the right place
  - ⚡ **Diverged branches** - Warns about potential conflicts
  - 🚫 **Closed PR branches** - Alerts to dead-end work

### ✅ Validation & Safety
**Strong validation ensures complete shipping:**
- Pre-flight checks before operations
- Rollback on failure
- Clear error reporting
- Dry-run mode: `/ship --check`
- Never leaves repository in broken state

## 🚀 Quick Start

### 1. Install Han-Solo

```bash
npx han-solo-installer
```

Interactive installer with:
- Profile selection (Solo, Team, Minimal, Custom)
- Component selection
- Status line configuration

### 2. Ship Your First Feature

```bash
/launch my-feature   # Start clean
# ... make changes ...
/ship               # Ship it!
```

**That's it!** Your code is tested, reviewed, merged, deployed, and cleaned up.

## 🎬 Visual Demo: See It In Action!

### The Smart Status Line - Your Workflow Co-Pilot

<div align="center">

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     🚀 Han-Solo Status Line Demo                         │
└──────────────────────────────────────────────────────────────────────────┘
```

</div>

#### 🔴 Scenario 1: On Main Branch (Warning Mode)
```ansi
📁 my-app | ⚠️ main | ✓ clean | ✓ | 🤖 Opus 4.1 | 🧠 [█░░░░░░░░░] 90% left [USE /launch TO START WORK]
            ^^^^^^^^                                                      ^^^^^^^^^^^^^^^^^^^^^^^^
              RED                                                           FLASHING WARNING
```
**What you see:** Bright red warning that you're on main, with clear instruction to use `/launch`

#### 🟢 Scenario 2: Active Feature Development
```ansi
📁 my-app | 🌟 feat/auth | ●3 +45/-12 | ↑2 | PR#42→ | 🤖 Sonnet 3.5 | 🧠 [███░░░░░░░] 70% left
            ^^^^^^^^^^^^   ^^^^^^^^^^   ^^   ^^^^^^^                      ^^^^^^^^^^^
            YELLOW STAR    3 CHANGES   AHEAD  PR OPEN                    GREEN = SAFE
```
**What you see:** Everything is good! Star shows feature branch, changes tracked, PR in progress

#### 🟡 Scenario 3: Context Running Low
```ansi
📁 my-app | 🌟 feat/big-refactor | ●15 +2048/-512 | ↑8 | 🤖 Opus 4.1 | 🧠 [████████░░] 20% left
                                                                           ^^^^^^^^^^^
                                                                           YELLOW/RED WARNING
```
**What you see:** Context bar turns yellow then red as you approach compaction

#### ⚡ Scenario 4: Diverged Branch (Danger!)
```ansi
📁 my-app | 🌿 old-feature | ●2 | ↕ | 🤖 Haiku 3.5 | 🧠 [████░░░░░░] 60% left
                                  ^^
                              DIVERGED!
```
**What you see:** Divergence indicator warns of potential conflicts

### 📺 Live Terminal Experience

<div align="center">

```
╔═══════════════════════════════════════════════════════════════════════════╗
║  Terminal                                                    □ ○ ×       ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ $ git status                                                              ║
║ On branch feat/awesome-feature                                           ║
║ Changes not staged for commit:                                           ║
║   modified:   src/index.js                                               ║
║                                                                           ║
║ ─────────────────────────────────────────────────────────────────────    ║
║ 📁 my-app | 🌟 feat/awesome-feature | ●1 +23/-5 | ↑1 | 🤖 Opus 4.1 |    ║
║ 🧠 [███████░░░] 65% left                                                 ║
║ ─────────────────────────────────────────────────────────────────────    ║
║ $                                                                         ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

</div>

## 📊 Smart Status Line Details

**Your co-pilot's instrument panel** provides real-time guidance:

### Information Architecture
```
📁 {dir} | {branch} | {changes} | {sync} | {pr} | 🤖 {model} | 🧠 {context}
```

### Visual Language Guide

| Symbol | Meaning | Color | Action Needed |
|--------|---------|-------|---------------|
| ⚠️ | On main branch | 🔴 Red | Use `/launch` to start |
| 🌟 | Feature branch | 🟡 Yellow | You're good! |
| ● | Uncommitted changes | 🟠 Orange | Consider committing |
| ✓ | Clean working tree | 🟢 Green | Ready to switch |
| ↑ | Ahead of origin | 🟡 Yellow | Push when ready |
| ↓ | Behind origin | 🔵 Blue | Pull to sync |
| ↕ | Diverged | 🔴 Red | Rebase needed |
| PR#X→ | PR open | 🔵 Blue | Checks running |
| PR#X✓ | PR merged | 🟢 Green | Run `/scrub` |

### Context Bar Visualization

The context bar changes color as you work:

```
🧠 [██████████] 100% left  - 🟢 Fresh start
🧠 [███████░░░] 70% left   - 🟢 Plenty of room
🧠 [█████░░░░░] 50% left   - 🟡 Half way there
🧠 [███░░░░░░░] 30% left   - 🟠 Getting tight
🧠 [█░░░░░░░░░] 10% left   - 🔴 Wrap it up!
```

## 📖 Commands

### Essential Commands

| Command | What It Does | 
|---------|--------------|
| `/ship` | Complete PR workflow with auto-merge and deploy |
| `/launch` | Start a clean feature branch |
| `/scrub` | Clean up merged branches |
| `/health` | Repository diagnostic scan |

### Command Details

#### `/launch` - Start New Work
**Create a clean feature branch:**
```bash
/launch                 # Auto-generate branch name
/launch my-feature      # Specify branch name
```

#### `/ship` - Ship Your Code  
**The magic happens here:**
```bash
/ship                   # Ship everything
/ship --staged          # Ship only staged changes
/ship --nowait          # Create PR without waiting
/ship --check           # Dry run to see what would happen
/ship --force           # Override failing checks (dangerous!)
```

#### `/launch` - Start Fresh
**Clean slate for new work:**
```bash
/launch                 # Auto-generated branch name
/launch my-feature      # Custom branch name
```

#### `/scrub` - Cleanup
**Keep your repository tidy:**
```bash
/scrub                  # Interactive cleanup
/scrub --quiet          # Auto-cleanup (used by /ship)
/scrub --dry-run        # Preview what would be deleted
```

#### `/health` - Health Check
**Comprehensive diagnostic:**
```bash
/health                 # Full repository scan
```

## 🔄 Typical Workflows

### Solo Developer Flow
```bash
# Daily workflow
/launch new-feature
# ... code ...
/ship
# Already on main, ready for next feature!
```

### Power User Flow
```bash
# Ship part of your work
git add src/auth.js tests/auth.test.js
/ship --staged  # Ships auth, keeps other work
```

### Team Collaboration
```bash
# Create PR for review
/ship --nowait

# After approval, auto-merges
```

## 🛡️ Safety Features

### Git Safety
- **Branch protection** prevents direct pushes to main
- **Force-with-lease** for safe rebasing
- **Automatic stashing** preserves uncommitted work
- **Rollback on failure** keeps repository stable

### Claude Code Integration
- **Memory persistence** maintains context across sessions
- **Hook enforcement** prevents unsafe operations
- **Safety rules** in CLAUDE.md can't be overridden
- **Automatic validation** before destructive operations

### Quality Gates
- **Required checks** must pass before merge
- **Husky hooks** run local validation
- **CI/CD pipeline** validates on every push
- **Build verification** ensures deployable code

## 🎯 Best Practices

1. **Ship Small**: Smaller PRs = fewer conflicts, faster reviews
2. **Ship Often**: Daily shipping keeps you in sync
3. **Trust the Process**: Let automation handle the details
4. **Use Conventional Commits**: Enables auto-generated PR descriptions
5. **Don't Force**: Only override checks when absolutely certain

## 📋 Requirements

- **Git** repository
- **GitHub** repository (public or private)
- **GitHub CLI** (`gh`) authenticated
- **Node.js** and **pnpm** (recommended)
- **Claude Code** with agents enabled

## 🚁 Advanced Features

### Environment Variables
```bash
NOWAIT=true /ship       # Skip waiting for checks
FORCE=true /ship        # Force merge
DEBUG=true /ship        # Enable debug output
```

### Nx Monorepo Support
Automatically detects and optimizes for Nx:
- Runs only affected projects
- Parallelizes execution
- Leverages computation caching

### Custom Deployment Targets
Configure in `.github/workflows/ci.yml`:
- Deploy conditions based on paths
- Multiple deployment targets
- Environment-specific deployments

## 🤝 Contributing

Han-Solo is designed to be extended:
- Add new deployment targets
- Customize quality gates
- Extend safety checks
- Create new commands

## 📝 License

MIT - Use freely in your Claude Code projects. Solo-first, always.

---

**Stop fighting Git. Start shipping features.** 🚀

*"I've got a bad feeling about this" - You, before Han-Solo*  
*"Never tell me the odds!" - You, after Han-Solo*