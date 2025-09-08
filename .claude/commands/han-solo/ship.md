description: "Ship with a governed fast path tailored for SOLO devs: rebase onto origin/<default>, create/update PR, WAIT for required checks by default, then squash-merge & clean up. --nowait for PR-only. --force to override failing checks (explicit only)."
argument-hint: "[--nowait] [--force] [--title \"PR title\"] [--branch-name <name>]"
---

## Invocation rule
Delegate to a general-purpose agent with the git-shipper implementation, ensuring context isolation.

## Defaults
- Wait for required checks and merge when green
- No required human reviewers (compatible with /bootstrap's solo defaults)

## Flags
- --nowait → PR only; do not merge
- --force → allow merge despite failing checks (explicit user choice)
- --title "<text>" → explicit PR title
- --branch-name "<name>" → explicit branch when branching from default

## Context (autocollected)
- Repo: !$(gh repo view --json name,owner --jq '.owner.login + "/" + .name' 2>/dev/null || echo "(not a GitHub repo)")
- Default branch: !$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p' || echo main)
- Current branch: !$(git branch --show-current 2>/dev/null || echo "(detached)")
- Local status: !$(git status --porcelain=v1)

## Instructions
1. Read the entire contents of `.claude/agents/git-shipper.md`
2. Use the Task tool with:
   - subagent_type: "general-purpose"
   - description: "Execute git-shipper workflow"
   - prompt: Include the full agent markdown content plus these instructions:
     - "You are git-shipper. Execute the bash script embedded between ```bash markers."
     - "Set these environment variables based on flags provided:"
       * If --nowait flag present: NOWAIT=true
       * If --force flag present: FORCE=true
       * If --title flag present: EXPLICIT_TITLE=<value>
       * If --branch-name flag present: EXPLICIT_BRANCH_NAME=<value>
     - "Run the bash script and report the final INFO/WARN/ERR summary"
