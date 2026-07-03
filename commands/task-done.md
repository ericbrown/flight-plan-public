---
description: Complete a task branch — verify, PR, clean up task context
---

## Step 1 — Final verification

Run `/verify`. If anything fails: stop. Do not proceed until green.

## Step 2 — Simplify (optional)

Ask: "Run /simplify before creating PR? (recommended for features, optional for fixes)"

## Step 3 — Create PR

Run `/commit-push-pr`.

## Step 4 — Remove task context

After PR is created:
```
git rm .claude/task-context.md
git commit -m "chore: remove task context — branch complete"
```

## Step 5 — Update Memory Bank

Update `.claude/memory/progress.md`:
- Move this task from "In progress" to "Done" with a brief result note.
- Update `sessionHistory.md` with a one-liner for this completed task.

## Step 6 — Optional: clean up worktree

If this branch was created as a git worktree:
```
git worktree remove ../[worktree-path]
```

Output:
```
Task complete.
Branch: [branch-name]
PR: created
Task context: removed
Memory Bank: updated
```
