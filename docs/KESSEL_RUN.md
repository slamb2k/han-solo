# 🚀 The Kessel Run - A Solo Developer's Guide to Git Mastery

> *"It's the ship that made the Kessel Run in less than twelve parsecs!"* - Han Solo

This is your complete guide to navigating the dangerous spaceways of git development. Follow this path, and you'll be making the Kessel Run in record time.

## 🌌 Your Mission

Transform from a pilot who crashes into asteroids (merge conflicts) into one who navigates them blindfolded. This guide will take you from git novice to git ace using Han-Solo tools.

## 📍 Pre-Flight Checklist

Before we jump to hyperspace, ensure you have:

- [ ] Git installed (`git --version`)
- [ ] GitHub CLI installed (`gh --version`)  
- [ ] Claude Code installed
- [ ] A GitHub account
- [ ] 15 minutes to set up your ship

## 🛸 Stage 1: Preparing Your Ship

### Install Han-Solo

```bash
# Interactive installation (recommended for first-timers)
curl -fsSL https://raw.githubusercontent.com/slamb2k/han-solo/main/.claude/scripts/install-interactive.sh | bash
```

Choose the **Solo Developer** profile when prompted. This gives you everything you need.

### Ready to Ship

```bash
cd your-project
/launch
```

Han-Solo works with your existing repository setup:
- ✅ Uses your existing CI/CD pipeline
- ✅ Respects your branch protection rules
- ✅ Works with your current checks
- ✅ No setup required

**What just happened?** You've created a clean feature branch and you're ready to start shipping code. Han-Solo will handle the git workflow complexity for you.

## 🗺️ Stage 2: The Flight Path

### Day 1: Your First Launch

**Morning: Start Fresh**
```bash
/health                    # Check ship systems
/launch feature/day1-work   # Launch from the docking bay
```

**Work Session:**
```bash
# Make your changes
code .

# Save your progress
git add .
git commit -m "feat: add user authentication"

# Check everything's good
/health
```

**Evening: Return to Base**
```bash
/ship    # Automated docking procedure
```

Your changes are now safely merged into main. No manual PR management needed!

### Day 2: Building Momentum

**The Daily Ritual:**
```bash
# Every morning starts the same
/health                    # System check
/launch feat/day2-feature   # Clean launch
```

**Multiple Commits Strategy:**
```bash
# Work in small, logical chunks
git add src/auth.js
git commit -m "feat: add login endpoint"

git add tests/auth.test.js  
git commit -m "test: add login tests"

git add docs/API.md
git commit -m "docs: update API documentation"

/ship    # All commits shipped together
```

### Day 3: Handling Turbulence

**When Things Get Complicated:**

```bash
/launch fix/urgent-bug

# Oh no, you need something from another branch!
git cherry-pick abc123    # Grab that specific commit

# Made a mess?
git status               # Assess damage
/health                  # Get recommendations

# Nuclear option (start over)
/launch fix/urgent-bug-attempt2
```

## 🎯 Stage 3: Navigation Patterns

### Pattern 1: The Quick Fix

Perfect for typos, small bugs, urgent changes.

```bash
/launch fix/typo
# Fix the typo
git add . && git commit -m "fix: correct spelling in README"
/ship --nowait    # Don't wait for merge, move on
```
**Time: 2 minutes**

### Pattern 2: The Feature Build

For substantial new features.

```bash
/launch feat/payment-system

# Day 1
git add . && git commit -m "feat: add payment models"

# Day 2  
git add . && git commit -m "feat: add stripe integration"

# Day 3
git add . && git commit -m "test: add payment tests"

/ship --check    # Verify everything's good
/ship            # Launch when ready
```
**Time: Feature-complete before shipping**

### Pattern 3: The Experimental Probe

For trying risky things.

```bash
/launch experiment/crazy-idea

# Go wild with changes
# ...

# If it works
/ship --draft    # Create draft PR for discussion

# If it doesn't
git checkout main
git branch -D experiment/crazy-idea    # Jettison the escape pod
```

