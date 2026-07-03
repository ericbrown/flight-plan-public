---
description: Switch behavioral mode. Boris-style modes restrict tool access to prevent accidents.
---

Usage: `/mode [architect|code|debug|review|audit]`

Switch the current operating mode. Each mode restricts what actions are allowed.

## Modes

### architect
**Purpose**: Design and planning phase. Think before building.
**Allowed**: Read files, search codebase, browse docs, write to plan.md and task-context.md only
**Blocked**: No edits to source files, no running tests, no commits
**Use when**: Starting a new feature, evaluating approaches, designing architecture
**Exit**: `/mode code` when ready to implement

### code
**Purpose**: Full implementation. The default mode.
**Allowed**: Everything
**Use when**: Executing an approved plan
**Note**: Always have an approved plan before entering this mode

### debug
**Purpose**: Investigation only. Hypothesis-driven.
**Allowed**: Read files, run tests, add temporary diagnostic logging
**Blocked**: No permanent edits unless directly fixing the confirmed root cause
**Rules**: State hypothesis before making any change. One change at a time.
**Use when**: A test is failing, a bug is reported, behavior is unexpected
**Exit**: `/mode code` once root cause is confirmed and fix is ready

### review
**Purpose**: Strict read-only code review.
**Allowed**: Read files, read diffs, output review comments
**Blocked**: No file edits of any kind, no running anything
**Use when**: Reviewing a PR or diff before merging
**Exit**: `/mode code` to implement review feedback

### audit
**Purpose**: Security scanning. Everything logged.
**Allowed**: Read files, run static analysis tools, read output
**Blocked**: No writes, no commits, no deploys
**Note**: All tool calls are logged to `~/.claude/audit.log`
**Use when**: Pre-release security review, compliance check

---

## Output

After switching:

```
Mode: [mode name]

[What's allowed]
[What's blocked]
[Reminder of what this mode is for]
```

## Current mode tracking

Track the current mode in the session. When a restricted action is attempted in a
restricted mode, output:
```
⚠ This action is not allowed in [mode] mode.
Switch with: /mode code
```

Do not silently skip the action — always explain why and how to unblock.
