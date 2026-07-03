---
description: Set up the main ← dev ← feature branch model in the current project — create dev, install the branch-guard CI workflow, and make dev the default branch.
---

Scaffold the Flight Plan branch model into **this** project. Pure setup — no force operations,
no history rewriting. Safe to re-run.

## Step 1 — Confirm this is a git repo with a remote

```bash
git rev-parse --is-inside-work-tree
git remote -v
```

If there is no remote, tell the user the guard CI and default-branch steps need a GitHub remote,
and stop after Step 3 (local dev branch only).

## Step 2 — Ensure a `dev` branch exists

```bash
git fetch origin
```

- If `origin/dev` already exists: `git checkout dev && git pull --ff-only`.
- Otherwise create it from the current default branch (usually `main`) and push:
  ```bash
  git checkout main && git pull --ff-only
  git checkout -b dev
  git push -u origin dev
  ```

Never reset or force here. If `dev` exists locally but not on the remote, just push it.

## Step 3 — Install the branch-guard workflow

```bash
mkdir -p .github/workflows
cp ~/flight-plan/templates/github/branch-guard.yml .github/workflows/branch-guard.yml
```

This workflow fails any PR to `main` that doesn't come from `dev`. Commit it on a feature branch
off `dev` (not directly on `dev`/`main`):

```bash
git checkout -b chore/branch-guard
git add .github/workflows/branch-guard.yml
git commit -m "ci: add branch-guard (PRs to main must come from dev)"
```

Then open a PR into `dev` per the normal workflow.

## Step 4 — Make `dev` the default branch (GitHub)

```bash
gh repo edit --default-branch dev
```

After this, new PRs target `dev` automatically and feature branches cut from `dev`.
`main` becomes the release branch — only `dev` ever merges into it, and the guard enforces that.

## Step 5 — Confirm

Output:
```
Branch model set up for [repo]:
  dev branch:       created / already existed
  branch-guard CI:  .github/workflows/branch-guard.yml (commit on a feature branch → PR to dev)
  default branch:   dev

From here: branch features off dev, PR into dev, and periodically PR dev → main.
The guard blocks any PR to main that isn't from dev.
```
