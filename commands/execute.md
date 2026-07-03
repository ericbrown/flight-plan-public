---
description: "Plan stage 3: execute annotated plan.md one task at a time using subagents. Updates Linear throughout. Never closes issues."
---

Read `plan.md` fully, including all annotations (`<!-- ... -->`).
Each task has a Linear issue ID as `<!-- linear:PROJ-123 -->`.

## Anti-hang rules (read first)

These rules prevent the workflow from stalling. They are not optional.

1. **Linear progress comments are fire-and-forget.** Spawn the subagent and continue immediately — do not wait for confirmation. Only START_TASK and BLOCKER_COMMENT are blocking (they change status).
2. **Reviewer subagents get one pass. No re-runs.** If a reviewer returns issues, fix them once. Do not re-spawn the reviewer. Trust your fix and move on.
3. **All reviewer subagents receive only the diff, not the session.** Kept small = fast. Pass `git diff HEAD~1` for the specific task files, not the whole session history.
4. **If any subagent fails to return in one tool call, continue without it.** Log "subagent unavailable" in plan.md and proceed. Never let a non-critical subagent block implementation.
5. **Linear MCP unavailable? Skip all Linear calls, note it, continue.** The code must still get written.

---

## Pre-flight check

1. Confirm `plan.md` exists with unchecked tasks and Linear issue IDs
2. Read commands from `.claude/project-config.json` (test, typecheck, lint)
   If missing: check CLAUDE.md. If neither: ask once, then proceed.
3. Output: `"Executing [N] tasks. Skipping [M] annotated. Starting: [task 1] (PROJ-123)"`

---

## Goal conditions (output before starting)

After the pre-flight check, emit ready-to-use `/goal` conditions — one for the full plan and one per task. This lets the user run the plan autonomously with `/goal` instead of following each step.

Output:
```
## /goal conditions — use these to run autonomously

Full plan (all tasks):
/goal all tasks in plan.md are checked [x] and the full verification suite passes — or stop after [N*6] turns

Per task:
  Task 1 — [description]:
  /goal [acceptance criteria from task 1] — or stop after 10 turns

  Task 2 — [description]:
  /goal [acceptance criteria from task 2] — or stop after 10 turns
  ...

Or run /execute to proceed task-by-task with verification gates.
```

Then continue with the per-task loop below (do not wait for a response — just proceed unless the user says stop).

---

## Per-task loop

For each unchecked task in order:

### 1 — Read task and annotations

Extract: description, acceptance criteria, Linear ID, subagent flag, test-first flag, annotations.

**If `<!-- skip -->`:**
Mark `- [~]` in plan.md.
Fire-and-forget: spawn `linear-sync` → `ADD_PROGRESS_COMMENT` "Descoped per annotation." (don't wait)
Move to next task.

---

### 2 — Move to In Progress in Linear (blocking — status change)

Spawn `linear-sync` subagent → `START_TASK`:
- issue_id from `<!-- linear:PROJ-123 -->`
- task_approach: 1–2 sentence implementation summary

**If linear-sync fails or times out: note "Linear unavailable" in plan.md, continue anyway.**
The code gets written regardless of whether Linear responds.

---

### 3 — If `subagent: yes`

Spawn a dedicated implementation subagent with:
- Task description + acceptance criteria
- The Approach section from plan.md
- Linear issue ID

Fire-and-forget: spawn `linear-sync` → `ADD_PROGRESS_COMMENT` "Delegated to subagent." (don't wait)
Wait for the **implementation** subagent to complete (this one is blocking — we need the code).

---

### 4 — If `test first: yes`

Write the failing test. Run it. Confirm it fails with a meaningful error (not a syntax error).
Fire-and-forget: spawn `linear-sync` → `ADD_PROGRESS_COMMENT` "Test red: [name]. Implementing." (don't wait)
Do not write implementation until test is confirmed failing.

---

### 5 — Implement

Write the implementation. Reference the Approach section pattern files.
Stay within the affected files from the design spec scope.

Fire-and-forget: spawn `linear-sync` → `ADD_PROGRESS_COMMENT` "Impl written. Running verification." (don't wait)

---

### 6 — Verify (do NOT stage files yet)

Run in order — stop on first hard failure:
1. typecheck
2. tests scoped to changed files
3. lint

---

### 7a — Verification passes ✓

**Quick spec check (inline, no subagent):**
Read the task description and acceptance criteria. Read your changes.
Ask yourself: "Does this implementation satisfy the acceptance criteria as written?"
If no: fix it before committing. This is a self-check, not a subagent.

**Quick quality check (inline, no subagent):**
Scan the diff for: debug artifacts (console.log, print, TODO), unused imports, obvious naming issues.
Fix anything found. This takes 30 seconds, not a subagent round trip.

**Commit:**
- Check box: `- [x]` in plan.md
- `git add [changed files] && git commit -m "[task description]"`
- Fire-and-forget: spawn `linear-sync` → `ADD_PROGRESS_COMMENT` "Committed: [hash]." (don't wait)
- Leave issue In Progress. Move to next task.

---

### 7b — Verification fails ✗

- `git checkout -- [changed files]` ← safe because nothing is staged yet
- Add to plan.md: `> FAILED: [exact error]. Reverted.`
- **Blocking:** spawn `linear-sync` → `ADD_BLOCKER_COMMENT` with the exact error. (wait — this is important)
- **STOP. Report to user. Do not patch. Wait for re-plan.**

---

### Record architectural decisions

If a significant architectural decision was made during this task:
Append to `.claude/memory/decisionLog.md`:
```
## [date] — [decision title]
Context: [why] | Decision: [what] | Rationale: [why this] | Alternatives: [what else]
```

---

## Completion

When all tasks are checked or skipped:

**Final code review (one pass, no re-run, non-blocking continuation):**
Spawn a reviewer subagent. Give it ONLY `git diff main...HEAD` output — not session history.
Instruction: "Review for overall coherence and obvious issues only. One pass. Return APPROVED or a bullet list of specific concerns."
If concerns: address the ones you agree with. Then continue regardless — do not re-spawn.

Run full verification:
typecheck → full test suite → lint → build

Output:
```
## Execute complete

Completed: [N] | Skipped: [M] | Failed: [N]
Code review: APPROVED / addressed [N] concerns

Linear:
  PROJ-123 — In Progress + progress comments
  PROJ-124 — In Progress + progress comments
  (fire-and-forget comments may still be in flight)

Verification:
  typecheck  PASS/FAIL
  tests      PASS/FAIL ([N] passed)
  lint       PASS/FAIL
  build      PASS/FAIL/SKIPPED

Overall: PASS → invoke finishing-a-branch skill or /commit-push-pr
         FAIL → fix before proceeding
```

**Issues are still open. Never close them.**
