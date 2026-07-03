---
description: Create a named save point for easy rollback
---

Create a git tag as a checkpoint.

Usage: `/checkpoint` or `/checkpoint [name]`

If no name provided, use: `checkpoint-[timestamp]` (format: `cp-YYYYMMDD-HHMM`)

```
git tag [name]
git stash list | head -5
```

Output:
```
Checkpoint created: [tag name]
Current branch: [branch]
To rollback to this point: /rollback [tag name]
```
