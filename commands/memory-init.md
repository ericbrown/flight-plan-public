---
description: Initialize Memory Bank for a new project. Run once per project.
---

Set up persistent context for this project.

## Step 1 — Check for existing Memory Bank

If `.claude/memory/` already exists:
Output: "Memory Bank already exists. I'll create any missing files without overwriting existing ones."

## Step 2 — Collect project info

Ask the user (can be answered in one message):
1. What is this project? (one sentence)
2. Primary language and framework?
3. Package manager? (npm/bun/pip/etc.)
4. Test command? (e.g. `bun test`, `pytest`)
5. Typecheck command? (e.g. `bun run typecheck`, `mypy .`)
6. Lint command? (e.g. `bun run lint`, `ruff check .`)
7. Build command? (or "none")
8. Dev server command? (or "none")
9. Auto-run tests after every file edit? (yes/no — enables the post-edit test runner hook)

## Step 3 — Create directory and config

```
mkdir -p .claude/memory/sessions
```

Write `.claude/project-config.json` (merge with existing if present):
```json
{
  "project_name": "[name]",
  "description": "[one sentence]",
  "stack": {
    "language": "[language]",
    "framework": "[framework]",
    "package_manager": "[npm|bun|pip|etc]"
  },
  "commands": {
    "test": "[command]",
    "test_single": "[command with filter flag]",
    "typecheck": "[command]",
    "lint": "[command]",
    "build": "[command or null]",
    "dev": "[command or null]"
  },
  "linear_team_id": null,
  "linear_project_id": null,
  "linear_in_progress_status_id": null,
  "test_on_edit": false,
  "git_enabled": true,
  "created": "[date]"
}
```

Note: `linear_*` fields are populated automatically on first `/plan-tasks` run.

## Step 4 — Create Memory Bank files

**`projectContext.md`**:
```markdown
# Project Context
Created: [date]

## What this is
[user's description]

## Why it exists
[purpose, audience, problem it solves]

## Architecture overview
[brief — expand as the project is explored]

## Key files / entry points
[fill in as discovered]

## External dependencies / APIs
[fill in as discovered]

## Stack
Language: [lang] | Framework: [fw] | Package manager: [pm]
Deployment: [fill in]
```

**`activeContext.md`**:
```markdown
# Active Context
Last updated: [date]

## Session goal
First session — project setup and orientation.

## Current state
Memory Bank initialized. No active tasks yet.

## Resume prompt
New project: [name]. Run /session-start and describe what to build first.
```

**`progress.md`**:
```markdown
# Progress

## Completed
(nothing yet)

## In progress
(nothing yet)

## Up next
- [ ] Explore codebase and fill in projectContext.md
- [ ] Run /plan-context for first task
```

**`decisionLog.md`**:
```markdown
# Decision Log

### Format
**[date] — [decision title]**
Context: [why this decision was needed]
Decision: [what was decided]
Rationale: [why this option]
Alternatives: [what else was considered]
```

**`conventions.md`**:
```markdown
# Project Conventions

Project-specific learned patterns. Updated automatically during sessions.

## Code style
[fill in]

## Naming conventions
[fill in]

## Testing approach
[fill in]

## Environment / deployment notes
[fill in]

## Corrections
[format: [date] [what went wrong] → [correct behavior]]
```

**`sessionHistory.md`**:
```markdown
# Session History

[date] — Memory Bank initialized. Project: [name].
```

## Step 4b — Create loop maintenance file

Copy the loop template to `.claude/loop.md`:

```bash
cp ~/flight-plan/memory-template/loop.md .claude/loop.md
```

This customizes what bare `/loop` does in this project (no-argument `/loop` reads this file).
Tell the user: "Edit `.claude/loop.md` to match your maintenance preferences. The defaults cover PR babysitting, test health, and branch hygiene."

## Step 4c — Create deprecations file

Copy the deprecations template to `.claude/memory/deprecations.md`:

```bash
cp ~/flight-plan/memory-template/deprecations.md .claude/memory/deprecations.md
```

This is where formally-deprecated patterns are recorded (via `/deprecate <name>`). The
SessionStart scan warns when an `ACTIVE` entry appears in code changed since your last session.

---

## Step 5 — Git decision

Ask: "Commit `.claude/` to git? This enables cross-machine handoffs via `git pull`.
(Recommended: yes. Say no if you want to keep Claude context private.)"

If yes: `git add .claude/ && git commit -m "chore: init claude memory bank"`
If no: add `.claude/memory/` to `.gitignore`

## Step 6 — Confirm

Output:
```
Memory Bank initialized for [project name].

Created:
  .claude/project-config.json
  .claude/memory/projectContext.md
  .claude/memory/activeContext.md
  .claude/memory/progress.md
  .claude/memory/decisionLog.md
  .claude/memory/conventions.md
  .claude/memory/sessionHistory.md
  .claude/memory/deprecations.md    (record with /deprecate — session-start scan warns on use)
  .claude/memory/sessions/          (dated session files go here)
  .claude/loop.md                   (bare /loop maintenance behavior — edit to customize)

Linear fields (linear_team_id etc.) will be set on first /plan-tasks run.
test_on_edit: set to true in project-config.json to enable auto test runs after each file edit.

Next: /session-start loads this context automatically at the start of each session.
```
