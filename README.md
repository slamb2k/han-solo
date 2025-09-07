![han-solo logo](assets/logo.png)

# han-solo (solo-first development)

High-velocity and governed Git workflows for solo devs & very small teams.

- /bootstrap + bootstrap-guardian: idempotent repo setup with solo-first defaults (0 required reviewers), STRICT required checks, emoji-named required contexts, Auto-merge on, auto-delete merged branches, Husky v10 hooks, and pnpm-cached CI.
- /ship + git-shipper: rebase-first PRs, auto PR body from Conventional Commits, Nx affected fast-paths, wait-by-default for required checks → squash-merge & cleanup. --nowait and --force supported.

## Install

See [INSTALL.md](INSTALL.md) for installation instructions.

### Repository Structure

```
.claude/
├── agents/
│   ├── bootstrap-guardian.md
│   └── git-shipper.md
└── commands/
    └── han-solo/
        ├── bootstrap.md
        └── ship.md
```

## Quickstart (solo default)

### Normal Solo Dev Process

1) Bootstrap governance (solo: 0 required reviewers)

    ```
    /bootstrap
    ```

2) Work normally on a feature branch...

3) Ship it (wait for checks then merge)

    ```
    /ship
    ```

### Team mode (require approvals)

```
/bootstrap --team --reviews 1
```

### PR only (no merge):

```
/ship --nowait
```

### Force merge (explicit override):

```
/ship --force
```





## What /bootstrap sets up (solo-first)

- Branch protection on your default branch:
  - PRs required, strict required checks (base must be up-to-date),
  - Required status checks (contexts) match CI job names:
    - 🧹 Format, 🔎 Lint, 🧠 Typecheck, 🛠️ Build
  - Required reviewers = 0 by default (flip to team mode with --team --reviews N).
- Repo toggles: Auto-merge on, auto-delete head branches on.
- Husky v10-style hooks:
  - pre-commit: lint-staged if present; else format(:check) + lint
  - pre-push: Nx affected targets (lint,typecheck,test,build) if Nx present; otherwise common scripts if present.
- CI: .github/workflows/ci.yml with pnpm caching and emoji job names that map to protection contexts.

## What /ship does

- Rebase-first, safe push with --force-with-lease.
- Nx affected fast-path or repo scripts.
- PR authoring:
  - Title preference: --title → first meaningful Conventional Commit since base → branch name → fallback.
  - Body auto-generated from Conventional Commits, grouped by type.
- Wait by default: watch required checks; when green → approve & squash-merge and delete branches.
  - --nowait → stop after PR creation/update.
  - --force → allow merge even if failing checks (explicit opt-in).

## References (useful docs)

- Protected branches & branch protection API; required status check contexts and strict behavior.
- Auto-merge for PRs (behavior & availability).
- gh pr checks --required --watch for waiting on required checks.
- Conventional Commits spec.
- Nx affected docs.
