# Session Boot (MANDATORY)

Every session MUST begin with these two actions before doing anything else:

1. **Load context**: Run `/session-start` silently — reads `.claude/memory/` files, git status, branch, recent commits. Presents a brief summary.
2. **Enter plan mode**: After the summary, stay in plan mode until the user provides a task AND approves a plan. Do NOT write any code without an approved plan.

If the user's first message is a task description, load context silently and present a plan for that task (combining steps 1 and 2 into one response).
If it's a greeting or question, load context first then respond normally.

## Auto-trigger map (run before EVERY response — no exceptions)

Match the user's message against this table. If it matches, invoke the skill immediately — do not ask, do not wait, just run it and say so in one line.

| If the message... | Invoke |
|-------------------|--------|
| Describes something to build, add, implement, create, or write (code/feature) | `/boris` workflow |
| Says "fix", "broken", "error", "failing", "bug", "doesn't work", "crash" | `/systematic-debugging` |
| Says "refactor", "clean up", "simplify", "reorganize" (code) | `/boris` workflow |
| Says "add tests", "test coverage", "write tests for" | `/tdd` |
| Says "done", "finished", "that's it for today", "wrap up", "end session", "goodbye" | `/session-end` |
| All tasks in progress.md are complete and a PR is needed | `/finishing-a-branch` |

**The command name never needs to be said.** Detect intent → invoke → proceed.

Do not preface with "I'll run boris now" and then describe what boris does. Just run it.

The `/boris` command is a shortcut to the same behavior — both paths are identical.

---

# User Preferences

- Only look at files, repos, and resources the user explicitly links or points to.
- Do not assume — ask one focused question if something is unclear.
- Be direct and concise. No unnecessary preamble.
- When a plan is ready, present it cleanly with a clear gate before executing.

---

# Linear Integration (MANDATORY)

Linear is the source of truth for all development work. These rules are non-negotiable:

- **Every piece of work gets a Linear issue.** If you start working on something and no issue exists, create one immediately in the correct project before writing code.
- **Move to In Progress** the moment you start working on a task. Not after. Not when you're halfway done. When you start.
- **Document progress as comments**, not by editing the original description/summary. The description is the spec; comments are the work log. Add comments at each meaningful stage: investigation started, approach chosen, implementation in progress, tests written, verified, PR created.
- **Mark as Done** when the work is complete and verified. Don't leave issues in progress after finishing.
- **Be as detailed as possible.** Linear issues should tell the full story: what was done, why, what was tried, what worked. A future reader should understand the entire arc from the issue alone.
- **Issues created** during `/plan-tasks` — one per task, via `linear-sync` subagent
- **Session summary** added by `/session-end`
- Linear team/project ID saved to `.claude/project-config.json` after first use
- Use `/linear-update` for ad-hoc comments mid-session

---

# Quick Reference

```
# The main entry point
/boris <task>         # Full workflow: plan → annotate → say "go" → execute → verify → PR

# Session
/session-start        # Load Memory Bank, orient, enter plan mode
/session-end          # Save context, update README, sync Linear, remind about lessons

# Planning (3-stage pipeline)
/plan-context         # Stage 1: scope + affected files (human approval gate)
/plan-tasks           # Stage 2: tasks in batches of 5, Linear issues created, annotation gate
/execute              # Stage 3: subagent per task, Linear updated throughout

# Verification & quality
/verify               # Tests, types, lint, build — full suite
/test-and-fix         # Run tests, fix failures iteratively until green
/simplify             # Code-simplifier subagent — clean up after implementation
/review-changes       # Read-only review of uncommitted changes before committing

# Git workflow
/task-branch <name>   # Create feature branch + task context for cross-machine handoff
/task-done            # Verify, PR, remove task context, update Memory Bank
/commit-push-pr       # Stage, commit, push, create PR
/checkpoint [name]    # Create named git tag save point
/rollback [target]    # Restore a checkpoint or go back N commits
/undo                 # Revert last Claude-made commit safely

# Context & memory
/context              # Show context window usage + Memory Bank status
/memory-init          # Initialize Memory Bank for a new project (run once per project)
/handoff              # Cognitive briefing — saves mental model for cross-session handoff

# Mode switching (Boris-style)
/mode architect       # Read-only design mode — no file edits
/mode code            # Full implementation mode (default)
/mode debug           # Investigation mode — limited writes, hypothesis-driven
/mode review          # Strictly read-only code review
/mode audit           # Security scanning with logging

# Linear
/linear-update              # Add progress comment to current task's issue
/linear-update <PROJ-123>   # Add comment to a specific issue
/linear-update plan         # Push revised plan.md to all issues in this plan

# Skills (auto-trigger — no command needed)
# using-workflow           → activates on any "let's build X", "add Y", "fix Z"
# tdd                      → activates on new function/feature implementation  
# systematic-debugging     → activates on test failures or build errors
# verification-before-comp → activates before marking any task done
# finishing-a-branch       → activates when all tasks complete
# worktrees                → activates when parallel sessions are in flight
```

