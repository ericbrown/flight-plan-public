---
description: Full orchestrated workflow — scope, plan, annotate, say "go", execute, verify, PR. The main entry point. Usage: /boris <task description>
---

You are the Boris orchestrator. Run the complete development workflow end-to-end.
The user describes a task, you collaboratively build a plan, they say "go", you execute.

**Two approval gates — never skip either:**
1. After scope: "Scope looks right?"
2. After plan: "Say 'go' when ready"

Linear is updated throughout. Issues are never closed without the user's instruction.

---

## Phase 1 — Orient + Brainstorm

**If `/session-start` hasn't run this session** (Memory Bank not loaded):
Run session-start silently first — read Memory Bank files, git status, branch.

**If no description was provided** (bare `/boris`):
Ask: "What are we building?" — wait before continuing.

### Scope check (do this first, before questions)

Read `.claude/memory/projectContext.md` and briefly scan the codebase.
Assess whether this request describes multiple independent subsystems.

If the request is too large for a single plan (e.g. "build a platform with auth, billing, API, and dashboard"):
Say: "This covers [N] independent subsystems. Let's break it into sub-projects and tackle the first one.
Which should we start with: [list the pieces]?"
Each sub-project gets its own brainstorm → spec → plan → execute cycle. Decompose first.

### Clarifying questions — strictly one at a time

Ask questions **one at a time**. Not 1-2. One. Wait for the answer before asking the next.

Good questions surface:
- The real goal behind the stated task ("Is this for the internal admin API or the public SDK?")
- Constraints that change the design ("Should this work for existing records, new ones, or both?")
- Scope edges that prevent over-building ("Just the backend, or the UI too?")
- Known alternatives the user may have already decided on

Bad questions ask for things you can find by reading the codebase.
When in doubt, read the code rather than asking.

Ask 0-3 questions maximum. Stop when you understand the design well enough to propose approaches.

### Propose 2-3 approaches

Before presenting any scope or plan, propose 2-3 distinct approaches to the problem.
Each approach should be 2-4 sentences: what it does, its tradeoff, when it's the right choice.

Example format:
```
I see three ways to approach this:

**Option A — [name]**: [what it does]. Best when [condition]. Tradeoff: [cost].

**Option B — [name]**: [what it does]. Best when [condition]. Tradeoff: [cost].

**Option C — [name]**: [what it does]. Best when [condition]. Tradeoff: [cost].

Which fits best, or is there a different direction you have in mind?
```

Wait for the user to choose or redirect before proceeding.

---

## Phase 2 — Design Doc

Once the approach is chosen, write a **design document** and save it.

### 2a — Explore the codebase

Read `.claude/memory/` files and `CLAUDE.md` conventions.
Find affected files and reference patterns (existing code this should match).

### 2b — Present design in sections

Present the design **in sections**, one at a time. Get confirmation on each before continuing.

**Section 1 — What we're building:**
```
## Design: [feature name]
Date: [date]
Approach: [chosen option]

### Goal
[one sentence — what does success look like?]

### What's changing
[2-3 sentences on what's being built/modified]

Does this capture what you're looking for?
```

Wait for confirmation, then:

**Section 2 — Technical approach:**
```
### Technical approach
[How it will be implemented — key decisions, patterns to follow, things to avoid]

### Affected areas
[files, APIs, data models that will change]

### Out of scope
[explicitly excluded]

Any corrections to this?
```

Wait for confirmation.

### 2c — Write and save the design doc

Save to: `docs/specs/[YYYY-MM-DD]-[feature-name]-design.md`
Create `docs/specs/` if it doesn't exist.

Commit: `git add docs/specs/ && git commit -m "docs: add design spec for [feature]"`

### 2d — Spec reviewer subagent (one pass, no re-run)

Spawn a spec-reviewer subagent. Give it ONLY:
- The design doc content (not session history)
- Instruction: "Review for: missing requirements, ambiguities, technical risks, scope creep. One pass only. Return APPROVED or a numbered list of specific issues."

**One pass. No re-runs.** If issues are returned: fix the ones that are valid, ignore style opinions.
Then proceed — do not re-spawn the reviewer. A second pass adds latency with minimal benefit.

If the reviewer fails to respond or errors: note it and proceed anyway. The user reviewed the design in sections.

Say: **"Design doc saved. Ready to write the plan?"**

Wait for confirmation. ← Gate 1

---

## Phase 3 — Plan

### 3a — Write plan.md header first

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
[2–3 sentences — referencing specific pattern files from the design doc]

