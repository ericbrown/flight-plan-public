---
description: Revert the last Claude-made change safely
---

Revert the most recent commit made in this session.

## Step 1 — Show what will be undone

```
git log --oneline -3
```

Output: "About to revert: [most recent commit message]. Confirm? (yes/no)"

## Step 2 — Revert

On confirmation:
```
git revert HEAD --no-edit
```

This creates a new revert commit (does not rewrite history). Safe on shared branches.

If the user wants to completely remove the commit (local branch only):
```
git reset --soft HEAD~1
```
Offer this as an option only if on a local-only branch.

Output: "Reverted. [N] files restored to previous state."
