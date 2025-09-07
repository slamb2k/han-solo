description: "Idempotent bootstrap of repo governance optimized for SOLO developers (zero required reviewers by default). Sets branch protection + strict checks, Husky v10 hooks, and pnpm-cached CI with 🧹/🔎/🧠/🛠️ required contexts. Delegates to bootstrap-guardian."
argument-hint: "[--branch main] [--hook both|pre-commit|pre-push] [--team] [--reviews N]"
allowed-tools: >
  Bash(git:*),
  Bash(gh api:*),
  Bash(gh repo:*),
  Bash(pnpm:*),
  Bash(npx:*),
  Bash(node:*),
  Bash(jq:*),
  Bash(mkdir:*),
  Bash(sed:*),
  Bash(sh:*)
model: claude-sonnet-4-20250514
---

## Invocation rule
The main assistant MUST delegate the full workflow to bootstrap-guardian.

## Defaults
- Solo mode (no required reviewers)
- Required checks: 🧹/🔎/🧠/🛠️
- Hooks: both

## Flags
- --team → switch to team mode (reviews required)
- --reviews N → number of required reviews in team mode (default 1)
- --branch <name> → branch to protect (default detected)
- --hook <both|pre-commit|pre-push> → which Husky hooks to install (default both)

## Context (autocollected)
- Repo: !`gh repo view --json name,owner --jq '.owner.login + "/" + .name' 2>/dev/null || echo "(not a GitHub repo)"`
- Default branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p' || echo main`
- pnpm present: !`pnpm -v >/dev/null 2>&1 && echo "pnpm ✓" || echo "pnpm ✗"`

## Task for subagent
Perform the idempotent bootstrap per the defaults/flags and print a final INFO/WARN/ERR report.
