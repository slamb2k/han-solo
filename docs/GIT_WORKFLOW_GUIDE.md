# 🚀 Git Workflow Guide: Avoiding Merge Conflict Hell

> **⚡ TL;DR**: Never work on main. Always ship from clean feature branches. Always sync after shipping.

## 📖 Table of Contents
1. [The Core Problem](#-the-core-problem)
2. [Scenario Analysis](#-scenario-analysis)
3. [Warning Signs](#-warning-signs)
4. [Protection Rules](#️-protection-rules)
5. [The Ultimate Safe Workflow](#-the-ultimate-safe-workflow)
6. [Emergency Recovery](#-emergency-recovery)
7. [Quick Reference](#-quick-reference)

---

## 🔥 The Core Problem

When you use `/ship`, here's what happens behind the scenes:

```
Your Local Branch        GitHub PR           GitHub Main
     [A]--[B]--[C]  →  [A]--[B]--[C]  →  [Squashed ABC]
                                              ↓
                                    Your commits disappear!
```

### Why This Causes Pain 😱

- **Squash merging** combines commits A+B+C into one new commit
- Git tracks commits by SHA hash
- Original hashes (111, 222, 333) ≠ Squashed hash (999)
- Git thinks branches have diverged!

---

## 📊 Scenario Analysis

### Scenario 1: Working on main, uncommitted changes ✅
```
main (uncommitted) → /ship → feature/new → PR → ✅ Generally Safe
```
**Status**: ✅ SAFE  
**Why**: Your main stays clean, no commits to conflict

### Scenario 2: Working on main, committed but not pushed 🔴
```
main (commits A,B) → /ship → feature/new → PR (squashes to X) → origin/main has X
     ↓
Your main still has A,B → Pull → 💥 DIVERGED!
```
**Status**: 🔴 DANGEROUS  
**Problem**: Local commits conflict with squashed version

### Scenario 3: Reusing merged feature branch 🔴
```
feature/foo (merged) → new changes → /ship → PR includes old commits!
```
**Status**: 🔴 DANGEROUS  
**Problem**: PR shows already-merged changes

### Scenario 4: Orphaned feature branch ⚠️
```
feature/bar (deleted on GitHub) → new changes → /ship → recreates branch
```
**Status**: 🟡 RISKY  
**Problem**: Base is outdated, potential conflicts

### Scenario 5a: The "Forgotten Pull" 📅
```
main (Monday) → Friday work → /ship → PR conflicts with week of changes
```
**Status**: 🟡 RISKY  
**Problem**: Working from stale base

### Scenario 5b: The "Stacked Changes" 📚
```
main + commit A → /ship PR#1
main + commit B → /ship PR#2 (includes A again!)
```
**Status**: 🔴 DANGEROUS  
**Problem**: Duplicate commits in PRs

---

## 🚩 Warning Signs

### Red Flags in `git status`:

#### ❌ "Your branch is ahead of 'origin/main' by X commits"
```bash
# THIS MEANS DANGER! You have local commits on main
# Fix: git reset --hard origin/main (loses commits)
# Or: git checkout -b feature/save-work (saves commits)
```

#### ❌ "Your branch and 'origin/main' have diverged"
```bash
# YOU'RE ALREADY IN TROUBLE!
# Fix: git fetch && git reset --hard origin/main
```

#### ⚠️ Working on old branch
```bash
git log --oneline origin/main..HEAD
# If shows commits = danger
# If empty = safe
```

---

## 🛡️ Protection Rules

### Rule 1: 🧹 The "Clean Main" Rule
```bash
# Start EVERY work session with:
git checkout main
git fetch origin
git reset --hard origin/main  # Nuclear but safe
```

### Rule 2: 🚫 The "Never Commit to Main" Rule
```bash
# If you accidentally committed to main:
git stash  # Save any uncommitted work
git branch feature/save-commits  # Save commits
git checkout main
git reset --hard origin/main  # Clean main
git checkout feature/save-commits  # Continue work
```

### Rule 3: 🌱 The "Fresh Branch" Rule
```bash
# ALWAYS create new branches from updated main:
git checkout main && git pull
git checkout -b feature/YYYY-MM-DD-description
# work work work
/ship
```

### Rule 4: 🔍 The "Status Check" Rule
```bash
# Before EVERY /ship:
git status  # Should show feature branch
git branch -vv  # Should show tracking
git log origin/main..HEAD  # Should show YOUR commits only
```

### Rule 5: 🧼 The "Post-Ship Cleanup" Rule
```bash
# After EVERY successful /ship:
git checkout main
git fetch origin
git reset --hard origin/main
git branch -D feature/whatever  # Delete the shipped branch
```

---

## ✨ The Ultimate Safe Workflow

### 🌅 Start of Day
```bash
git checkout main
git fetch origin
git reset --hard origin/main
git clean -fd  # Remove untracked files
```

### 💼 For Each Task
```bash
# 1. Create new branch
git checkout -b feature/task-name

# 2. Work
edit files...
git add .
git commit -m "feat: description"

# 3. Ship it
/ship

# 4. IMMEDIATELY cleanup
git checkout main
git fetch origin
git reset --hard origin/main
git branch -D feature/task-name
```

### 🔄 Repeat for Next Task
```bash
git checkout -b feature/next-task
# ... and so on
```

---

## 🚨 Emergency Recovery

### Situation: "Branches have diverged"
```bash
# Option 1: Save everything (safest)
git stash  # Save uncommitted
git branch backup-$(date +%s)  # Save commits
git fetch origin
git reset --hard origin/main

# Option 2: Nuclear reset (fastest)
git fetch origin
git reset --hard origin/main
git clean -fd
```

### Situation: "Accidentally committed to main"
```bash
# Save the commits to a branch
git branch feature/recovered
git checkout main
git reset --hard origin/main
git checkout feature/recovered
```

### Situation: "PR has unexpected commits"
```bash
# Cancel the PR and start over
git checkout main
git pull origin main
git checkout -b feature/new-start
git cherry-pick <commit-sha>  # Pick only the commits you want
/ship
```

---

## 📋 Quick Reference

### 🟢 DO's
- ✅ Always work on feature branches
- ✅ Always sync main after shipping
- ✅ Always check status before shipping
- ✅ Delete feature branches after merging
- ✅ Pull main at start of each session

### 🔴 DON'Ts
- ❌ Never commit directly to main
- ❌ Never reuse merged feature branches
- ❌ Never ship without checking branch status
- ❌ Never ignore "diverged" warnings
- ❌ Never work from stale main (>1 day old)

### 🛠️ Essential Commands
```bash
# Check your safety
git status
git branch -vv
git log origin/main..HEAD --oneline

# Start over
git checkout main
git fetch origin
git reset --hard origin/main

# Create feature branch
git checkout -b feature/description

# After shipping
git checkout main
git pull origin main
git branch -D feature/old-branch
```

---

## 🎯 Golden Rules

1. **🏠 Main is sacred** - Never commit to it directly
2. **🌿 Branches are disposable** - Use them once and delete
3. **🔄 Sync frequently** - After every ship, before every task
4. **👀 Check before shipping** - Status, branch, commits
5. **🧹 Clean up always** - Delete merged branches immediately

---

## 💡 Pro Tips

- **Name branches with dates**: `feature/2024-01-15-fix-login`
- **Use aliases**: Set up shell shortcuts for common workflows
- **Automate checks**: Use pre-commit hooks to prevent main commits
- **Visual indicators**: Use prompt customization to show branch
- **Regular maintenance**: Weekly `git gc` and `git prune`

---

> **🎉 Follow these rules and you'll never see "branches have diverged" again!**

---

*Last updated: 2025-01-09 | Version: 1.0*