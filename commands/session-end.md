---
description: Save Memory Bank, write the in-repo research log, update README, post Linear session summaries, capture learnings. Run at end of every session.
---

Close out the session cleanly. Execute each step in order.

## Step 1 — Cognitive Briefing

Before writing anything to disk, synthesize in your head:
- What was the main goal this session?
- What approach was taken and why?
- What failed or was abandoned, and why?
- What is the current state — what works, what's incomplete?
- What should the next session do first?
- Any open questions or deferred decisions?

This becomes the `activeContext.md` content. Capture THINKING, not just files changed.

---

## Step 2 — Update Memory Bank

Write or update each file in `.claude/memory/`:

**`activeContext.md`** — Replace entirely (this is the "latest state" snapshot for session-start):
```markdown
# Active Context
Last updated: [date]

## Session goal
[one sentence]

## Approach taken
[2–3 sentences]

## Current state
[what works, what's incomplete, what's broken]

## What failed / was abandoned
[specific — future Claude needs this to avoid repeating the same mistakes]

## Resume prompt
[One paragraph written to a fresh Claude instance: "You're working on X. Last thing
that happened was Y. Your next step is Z. Watch out for W."]
```

**`.claude/memory/sessions/[YYYY-MM-DD-HHmm].md`** — Create a NEW dated file (never overwrite previous sessions):
```markdown
# Session — [date and time]

## Goal
[one sentence]

## What happened
[2-5 bullets: what was built, fixed, or decided]

## What failed / was abandoned
[specific — prevents future sessions from retrying dead ends]

## Decisions made
[architectural or approach decisions with rationale]

## Resume prompt
[same as activeContext — written for a fresh Claude instance]
```
This preserves a complete history of every session. `activeContext.md` is the "latest" pointer; the sessions directory is the full log.

**`progress.md`** — Update status. Move completed items to the Completed section with dates (never delete them):
```markdown
## Completed
- [x] [task] — [one-line result] (completed [date])

## In progress
- [ ] [task] — [current state]

## Up next
- [ ] [task]
```
Items move DOWN the file as they progress: Up next → In progress → Completed. Never remove completed items — they're the project's work history.

**`sessionHistory.md`** — Append (never replace):
```
[date] — [one paragraph: what was done, outcome, what's next]
```

**`conventions.md`** — For every user correction this session, add:
```markdown
### [Plain-language pattern name]
[What happened. What was wrong. What the correct behavior is.]
```
Then evaluate: universal or project-specific?
Universal → also add to "Learned Patterns" in `~/.claude/CLAUDE.md`.

**CLAUDE.md length check:**
```bash
wc -l ~/.claude/CLAUDE.md 2>/dev/null | awk '{print $1}'
```
- Under 400 lines: fine.
- 400–800 lines: note it. "CLAUDE.md is [N] lines — consider pruning rules Claude already follows naturally."
- Over 800 lines: hard warning. "CLAUDE.md is [N] lines — instruction-following degrades significantly above 800 lines. Prune to under 400."

**`decisionLog.md`** — For every significant architectural or approach decision made this session, append:
```markdown
## [date] — [decision title]
**Context**: [why this decision was needed]
**Decision**: [what was decided]
**Rationale**: [why this option over alternatives]
**Alternatives**: [what else was considered and rejected]
```
Skip trivial decisions. Log only things a future Claude instance would need to understand "why is it built this way?"

---

## Step 2b — Update the research log (in-repo, travels via GitHub)

The Memory Bank (Step 2) lives in `.claude/` and never leaves the machine. On a machine that can't reach your central notes store directly (e.g. over a VPN/private network), the **research log is how the session's thinking gets back** — it's tracked in the repo, pushed to GitHub, and pulled into wherever you aggregate (your notes system, an activity-log MCP, etc.).

Decide whether this repo keeps a research log:
- If a `research-log/` directory already exists → write the entry (below).
- If it does NOT exist → ask the user once: *"No research-log/ here yet. Start a research notebook for this project? It will be committed and pushed to this repo."* On **yes**, create the directory and proceed. On **no**, skip the rest of this step for this session.

Do **not** auto-create the directory silently. `/session-end` can run in repos that aren't yours (OSS, client work), and the notebook gets committed and pushed — so creation is always a deliberate yes.

Then write the day's entry using the same cognitive briefing from Step 1.

Create or update `research-log/YYYY-MM-DD.md` — one file per day. If it already exists from an earlier session today, **extend it**, don't overwrite. Use this exact schema (a downstream aggregator can parse these headings):

