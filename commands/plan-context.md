---
description: "Plan stage 1: scope and affected files. Approval gate before plan:tasks."
---

Read the CLAUDE.md and Memory Bank conventions first. Then, for the task described,
do ONLY the following. Do not write an implementation plan.

## Output this structure

```
## Scope: [task name]

### Affected files (likely)
- `path/to/file.ts` — reason it will change
- `path/to/other.ts` — reason it will change

### Reference files (existing patterns to follow)
- `path/to/reference.ts` — why this is the right pattern to match

### External dependencies / APIs involved
- [list any third-party SDKs, APIs, env vars this will touch]

### Out of scope (explicitly)
- [things that are related but NOT part of this task]

### Open questions (if any)
- [anything ambiguous that needs answering before planning]
```

## Rules

- Do not propose any implementation approach yet.
- Do not write any task list.
- Max 20 affected files. If more are likely, that's a sign the task is too large — flag it.
- If there are open questions, stop after listing them and wait for answers before proceeding.

## Gate

After outputting the scope, say:
"Scope looks right? Say 'yes' to proceed to /plan-tasks, or correct anything above."

Do not proceed to /plan-tasks until the user explicitly confirms.
