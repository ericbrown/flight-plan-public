---
description: Stage, commit, push, create PR, update Linear with PR link. Full git workflow.
---

## Step 1 — Read git state

Run:
```
git remote -v
git branch --show-current
git status --short
git diff --stat HEAD
```

## Step 2 — Confirm push target

Show:
```
Remote: [URL from git remote -v]
Branch: [current branch]
Changed: [diff stat summary]
```

Say: "Push to [remote] on [branch]? (yes/no)"
Do not push until confirmed. This is a hard requirement — never skip.

## Step 3 — Stage and commit

```
git add -A
```

Write commit message:
- Imperative mood ("add X", "fix Y")
- ≤72 characters
- References plan.md Goal if available

```
git commit -m "[message]"
```

## Step 4 — Push

```
git push origin [branch]
```

## Step 5 — Create PR

Create PR with:
- **Title**: same as commit message
- **Body**:
  ```markdown
  ## Summary
  [plan.md Goal, or one-paragraph description]

  ## Changes
  [checked task list from plan.md]

  ## Verification
  All checks passing: typecheck, tests, lint, build.
  ```

## Step 6 — Update Linear with PR link

Find all Linear issue IDs in `plan.md` that have checked tasks (`- [x]`).

For each completed issue:
Spawn `linear-sync` subagent (via Task tool) with:
```
Operation: ADD_COMPLETION_COMMENT
issue_id: PROJ-123
summary: [what was implemented, one sentence per task]
pr_url: [PR URL]
```

**Do NOT change any issue status. Do NOT close anything.**

## Step 7 — Capture learnings

Ask: "Anything to add to CLAUDE.md? Corrections or patterns from this session?"

If yes: append to "Learned Patterns" in `~/.claude/CLAUDE.md` AND `.claude/memory/conventions.md`.

## Step 8 — Output

```
PR created: [url]
Linear: [N] issues updated with PR link (still open)

To sync lessons:
  cd ~/flight-plan && ./sync-lessons.sh
  git add CLAUDE.md && git commit -m "sync lessons" && git push
```