```markdown
# YYYY-MM-DD (Weekday)

## Context going in
Where things stood at the start of the day.

## What we did
The narrative of the work. Use `### Morning/Afternoon/Evening: topic` subsections for distinct threads. Include commit hashes, Linear ticket IDs (with links), decisions and their rationale, alternatives considered and rejected, and any corrections the user made.

## What we found
The findings and insights — the durable thinking, not just activity. This is the part GitHub commits can't give you.

## What we changed
Concrete changes: files, scripts, tickets, commits.

## What we moved on to
Transitions, what's running in the background, what's next.

## Open / parked
Open questions and parked items.
```

Capture **thinking** (findings, what was ruled out, open questions), not a commit list — GitHub already has the commits.

On the last working day of the week (or when the user asks), also write `research-log/weekly-YYYY-MM-DD.md` (date = that day) synthesizing the week:

```markdown
# Week of YYYY-MM-DD (Weekday–Weekday)

## Headline
## What landed (production / deployment changes)
## What we learned
## What we built (scaffolded but not shipped)
## What we parked / open questions
## Cross-references
### Linear
### Design docs
### Key commits
## Where next week opens
```

Commit and push so it reaches GitHub (the aggregator pulls from `main` and `dev`):
`git add research-log/ && git commit -m "research-log: YYYY-MM-DD" && git push`

---

## Step 3 — Update Linear issues

Find all Linear issue IDs in `plan.md` (format: `<!-- linear:PROJ-123 -->`).
Also check `.claude/task-context.md` for any additional issue IDs from this branch.

For each issue touched this session (started, in-progress, or failed):
Spawn `linear-sync` subagent (via Task tool) with:
```
Operation: ADD_SESSION_COMMENT
issue_id: PROJ-123
session_goal: [from Step 1]
current_state: [from Step 1]
resume_prompt: [from Step 1 resume prompt]
```

**Do NOT change any issue status. Issues stay In Progress until you close them.**

---

## Step 4 — Update branch task context

If on a feature branch, update `.claude/task-context.md`:
```markdown
# Task Context: [branch]
Last updated: [date]

## Objective
[one sentence]

## Plan
[paste plan.md Tasks section — checked + unchecked]

## Key decisions
[architectural decisions made this session]

## Current progress
[what's done, what's next]

## Resume here
[same resume prompt as activeContext.md — written to a fresh Claude instance]
```

Stage and commit:
`git add .claude/task-context.md && git commit -m "chore: update task context [date]"`

---

## Step 5 — Update README

Check if any of these changed this session:
- New features or commands added
- Configuration or setup steps changed
- New dependencies added
- Architecture changed

If yes: update `README.md`. Commit alongside the memory update.

---

## Step 6 — Log session to the activity-log MCP (optional)

If an activity-log MCP server is connected (tool `mcp__activity-log__log_activity`
is available — see the README's "Activity-log MCP integration" section),
call it now with a summary of this session:

```
mcp__activity-log__log_activity(
  project="[project name from projectContext.md]",
  activity="Session end: [one-sentence summary of what was done]",
  activity_type="[code|decision|research|debug — whichever best fits]",
  details="[2-3 sentences: what was built/fixed/decided, current state, what's next]",
  files_changed=["[key files changed this session]"],
  decisions=["[any significant decisions made]"]
)
```

This keeps a central activity log informed of work done across all Claude
sessions and machines. Skip silently if `mcp__activity-log__log_activity` is not
available in this session.

---

## Step 7 — Verify nothing uncommitted

Run `git status`. If there are uncommitted changes:
- WIP code → offer to stash: `git stash push -m "wip: session end [date]"`
- Complete changes → offer to commit
- Memory/context files → stage and commit them

---

## Step 8 — Session summary

Output:
```
## Session End

Memory Bank:   saved (activeContext, progress, sessionHistory, conventions)
Linear:        session-end comments added to [N] issues (still open — close when ready)
Activity MCP:  logged / "not connected"
Conventions:   [N] new / "none"
README:        updated / "no changes needed"
Branch ctx:    saved + committed / "not on feature branch"
Git:           clean / [N] changes stashed or committed

Next session: /session-start
```

---

## Step 9 — Lesson sync reminder

Output:
```
To sync learned patterns across machines:
  cd ~/flight-plan
  ./sync-lessons.sh
  git add CLAUDE.md && git commit -m "sync lessons" && git push
```