### Pattern 4: The Emergency Response

When production is on fire.

```bash
/launch hotfix/stop-the-bleeding

# Fix the critical issue
git add .
git commit -m "fix: prevent database from catching fire"

/ship --force    # Override safety checks (emergency only!)
```

## 🛡️ Stage 4: Defensive Maneuvers

### Avoiding Black Holes (Common Pitfalls)

**The "Just One More Change" Trap**
```bash
# DON'T DO THIS
/launch feature/simple-change
# ... 3 hours later ...
# ... 47 files changed ...
# ... merge conflicts everywhere ...

# DO THIS INSTEAD
/launch feature/simple-change
# Make ONE change
/ship
# Want more changes? Start fresh!
/launch feature/another-simple-change
```

**The "I'll Commit Later" Syndrome**
```bash
# DON'T DO THIS
# ... work for 3 days without committing ...
# ... computer crashes ...
# ... work gone ...

# DO THIS INSTEAD
git commit -m "WIP: save progress"    # Commit every hour
git commit -m "WIP: before lunch"     # Commit at transitions
git commit -m "WIP: end of day"        # Commit before leaving
```

**The "Main Branch Cowboy"**
```bash
# DON'T DO THIS
git checkout main
# Edit files directly on main
git commit -m "yolo"

# DO THIS INSTEAD
/launch       # ALWAYS start with /launch
# Work on feature branch
/ship        # Let automation handle main
```

## 🎖️ Stage 5: Advanced Maneuvers

### The Parallel Development Pattern

Working on multiple features simultaneously:

```bash
# Terminal 1: Feature A
/launch feat/user-profiles
# Work on user profiles

# Terminal 2: Feature B  
/launch feat/notifications
# Work on notifications

# Ship whichever is ready first
cd ../feature-a-dir
/ship

cd ../feature-b-dir
/ship
```

### The Review-Your-Own-PR Pattern

Even solo devs benefit from reviewing their own code:

```bash
/launch feat/complex-feature
# ... make changes ...
git commit -m "feat: add complex feature"

/ship --draft    # Create draft PR
# Review your changes on GitHub
# Make adjustments if needed
git commit -m "refactor: improve code quality"

gh pr ready      # Mark as ready
/ship           # Complete the merge
```

### The Continuous Deployment Pattern

Ship multiple times per day:

```bash
# Morning
/launch feat/morning-work
# Small chunk of work
/ship

# After lunch
/launch feat/afternoon-work  
# Another small chunk
/ship

# Before leaving
/launch fix/cleanup
# Quick cleanup
/ship

# Result: 3 clean deployments, no conflicts
```

## 🏁 Stage 6: The Final Approach

### Your Daily Workflow

```yaml
Morning:
  - /health                 # Check status
  - /launch feat/daily-work  # Start clean
  - Work in small chunks
  - Commit frequently

Afternoon:
  - /ship --check          # Pre-flight check
  - /ship                  # Deploy
  - /launch feat/next-task  # Start next task

Evening:
  - /ship                  # Ship today's work
  - /health               # Final check
```

### Your Weekly Workflow

```yaml
Monday:
  - /health --full        # Comprehensive check
  - Clean up old branches
  - Plan week's work

Daily:
  - Follow daily workflow
  - Ship at least once

Friday:
  - Ship everything
  - No uncommitted work
  - /health              # Leave clean
```

## 📊 Stage 7: Success Metrics

You're making the Kessel Run successfully when:

### Speed Metrics
- ⚡ Branch to merge: < 1 day
- ⚡ Commits per day: 3-10
- ⚡ Ships per day: 1-3
- ⚡ Merge conflicts: 0

### Health Metrics  
- ✅ Health score: > 90%
- ✅ Open branches: < 3
- ✅ Stash count: 0
- ✅ Branch age: < 24 hours

