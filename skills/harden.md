---
name: harden
description: Use when the user has an existing thesis, argument, claim, draft, or plan and wants it stress-tested before it gets used — "is this defensible?", "poke holes in this", "harden this argument", "make this bulletproof before I ship/pitch/decide". Verify/revise, not fresh planning.
---

# Harden

`/verify` checks that code works. `/harden` checks that an idea holds up.

Use it when a thesis, argument, draft, or plan already exists and needs a bounded verify-and-revise pass before it's used in a PR, a pitch, a decision, or a doc.

## When to activate

- "Is this argument solid?" / "poke holes in this" → harden
- "Harden this plan before I commit to it" → harden
- "What's the weakest claim here?" → harden
- An existing `plan.md`, design doc, or pasted thesis needs stress-testing → harden

## When NOT to activate

- The idea is too foggy to state as one falsifiable sentence — sharpen it first (`/plan-context`), then harden.
- The user wants a fresh plan from scratch — that's `/boris` or `/plan-context`.
- The user wants code verified — that's `/verify`.

## The shape

Four stages, all conversational — no runner, no blueprint file:

1. **Frame the thesis** — state the seed as one falsifiable sentence. If you can't, stop and send the user to sharpen it.
2. **Set the proof bar** — what counts as strong evidence, what would falsify it, which 1-3 claims are load-bearing and fragile.
3. **Run the loop** — one or two verify/revise passes (a third only for high stakes with real new evidence). Verify fragile claims against allowed evidence, revise the artifact against what you find. Never invent facts or sources.
4. **Lock** — write `hardened/final.md` and `hardened/one-paragraph-summary.md`, then stop. Acting on the artifact is a separate step.

The one discipline that keeps it bounded: **only ask questions that change the proof bar, the loop structure, or the stop rule.** Everything else gets a stated assumption.

Full procedure and output contract: `commands/harden.md`.

Adapted from the `harden` primitive in Jarad Johnson's cli-skills (MIT); see `skills/ATTRIBUTION.md`.