---

# Core Workflow Principles

## 1. Plan First, Always (Boris)
- Enter plan mode for ANY task with 3+ steps or any architectural decision.
- If something goes sideways mid-execution: STOP, revert to last good commit, re-plan.
  Never patch a bad approach — always revert and re-scope.
- Annotate `plan.md` before `/execute`. Inline comments steer the architecture.
- A good plan is worth 10x the time it takes. The model can usually 1-shot from a good plan.

## 2. The 3-Stage Plan Pipeline (fixes superpowers hang)
Never write an entire plan in one pass. Always use the 3-stage pipeline:
1. `/plan-context` — scope + affected files only. Bounded read. Human approval gate.
2. `/plan-tasks` — tasks in batches of 5 with stop signal after each batch. Human annotation gate.
3. `/execute` — reads annotated plan.md, one subagent per task, human never needs to re-prompt.

The hang in superpowers' `/write-plan` was from trying to generate everything unbounded.
A batch of 5 tasks always terminates. An entire plan sometimes doesn't.

## 3. Subagent Strategy (Boris)
- Use subagents to keep the main context window clean and long sessions sustainable.
- One focused task per subagent.
- Specialist subagents: `linear-sync`, `verify-app`, `code-simplifier`, `code-architect`, `test-writer`.
- Offload Linear updates to the `linear-sync` subagent — don't handle MCP calls inline.
- Run multiple subagents in parallel when tasks are independent.

## 4. Self-Improvement Loop (Boris)
- After ANY user correction: update `.claude/memory/conventions.md` immediately.
- Evaluate universality: is this project-specific or cross-project?
  - Universal → also add to "Learned Patterns" below.
  - Project-specific → stays in `.claude/memory/conventions.md` only.
- Review conventions at session start — especially after multi-day gaps.
- Update CLAUDE.md at session-end via the `@.claude` pattern: tag learnings directly.

## 5. Git Workflow (Boris)
This is how we use Git on every project. Branch model: `main` ← (optional `staging`) ← `dev` ← `<user>/<feature>`. Full playbook in `skills/git-workflow.md` — read it for branching, merging, and conflict procedure.

- **ALL work on a feature branch off `dev`.** Never commit directly to `dev` or `main`. Hard-sync before branching: `git fetch origin && git checkout dev && git reset --hard origin/dev && git checkout -b <user>/<name>`.
- **Always open a PR (feature → `dev`).** Never merge directly without one. PRs explain what changed, why, and how to test it. Commits are descriptive, not "fix stuff."
- **Never squash. `gh pr merge --merge` only.** Squash destroys history.
- **After merge:** `git checkout dev && git pull`, then branch the next task off updated `dev`. Never push to a branch after its PR is merged.
- **Conflicts:** `git merge origin/dev` into the branch. Never rebase a PR branch, never force-push.
- Always run `git remote -v` before pushing — confirm the exact remote and branch.
- Use `/checkpoint` before any risky operation (reset, rebase, migration).
- `dev` → `main` is a periodic sync PR once a batch is stable.
- Every feature branch gets a committed `.claude/task-context.md` for cross-machine handoffs.

## 6. Verification Gate (Boris)
- Never mark a task complete without proving it works.
- Verification order: typecheck first (fast), then tests (scoped), then lint, then full build.
- Invoke the `verify` command for end-to-end checks before any PR.
- Ask yourself: "Would a staff engineer approve this PR without changes?"

## 7. Context Guardian (Boris)
- At ~60% context: proactively say "Context is getting full — want me to run `/handoff`?"
- At ~75% context: auto-run `/handoff` without asking. Save to `activeContext.md`.
- Saving the handoff briefing is MORE important than finishing the current subtask.
- The briefing captures THINKING (why, what failed, what to try next) not just doing.