### Quality Metrics
- 🎯 CI passes: > 95%
- 🎯 Force pushes: 0
- 🎯 Reverted commits: < 1%
- 🎯 Commit message quality: High

## 🎓 Graduation Ceremony

You've completed the Kessel Run when you can:

1. **Ship a feature in < 10 minutes**
   ```bash
   /launch → code → commit → /ship
   ```

2. **Recover from any git situation**
   ```bash
   /health → follow recommendations → recover
   ```

3. **Work without thinking about git**
   - Git becomes invisible
   - You focus on code, not version control
   - Shipping is automatic

4. **Help others escape the Sarlacc**
   - You can teach this workflow
   - You prevent git disasters for others
   - You've become a git Jedi

## 🚨 Emergency Procedures

### Lost in Space (Detached HEAD)
```bash
git checkout main
/launch recovery-branch
```

### Hull Breach (Merge Conflicts)
```bash
git merge --abort
/launch start-over
```

### Engine Failure (Can't Push)
```bash
git fetch origin
git rebase origin/main
/ship --force  # If you're sure
```

### Complete System Failure
```bash
# Save your work elsewhere
cp -r . ../backup

# Nuclear reset
git checkout main
git reset --hard origin/main
/launch clean-start
```

## 🌟 The Way of the Git Jedi

### The Git Jedi Code

1. **Start fresh, always** - Every journey begins with `/launch`
2. **Ship small, ship often** - Multiple small ships > one big ship
3. **Commit with meaning** - Your future self will thank you
4. **Trust the automation** - Let Han-Solo handle the complexity
5. **Check health daily** - Prevention > cure
6. **Never force push to main** - The dark side, that is
7. **Help others** - Share the knowledge

### Wise Words from Git Masters

> "The best commit is a small commit." - Git Yoda

> "Merge conflicts are caused by holding onto code too long." - Git Obi-Wan

> "The force push is a path to the dark side." - Git Mace Windu

> "Do or do not commit. There is no 'save for later'." - Git Yoda

## 🎬 Your Next Steps

1. **Practice the basics** for one week:
   - `/launch` every morning
   - `/ship` every evening
   - `/health` checks daily

2. **Add advanced patterns** in week two:
   - Multiple branches
   - Draft PRs
   - Parallel development

3. **Achieve mastery** by week three:
   - Ship 3+ times daily
   - Zero merge conflicts
   - Help someone else

## 🏆 Achievements Unlocked

Track your progress:

- [ ] 🎖️ **First Ship** - Complete your first `/ship`
- [ ] 🎖️ **Daily Shipper** - Ship every day for a week
- [ ] 🎖️ **Conflict Free** - 10 ships without conflicts
- [ ] 🎖️ **Speed Demon** - Ship in under 5 minutes
- [ ] 🎖️ **Clean Operator** - Maintain 100% health for a week
- [ ] 🎖️ **Git Jedi** - Complete 100 successful ships
- [ ] 🎖️ **Kessel Run Champion** - Ship 5 times in one day

## 📚 Continue Your Training

- Review **[SARLACC.md](SARLACC.md)** to understand what we're avoiding
- Read **[GIT_WORKFLOW_GUIDE.md](GIT_WORKFLOW_GUIDE.md)** for detailed patterns
- Check **[README.md](../README.md)** for command reference

---

## 🎊 Congratulations!

You now have the knowledge to make the Kessel Run. Remember:

- **Speed comes from safety** - The tools prevent problems
- **Consistency beats complexity** - Same workflow every time
- **Small steps win** - Little and often beats big and rare

Now go forth and ship with confidence. May the git force be with you!

*"Great shot, kid! That was one in a million!"* - Your code review after following this guide

---

**Final Challenge**: Can you make the Kessel Run (morning `/launch` to evening `/ship`) in less than 12 parsecs... er, minutes?

Good luck, pilot. The galaxy is counting on you! 🚀