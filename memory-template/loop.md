# Loop Maintenance Instructions

This file customizes what bare `/loop` does in this project.
Placed at `.claude/loop.md` — only affects bare `/loop` (ignored when you supply a prompt).
Edit it to match your workflow. Delete sections that don't apply.

---

## On each iteration

1. **PR health** — Check for open PRs on the current branch.
   - If CI is failing: diagnose and fix. Commit the fix and push.
   - If there are new review comments: address straightforward ones. Push.
   - Re-request review when CI is green.
   - If no open PR: check if the branch has commits not yet in a PR. Open one if so.

2. **Test health** — Run the test suite.
   - If anything is failing that wasn't failing at the start of this session: fix it before continuing other work.
   - Do not suppress or skip a failing test. Surface it if it can't be fixed.

3. **Branch hygiene** — If the branch is behind main/dev, rebase.

4. **Work in progress** — Continue the most recent unfinished task from the conversation.
   - If nothing is actively in progress: check `.claude/memory/progress.md` for the next "In progress" item.
   - If `plan.md` exists with unchecked tasks: continue the next unchecked task.

5. **Cleanup pass** (when nothing else is pending) — One pass over recently-changed files:
   - Remove TODO/FIXME comments that were added and then resolved
   - Remove debug artifacts (console.log, print statements)
   - Flag anything that looks unfinished but wasn't discussed

---

## Rules

- Do not start new features or tasks not already discussed in this conversation.
- Irreversible actions (push, delete, close PR) only if they continue something already authorized in this conversation.
- If genuinely blocked: surface the blocker clearly, stop. Do not work around it silently.
- Maximum one push per iteration unless CI requires a fix-and-repush cycle.
