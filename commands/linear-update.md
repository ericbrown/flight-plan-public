---
description: Add a progress comment or update a Linear issue manually
---

Usage:
  /linear-update              → add a progress comment to the current task's issue
  /linear-update PROJ-123     → add a comment to a specific issue
  /linear-update plan         → post the current plan.md to all issues in this plan

## Detect current issue (if no ID provided)

1. Read `plan.md` and find the currently in-progress task (last unchecked task
   that had `START_TASK` called on it, or ask which task)
2. Extract the Linear issue ID from `<!-- linear:PROJ-123 -->`

## Prompt for comment content

Ask: "What should I add to [PROJ-123]?"

If the user says something like "blocked on X" or "waiting for Y":
- Use `ADD_BLOCKER_COMMENT` operation
If it's general progress:
- Use `ADD_PROGRESS_COMMENT` operation

## /linear-update plan

Posts the full current `plan.md` content as a description update to every issue
referenced in the plan. Useful when the plan was revised after issue creation.

Invoke `linear-sync` → `ADD_PLAN_TO_ISSUE` for each issue ID found in plan.md.

## Never close from this command

This command only adds comments or updates descriptions.
It never changes issue status to any terminal state.

Output: "Updated PROJ-123: [comment preview]"
