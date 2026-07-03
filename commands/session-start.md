---
description: Load Memory Bank, orient to project, enter plan mode. Run at the start of every session.
---

Load context silently, then present a single compact summary.

## Step 1 — Read Memory Bank

Check for `.claude/memory/` in the project root.

**If it exists**, read these files in order:
1. `.claude/memory/projectContext.md`
2. `.claude/memory/activeContext.md`
3. `.claude/memory/progress.md`
4. `.claude/memory/conventions.md` — note the top 1–2 most relevant patterns
5. `.claude/memory/sessions/` — scan for the most recent session file if activeContext seems stale

**If it does not exist**, check for fallback files:
- `plan.md` in project root
- `tasks/handoff.md`, `tasks/todo.md`, `tasks/lessons.md`

## Step 2 — Read Branch Context

If `.claude/task-context.md` exists on the current branch, read it.
This contains branch-specific objective, plan, decisions, and resume prompt.

## Step 3 — Git Status

Run and capture:
- `git branch --show-current`
- `git status --short`
- `git log --oneline -5`

## Step 4 — Read Project Config

If `.claude/project-config.json` exists, read it for project name, stack, and commands.
Otherwise infer project type from: `package.json`, `pyproject.toml`, `fly.toml`, `mkdocs.yml`.

## Step 5 — Present Summary

Output this (and nothing else — keep it compact):

```
## Session Start — [project name]

Branch: [branch] | Status: [clean / N modified / N untracked]
Last commit: [message]

Last session: [1–2 sentences from activeContext.md "Session goal" + "Current state"]
In progress: [from progress.md, or "nothing active"]
Up next: [from progress.md, or "nothing queued"]

Conventions: [top 1–2 relevant items from conventions.md, or "none"]
```

If no Memory Bank and no fallbacks:
```
## Session Start — [project name]

No Memory Bank found. First session in this project?
Run /memory-init to set up persistent context, then describe what you want to work on.
```

## Step 6 — Enter Plan Mode

Enter plan mode now. Do not write any code or make any file changes.
Wait for the user to describe a task. Present a plan. Get approval. Then proceed.
