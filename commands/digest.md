---
description: Generate a weekly rollup draft from Memory Bank sessions, decisions, and research-log. Usage: /digest [days] (default 7).
---

Generate a weekly digest from accumulated context. Argument: `$ARGUMENTS` (number of days
to look back — default 7 if empty, e.g. `/digest 14` for a fortnight).

## Step 1 — Determine the lookback window

```
DAYS=$ARGUMENTS   # use the number the user passed, or 7 if blank
```

Set a cutoff date: today minus DAYS.

## Step 2 — Collect source material

Read the following files **that exist** (skip silently if missing):

1. `.claude/memory/sessions/*.md` — filter to files whose name (YYYY-MM-DD) falls within
   the lookback window.
2. `.claude/memory/progress.md` — extract items under the **Completed** section only.
3. `.claude/memory/decisionLog.md` — extract entries dated within the window.
4. `research-log/*.md` — filter to files whose name (YYYY-MM-DD or weekly-YYYY-MM-DD)
   falls within the window.

If none of these files exist yet, say so and stop — there's nothing to roll up.

## Step 3 — Synthesize the digest

From the collected material, produce a draft with this structure:

```markdown
# Weekly Digest — [start date] to [end date]

## What we shipped
[Bullet list of completed tasks / merged PRs from progress.md + session notes. One line each.]

## Key decisions
[Bullet list of architecture / approach decisions from decisionLog.md + session notes.
 Include the rationale in parentheses where it's clear.]

## What we learned
[Bullet list of lessons, corrections, and non-obvious patterns surfaced during the period.
 Pull from conventions notes and session reflections.]

## Open threads
[Anything explicitly deferred, blocked, or still in progress at the end of the window.]

## Next up
[Top 1–3 items from progress.md "Up next" or the most recent session's resume prompt.]
```

Keep each section tight — this is a summary, not a transcript. If a section is empty, omit it.

## Step 4 — Write the draft

Write the digest to:
```
research-log/weekly-[end-date].md
```

where `[end-date]` is today's date in YYYY-MM-DD format.

If the file already exists, append a `---` separator and the new draft below it rather
than overwriting.

## Step 5 — Confirm

Tell the user:
- The file written (path)
- The date range covered
- How many source files were read (e.g. "3 session files, 1 research-log entry")
- A reminder that it's a draft — edit freely before sharing or archiving
