---
description: Cognitive briefing — saves full mental model for seamless session handoff
---

Generate a complete cognitive briefing. Save it to `activeContext.md` and
`.claude/task-context.md` (if on a feature branch).

The briefing captures THINKING, not just DOING. A list of changed files is not a handoff.

## Write to .claude/memory/activeContext.md

```markdown
# Active Context — Handoff
Created: [date]

## What we're doing and why
[2-3 sentences on the goal and why this approach was chosen]

## Where we are right now
[Current state: what works, what's half-done, what's broken]

## What was tried and failed
[Be specific. What approaches failed and why. Future Claude needs this to avoid repeating.]

## Active hypotheses
[Any open theories about why something isn't working]

## The plan from here
[What the next concrete steps are, in order]

## Resume prompt
[A single paragraph that a fresh Claude instance can read to pick up exactly here.
Write it in second person: "You're working on X. The last thing that happened was Y.
Your next step is Z. Watch out for W."]
```

Output: "Handoff saved to activeContext.md. Context preserved — safe to start a new session."
