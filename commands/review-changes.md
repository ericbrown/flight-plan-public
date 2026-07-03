---
description: Read-only review of uncommitted changes before committing. Boris-style: would a staff engineer approve this?
---

Review all uncommitted changes. This is read-only — no edits.

## Step 1 — Get changed files

```
git diff --name-only HEAD
git diff --staged --name-only
```

If nothing to review: "No uncommitted changes." and stop.

## Step 2 — Read each changed file's diff

For each changed file, read the full diff (`git diff HEAD [file]`).

## Step 3 — Review criteria

For each file, check:

**Correctness**
- Does the logic match the stated intent?
- Are there obvious off-by-one errors, null/undefined cases, type mismatches?
- Are error cases handled?

**Test coverage**
- Are new functions/methods covered by tests?
- Are edge cases tested?
- Any tests that were changed — do the changes make the tests weaker?

**Conventions**
- Does the code match patterns in `.claude/memory/conventions.md`?
- Does it follow the style of the reference files named in plan.md?
- Naming consistent with the rest of the codebase?

**Scope**
- Are any changes outside the stated plan? (flag these — they may be unintentional)
- Any debug artifacts left in (console.log, print(), TODO comments)?

**Security (quick check)**
- Any secrets, tokens, or credentials in the diff?
- Any user input going directly into queries/commands without sanitization?

## Step 4 — Output

```
## Review

[filename]
  ✓ Logic correct
  ✓ Tests present
  ⚠ [issue description] — [line number or function name]
  ✗ [blocking issue description]

[filename]
  ✓ Clean

Summary:
  Files reviewed: [N]
  Blocking issues: [N] — [must fix before committing]
  Warnings: [N] — [worth addressing]
  Clean: [N]
```

Blocking issues must be fixed before `/commit-push-pr`. Warnings are optional.

If blocking issues exist: describe exactly what needs to change.
Do NOT make changes automatically — this command is read-only.
Say: "Fix the [N] blocking issue(s) above, then run /commit-push-pr."
