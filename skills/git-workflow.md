# Skill: Git Workflow

This is the canonical way we use Git on every project. The always-on summary
lives in `CLAUDE.md` (section "Git Workflow"); this file is the full playbook it
points to. When a Git question comes up mid-task — how to branch, how to merge,
how to resolve a conflict — this is the authority.

## Branch model

```
main      ← production. Released, stable. Protected.
  ↑
staging   ← optional. Used when a release needs a soak before main.
  ↑
dev       ← integration. Where feature branches land.
  ↑
feature   ← <user>/<short-name>. One per task. Short-lived.
```

- `main` and `dev` always exist. `staging` exists on projects that need it —
  not every repo has one.
- **Never commit directly to `dev` or `main`.** Every change reaches them through
  a pull request. Direct commits cause dev/main divergence.

## Workflow

**Step 1 — Start a feature branch off `dev`, hard-synced.**
```bash
git fetch origin
git checkout dev
git reset --hard origin/dev      # born even with origin, never behind
git checkout -b <user>/<short-name>
```
Hard-sync first. A branch cut from a stale `dev` starts behind origin and the PR
gets blocked later. No suppressed errors (`2>/dev/null`), no truncated output.

**Step 2 — Do the work and commit.**
- Commit messages are descriptive — what changed and why, not "fix stuff."
- Commit at meaningful boundaries, not one giant commit at the end.

**Step 3 — Push the branch.**
```bash
git remote -v                    # confirm the exact remote BEFORE pushing
git push -u origin <user>/<short-name>
```
Always verify the remote first. With multiple repos in flight, "push this" is
ambiguous — confirm the target, then push.

**Step 4 — Open a pull request: feature → `dev`.**
- Always a PR. Never merge directly without one.
- PR body explains what changed, why, and how to test it.
- If the PR defaulted to `main`, retarget it to `dev`.

**Step 5 — Merge with `--merge`, never squash.**
```bash
gh pr merge --merge              # NEVER --squash, NEVER --rebase
```
Squash destroys commit history. This was forbidden after a session where it
caused lost history. Merge commits only.

**Step 6 — Reset for the next task.**
```bash
git checkout dev
git pull
git checkout -b <user>/<next-thing>   # branch the next task off updated dev
```
This is the whole trick to never needing a rebase: always branch the next task
from a freshly pulled `dev`.

**Step 7 — `dev` → `main` is a periodic sync.**
- After a batch of features is stable, open a `dev` → `main` PR.
- Same rules: PR, `--merge`, never squash.

## Conflicts

- Bring `dev` into the feature branch with a **merge**:
  ```bash
  git merge origin/dev
  ```
  Resolve, commit, push normally.
- **Never rebase a PR branch.** Never force-push to resolve conflicts.

## Rules — never break these

- **Never commit directly to `dev` or `main`.** Feature branch → PR, always.
- **Never squash-merge.** `gh pr merge --merge` only. Squash destroys history.
- **Never rebase a PR branch.** Use `git merge origin/dev` for conflicts.
- **Never force-push** to any shared branch. Force-push to `main`/`master` is in
  the deny list.
- **Never push to a branch after its PR is merged.** The branch is dead — cut a
  new branch off the updated base for follow-up work.
- **Never `git stash` to move changes between branches.** Create a clean branch
  instead; stashing causes conflicts when the target has a different file set.
- **Never use `git checkout <branch> -- <path>`** to move live code between
  branches — it silently stages files onto the current branch.
- **Always `git remote -v` before any push.** Confirm remote and branch first.
- **Always hard-sync before branching** (`git reset --hard origin/dev`). No
  suppressed errors, no truncated output.
