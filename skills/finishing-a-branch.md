---
name: finishing-a-branch
description: Use when all tasks on a feature branch are complete and verified. Activates after execute completes successfully, or when the user says "we're done", "ship it", "merge this", "clean up". Handles final verification, PR options, and worktree cleanup.
---

# Finishing a Development Branch

All tasks done? Run this before touching anything else.

## Step 1 — Final verification

Run the full suite one last time from a clean state:
```
git stash  # ensure no accidental staged changes
git stash pop
```
Then: typecheck → full tests → lint → build

If anything fails: stop. Do not proceed. Fix it or report it.

## Step 2 — Diff review

Run `git diff main...HEAD --stat` and `git log main..HEAD --oneline`.

Present to the user:
```
Branch: [branch name]
Commits: [N commits since main]
Files changed: [list]
Net: +[N] -[N] lines
```

Ask the user to confirm this matches what they expected.

## Step 3 — Present options

Ask: "Everything looks good. What would you like to do?"

Present these options:
1. **Create PR** — push branch, open PR, keep branch open for review
2. **Merge locally** — merge into main now, delete branch (use only if solo project or you own main)
3. **Keep open** — push branch but don't PR yet, continue work later
4. **Discard** — you don't want these changes (confirm before doing anything destructive)

Wait for explicit choice.

## Step 4 — Execute the chosen option

**Create PR:**
- `git push origin [branch]`
- Create PR: title = plan.md Goal, body = summary + task list
- Spawn `linear-sync` → `ADD_COMPLETION_COMMENT` on all issues with PR URL
- Leave Linear issues open

**Merge locally:**
- `git checkout main && git merge [branch] --no-ff -m "merge: [plan goal]"`
- `git push origin main`
- `git branch -d [branch]`
- Spawn `linear-sync` → `ADD_COMPLETION_COMMENT` noting merged to main

**Keep open:**
- `git push origin [branch]`
- Update `.claude/task-context.md` with current state
- Leave everything as-is

**Discard:**
- Confirm: "Discard all changes on [branch]? This cannot be undone. (yes/no)"
- On yes: `git checkout main && git branch -D [branch]`

## Step 5 — Clean up worktree (if applicable)

If this branch was created as a git worktree:
```
git worktree remove [path] --force
git branch -d [branch]  # only after PR merged or local merge
```

Ask first: "Was this a worktree? If so I can clean up [path]."

## Step 6 — Update Memory Bank

- Move tasks from "In progress" to "Done" in `.claude/memory/progress.md`
- Append to `sessionHistory.md`
- Remove `.claude/task-context.md` from branch if merging/PR'd

## What you never do

- Never `git merge` without running full tests first
- Never delete a branch without confirming the user's intent
- Never force-push to main
- Never close Linear issues — that's the user's action
