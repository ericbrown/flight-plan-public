---
description: "Plan stage 2: write plan.md in batches of 5, create Linear issues per batch (not per task). Annotation gate before /execute."
---

Given the approved scope and design doc from boris Phase 2, write `plan.md` and create Linear issues.

## Anti-hang rule

**Write all 5 tasks in a batch first. Then create all Linear issues for the batch in one call.**
Never interleave task-writing with Linear calls — that creates 5 sequential blocking MCP calls per batch.
One batch → write 5 → one linear-sync call for all 5 → update plan.md with IDs → stop for annotation.

---

## Step 1 — Resolve Linear team (once per project)

Read `.claude/project-config.json`. If `linear_team_id` exists: skip this step entirely.

If missing: spawn `linear-sync` subagent → `RESOLVE_TEAM`. Wait. This happens once.
**If linear-sync is unavailable: write `"linear_team_id": "UNAVAILABLE"` and continue without Linear.**
Tasks will be written without issue IDs — add them manually later if needed.

---

## Step 2 — Write plan.md header

Create `plan.md`:
```markdown
# Plan: [task name]
Created: [date]
Branch: [current branch]
Design doc: docs/specs/[filename]-design.md
Status: DRAFT

## Goal
[one sentence — what does success look like?]

## Approach
[2–3 sentences referencing pattern files from the design doc]

## Tasks
```

---

## Step 3 — Batch loop (write 5, then Linear, then stop)

### 3a — Write all 5 task entries first

Write all 5 task entries into plan.md with placeholder IDs:
```markdown
- [ ] [Task — one sentence, imperative verb] <!-- linear:TBD -->
  - Acceptance: [specific verifiable condition — "test passes" not "it works"]
  - Subagent: yes/no
  - Test first: yes/no
```

### 3b — Create all 5 Linear issues in one subagent call

Spawn `linear-sync` subagent once for the whole batch:
```
Operation: CREATE_TASK_BATCH
tasks: [
  { title, acceptance_criteria, plan_goal, branch },
  { title, acceptance_criteria, plan_goal, branch },
  ... (all 5)
]
```

**If linear-sync fails or is slow (>30s): continue with TBD placeholders. Do not retry.**
Write a note at the top of plan.md: `<!-- Linear: [N] issues pending — create manually or retry /linear-update plan -->`

### 3c — Update plan.md with returned issue IDs

Replace each `<!-- linear:TBD -->` with the returned `<!-- linear:PROJ-123 → url -->`.

### 3d — Stop for annotation

Output:
```
--- Batch [N] complete — [N] tasks written, [N] Linear issues created.
Add annotations now: <!-- skip -->, <!-- use X instead -->, <!-- do this last -->
Say "continue" for more tasks or "done" if this covers it.
---
```

Wait for response before writing more tasks.

---

## Step 4 — Generate ACCEPTANCE.md

After all tasks are written and annotated, create `ACCEPTANCE.md`:

```markdown
# Acceptance Criteria
Generated: [date]
Branch: [current branch]

Use as the anchor for a full-plan /goal:
`/goal all criteria in ACCEPTANCE.md are satisfied as shown in this conversation — or stop after [N*6] turns`

---

## [Task 1 — description]
- [ ] [acceptance criterion verbatim from plan.md task 1]

## [Task 2 — description]
- [ ] [acceptance criterion verbatim from plan.md task 2]

...
```

This file gives `/goal` a multi-dimensional stopping condition without cramming everything into one command. Claude walks through each criterion and shows proof; the evaluator checks the walkthrough.

---

## Step 5 — Completion gate

When all tasks are written and annotated:
```
plan.md complete — [N] tasks, [N] Linear issues.
ACCEPTANCE.md written — use with /goal for autonomous execution.

  PROJ-123 — [task 1] → [url]
  PROJ-124 — [task 2] → [url]
  ...

Options:
  /execute          — task-by-task with verification gates (default)
  /goal all criteria in ACCEPTANCE.md are satisfied... — fully autonomous run
  Say "go" in /boris to proceed with /execute
```

Do NOT proceed to execute. User must trigger it.

---

## Task quality rules

- One focused work block — completable without interruption
- Acceptance: verifiable ("endpoint returns 200", "test passes") not vague ("it works")
- Subagent: yes for isolated, side-effectful, or parallelizable work
- Test first: yes by default for any new function, class, or endpoint
