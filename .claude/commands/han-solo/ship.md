description: "Ship with a governed fast path tailored for SOLO devs: rebase onto origin/<default>, create/update PR, WAIT for required checks by default, then squash-merge & clean up. --nowait for PR-only. --force to override failing checks (explicit only)."
argument-hint: "[--nowait] [--force] [--title \"PR title\"] [--branch-name <name>]"
allowed-tools: >
  Bash(git:*),
  Bash(gh pr:*),
  Bash(gh repo:*),
  Bash(gh auth:*),
  Bash(pnpm:*),
  Bash(npx:*),
  Bash(node:*),
  Bash(jq:*)
model: claude-sonnet-4-20250514
---

## Invocation rule
Delegate the entire workflow to git-shipper.

## Defaults
- Wait for required checks and merge when green
- No required human reviewers (compatible with /bootstrap’s solo defaults)

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

## Task
Execute the shipping workflow per the defaults/flags and print a final INFO/WARN/ERR report.
