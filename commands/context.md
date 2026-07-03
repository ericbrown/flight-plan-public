---
description: Show context window usage and Memory Bank status
---

Report the current session state at a glance.

## Context window

Estimate current context usage. Output a rough percentage based on the amount of
content in the current session. Be honest — this is an estimate.

```
Context: ~[N]% used
```

If above 60%: recommend `/handoff` now.
If above 75%: strongly recommend running `/handoff` immediately before continuing.

## Memory Bank status

Check `.claude/memory/` in the current project:

```
Memory Bank: [found / not found]
  projectContext.md: [exists / missing]
  activeContext.md:  [exists / last updated: date]
  progress.md:       [exists / missing]
  conventions.md:    [exists / N patterns]
  sessionHistory.md: [exists / N sessions]

Branch context (.claude/task-context.md): [found / not found]
```

## Current plan

If `plan.md` exists:
```
Active plan: [plan.md Goal line]
Tasks: [N checked / N total]
Linear issues: [list PROJ-IDs found in plan.md]
```

## Git state

```
Branch: [current branch]
Status: [clean / N modified]
Last commit: [message]
```

## Linear config

Read `.claude/project-config.json`:
```
Linear team: [team name / not configured]
Linear project: [project name / none]
```
