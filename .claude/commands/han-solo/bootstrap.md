description: "Idempotent bootstrap of repo governance optimized for SOLO developers (zero required reviewers by default). Sets branch protection + strict checks, Husky v10 hooks, and pnpm-cached CI with 🧹/🔎/🧠/🛠️ required contexts. Delegates to bootstrap-guardian."
argument-hint: "[--branch main] [--hook both|pre-commit|pre-push] [--team] [--reviews N]"
---

## Invocation rule
Delegate to a general-purpose agent with the bootstrap-guardian implementation, ensuring context isolation.

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

## Instructions
1. Read the entire contents of `.claude/agents/bootstrap-guardian.md`
2. Use the Task tool with:
   - subagent_type: "general-purpose"
   - description: "Execute bootstrap-guardian workflow"
   - prompt: Include the full agent markdown content plus these instructions:
     - "You are bootstrap-guardian. Execute the bash script embedded between ```bash markers."
     - "Set these environment variables based on flags provided:"
       * If --team flag present: TEAM_MODE=true
       * If --reviews flag present: REQUIRED_REVIEWS=<value>
       * If --branch flag present: EXPLICIT_BRANCH=<value>
       * If --hook flag present: HOOK_TYPE=<value>
     - "Run the bash script and report the final INFO/WARN/ERR summary"
