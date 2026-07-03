---
description: Create a feature branch with task context for cross-machine handoff
---

Usage: `/task-branch [branch-name]`

Branch name conventions: `feature/`, `fix/`, `task/` prefix.
Example: `/task-branch feature/liveness-detection-api`

## Step 1 — Create worktree (preferred) or branch

If the user has multiple sessions in flight, offer to create a git worktree:
```
git worktree add ../[repo-name]-[branch-suffix] -b [branch-name]
```

Otherwise create a normal branch:
```
git checkout -b [branch-name]
```

## Step 2 — Create task context file

Write `.claude/task-context.md`:
```markdown
# Task Context: [branch-name]
Created: [date]

## Objective
[Ask the user: "One sentence: what is this branch trying to accomplish?"]

## Plan
[Empty — to be filled by /plan-tasks]

## Key decisions
(none yet)

## Progress
- [ ] (no tasks yet — run /plan-context to start planning)

## Resume here
Branch just created. Start with /plan-context to define scope.
```

Stage and commit:
```
git add .claude/task-context.md
git commit -m "chore: init task context for [branch-name]"
```

Output:
```
Branch created: [branch-name]
Task context initialized: .claude/task-context.md
Next: /plan-context to define scope, then /plan-tasks, then /execute
```