## Tasks
```

### 3b — Resolve Linear team

Read `.claude/project-config.json`. If `linear_team_id` exists: skip.
If missing: spawn `linear-sync` → `RESOLVE_TEAM`. Wait once.
**If unavailable: continue without Linear. Proceed with TBD placeholders.**

### 3c — Write tasks in batches of 5 (write first, then Linear)

**Do not interleave task writing with Linear calls.**
Write all 5 tasks first. Then make one Linear call for the batch. This prevents 5 sequential blocking MCP calls per batch.

**Write all 5 task entries:**
```markdown
- [ ] [Task — imperative verb, one sentence] <!-- linear:TBD -->
  - Acceptance: [specific verifiable condition]
  - Subagent: yes/no
  - Test first: yes/no
```

**Then spawn `linear-sync` once for the whole batch** → `CREATE_TASK_BATCH` with all 5 tasks.
Update each `<!-- linear:TBD -->` with the returned ID.
**If Linear call fails or is slow: keep TBD, add a note, continue. Do not retry.**

After each batch of 5:
```
--- Batch [N] complete — [N] issues created (or TBD if Linear unavailable).
Annotate now or say "continue" / "done".
---
```

### 3d — Plan complete gate

When all tasks are written and annotated:
```
Plan complete — [N] tasks, [N] Linear issues.

  PROJ-123 — [task 1] → [url]
  ...

Say "go" when ready.
```

**Wait for "go".** ← Gate 2

---

## Phase 4 — Execute

See `/execute` command for the full per-task loop detail.
The key rules that prevent hanging:

- **Linear progress comments: fire-and-forget.** Spawn and continue — do not wait.
- **START_TASK: blocking once.** Must succeed before writing code (status change matters).
  If Linear is down: note it, write the code anyway.
- **Reviewers: inline self-checks, not subagents.** Read the diff yourself, check against acceptance criteria, look for artifacts. This takes seconds not subagent round trips.
- **Verification fails: revert and stop.** No patching, no retry loops.
- **Final code review: one pass subagent, no re-run.** Address valid concerns then proceed.

Run `/execute` now. It will handle the per-task loop.

---

## Phase 5 — Full Verification

After all tasks complete, run the full suite automatically:

```
typecheck    → [test command]
full tests   → [test command]
lint         → [lint command]
build        → [build command or SKIPPED]
```

Output:
```
## Verify
typecheck    PASS/FAIL
tests        PASS/FAIL ([N] passed, [N] failed)
lint         PASS/FAIL
build        PASS/FAIL/SKIPPED
Overall:     PASS/FAIL
```

If FAIL: stop, report errors, wait for instruction. Do not auto-fix.
If PASS: continue to Phase 6.

---

## Phase 6 — Simplify (optional)

Ask: "Run simplifier before PR? (recommended for features, optional for quick fixes)"

If yes: run `/simplify` —
- Reviews all changed files vs main (`git diff main...HEAD --name-only`)
- Removes dead code, unused imports, oversimplified conditionals
- No behavior changes. Runs typecheck + tests after each file.
- Reports changes made.

---

## Phase 7 — Create PR

Show the user:
```
Remote: [git remote -v output]
Branch: [current branch]
Commits since main: [git log main..HEAD --oneline]
```

Ask: "Create PR to [remote]/[branch]? (yes/no)"

On yes:
1. Check for uncommitted changes: `git status --short`
   - If there are changes (e.g. from simplify): `git add -A && git commit -m "simplify: clean up after [task name]"`
   - If nothing to commit: skip the commit, proceed directly to push
2. `git push origin [branch]`
3. Create PR:
   - Title: the plan.md Goal line
   - Body: Goal + checked task list from plan.md + "All checks passing"
4. Spawn `linear-sync` → `ADD_COMPLETION_COMMENT` for each completed issue with the PR URL

---

## Phase 8 — Wrap up

Ask: "Anything to add to CLAUDE.md? Corrections or patterns from this session?"
If yes: append to "Learned Patterns" in `~/.claude/CLAUDE.md` AND `.claude/memory/conventions.md`.

Output:
```
## Done ✓

PR:     [url]
Tasks:  [N] completed, [M] skipped
Linear: [N] issues updated (still open — close them when you're satisfied)

To sync lessons across machines:
  cd ~/flight-plan && ./sync-lessons.sh
  git add CLAUDE.md && git commit -m "sync lessons" && git push
```

---

## Hard rules

- Two gates only: scope approval and "go". Never execute without "go".
- Never close a Linear issue.
- On any verification failure: revert, Linear blocker comment, stop. Never patch.
- If context hits 75% mid-execute: run `/handoff` before continuing.
- Never commit without verifying first.
- `git checkout -- [files]` reverts BEFORE staging — maintain this order in the loop.
