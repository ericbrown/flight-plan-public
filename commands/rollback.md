---
description: Restore a named checkpoint tag or go back N commits
---

Usage:
  /rollback                   → show available checkpoints, pick one
  /rollback checkpoint-name   → restore to a specific checkpoint tag
  /rollback 2                 → go back 2 commits (soft reset, keeps changes staged)

## List available checkpoints

Run:
```
git tag --sort=-creatordate | grep "^checkpoint"
git stash list
```

Output the list with dates. Ask which one to restore.

## Restore a checkpoint tag

Show what will change:
```
git diff HEAD [tag] --stat
```

Confirm: "Restore to [tag-name]? This will [describe impact]. (yes/no)"

On yes:
```
git checkout [tag]
```

Note: This puts git in detached HEAD state. Ask if the user wants a new branch from here:
"Create a branch from this checkpoint? (yes/[branch-name] / no)"

## Go back N commits (soft reset)

Show the commits that will be "undone":
```
git log --oneline -[N+2]
```

Confirm: "Soft-reset [N] commits? Changes will be staged but not lost. (yes/no)"

On yes:
```
git reset --soft HEAD~[N]
```

Output: "[N] commits rolled back. Changes are staged — review with `git diff --staged`."

## Hard reset (destructive — use with caution)

Only offer this if the user explicitly asks for it.
The `destructive-ops-guard` hook will auto-checkpoint before this runs.

```
git reset --hard [target]
```