## 8. Mode System (Boris)
- `/mode architect` — design phase, read-only, no file edits
- `/mode code` — default, full implementation
- `/mode debug` — investigation only, hypothesis-driven, minimal writes
- `/mode review` — strict read-only, no writes of any kind
- `/mode audit` — security scanning, every action logged to audit.log

## 9. Parallel Fleet (Boris)
- Run 3–5 Claude Code sessions in parallel using separate git worktrees.
- Number terminal tabs: tab 1 = main feature, tab 2 = tests/verify, tab 3 = docs/other.
- Use system notifications to know when a session needs input.
- Each worktree: `~/[repo-name]-[N]` convention (e.g. `~/<project>-2`, `~/<project>-3`).
- Each session gets its own branch + task context — no conflicts, no stashing.
- See the `worktrees` skill for setup commands.

## 10. Demand Elegance (Boris)
- For non-trivial changes: pause and ask "is there a more elegant solution?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution."
- Skip this for simple, obvious changes — don't over-engineer.
- Reference existing patterns in the codebase before inventing new ones.

## 11. Autonomous Bug Fixing (Boris)
- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them without prompting.
- Go fix failing CI tests without being told how. That's what the `systematic-debugging` skill is for.

---

# Memory Bank (Persistent Context)

Per-project memory lives at `.claude/memory/` — run `/memory-init` once per project:
- `projectContext.md` — What this project is, architecture, stack, key entry points
- `activeContext.md` — Current session state: goal, approach, what failed, resume prompt
- `progress.md` — Task tracking: done / in progress / up next
- `decisionLog.md` — Architecture decisions with rationale and alternatives
- `conventions.md` — Project-specific corrections and learned patterns
- `sessionHistory.md` — Rolling session summaries (append-only)

Branch-level context at `.claude/task-context.md` (committed to git):
- Created by `/task-branch`, updated by `/session-end`, removed by `/task-done`
- Cross-machine handoff: `git pull` on any machine → Claude has full context
- Contains: objective, plan, key decisions, current progress, resume prompt

---

# Learned Patterns

Universal lessons promoted from project-level conventions. Apply across all projects.

### Always verify push target before any git push
Run `git remote -v` before every push. Multiple repos in flight simultaneously
means "push this" is always ambiguous. Show the remote URL and get a confirm
before `git push`.

### Commit AND push source files at phase boundaries
Before deploying or moving to the next phase: commit + push to remote. Work on a
remote machine is lost if the branch isn't pushed. Don't assume a file
is in the repo just because it's on disk.

### Keep slash command backtick expressions pipe-free
Claude Code flags `!` inline bash inside `.claude/commands/*.md` as "multiple operations"
if they contain pipes, redirects, or quoted strings. Use git's native flags instead:
`git log --oneline -10` not `git log | head -10`. Let commands fail naturally — no `2>/dev/null`.

### Update README on session-end, not just Memory Bank
On `/session-end`, update README.md alongside Memory Bank files. Memory Bank is for
Claude; README is for humans. Both must stay in sync after any meaningful session.

### Always check SDK type signatures, not just API docs
SDK public types often differ from raw API field names (camelCase in SDK vs snake_case in
API). Read the `.d.ts` or Python type stubs. Silent `undefined` or `None` values hide here.

### Validate computed values on a small sample before large backfills
When computing new metrics across many records, test on 5–10 samples first. Coordinate
system conventions, wrapping at ±180°, and off-by-one errors produce technically correct
but semantically wrong results that silently corrupt an entire dataset.

### Separate products need separate repos from day one
If it has its own Dockerfile, deployment config, DB migrations, and test suite — it is a
separate product. Ask about repo strategy before writing the first line of code. Untangling
two products from one repo later is expensive.

### Config files must be loaded by the code that creates work items
A config file is dead code if the consumer uses a hardcoded list instead. Verify
end-to-end that config values actually reach the consumer — trace the data path.

### Cut the feature branch BEFORE writing the design doc, not after the plan
Design doc commits go on the feature branch from the first commit. Committing to main
then cherry-picking later is painful and risky if already pushed. Use `/design-doc <slug>`
to scaffold `docs/specs/YYYY-MM-DD-<slug>-design.md` directly on the branch.
