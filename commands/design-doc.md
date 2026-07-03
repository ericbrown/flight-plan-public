---
description: Scaffold a dated design doc on the current feature branch. Usage: /design-doc <slug> (e.g. /design-doc auth-refactor).
---

Scaffold a design doc for the current feature. Argument: `$ARGUMENTS` (a short kebab-case
slug describing the feature, e.g. `auth-refactor` or `payment-v2`).

## Step 1 — Validate

If `$ARGUMENTS` is empty, ask the user for a slug (one question, then proceed). The slug
should be lowercase kebab-case, no spaces.

Ensure `docs/specs/` exists in the project root (create it if not).

## Step 2 — Determine the filename

Filename: `docs/specs/YYYY-MM-DD-<slug>-design.md`

Use today's date for `YYYY-MM-DD`.

## Step 3 — Scaffold from template

If `~/flight-plan/docs/specs/TEMPLATE.md` exists, use it as the starting content.
Otherwise use this inline template:

```markdown
# Design: <slug>

> **Status:** Draft
> **Branch:** <current git branch>
> **Date:** YYYY-MM-DD

## Context

What problem are we solving and why now? Include any relevant constraints or prior art.

## Decision

What are we doing? State the chosen approach clearly.

## Alternatives considered

| Option | Why rejected |
|--------|-------------|
| ...    | ...          |

## Rollout

Step-by-step implementation order. Note any migration steps, feature flags, or
backwards-compatibility concerns.

## Open questions

- [ ] ...
```

Fill in `<slug>`, the current git branch name, and today's date before writing.

## Step 4 — Write the file

Write to `docs/specs/YYYY-MM-DD-<slug>-design.md`.

If the file already exists (same date + slug), say so and open it for review rather than
overwriting.

## Step 5 — Confirm

Tell the user:
- The file created (path)
- A reminder: **commit this file on the feature branch before writing any code** —
  the design doc is evidence of intent, not an afterthought.
- They can open it and fill in the Context + Decision sections, then run `/boris <task>`
  to plan execution.
