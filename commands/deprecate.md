---
description: Record a deprecation — append an ACTIVE entry to .claude/memory/deprecations.md so the session-start scan warns when the deprecated pattern reappears.
---

Record that something should no longer be used in this project. Argument: `$ARGUMENTS`
(the name of the thing being deprecated — the literal import/symbol/endpoint, e.g.
`axios`, `passport.js`, `/api/v1/payments`).

## Step 1 — Ensure the deprecations file exists

If `.claude/memory/deprecations.md` does not exist:
```bash
mkdir -p .claude/memory
cp ~/flight-plan/memory-template/deprecations.md .claude/memory/deprecations.md
```
(If there's no Memory Bank at all yet, suggest running `/memory-init` first.)

## Step 2 — Gather the details

If not already clear from the conversation, ask the user (one message):
1. **Replaced by** — what to use instead?
2. **Why** — one line.
3. **Ticket** — a tracker ID, or "none".

Use the literal name the user passed in `$ARGUMENTS` so the scanner's keyword match can
find it in future diffs.

## Step 3 — Append the entry

Append to `.claude/memory/deprecations.md` (never edit existing entries):

```markdown
## [today's date YYYY-MM-DD] — DEPRECATED: [name]
Replaced by: [replacement]
Why: [one line]
Status: ACTIVE
Ticket: [PROJ-123 or none]
```

## Step 4 — Confirm

Output:
```
Deprecated: [name]
  Replaced by: [replacement]
  Status: ACTIVE — the session-start scan will warn if this appears in changed code.

Mark it RESOLVED in .claude/memory/deprecations.md once the migration is complete.
```

Optionally remind the user to commit `.claude/memory/deprecations.md` if `.claude/` is tracked.
