---
description: Diagnose and fix a failure methodically — hypothesis-driven, no guess-and-check. Auto-triggers on test failures, build errors, and runtime errors.
---

Diagnose and fix the problem described in `$ARGUMENTS` (or inferred from the current
conversation context if blank). Do not guess-and-check. Follow this process exactly.

## Step 1 — Read the full error before doing anything

Read the complete error message, stack trace, and any relevant log output. Do not modify
code until you have the full picture. Partial reads lead to wrong fixes.

## Step 2 — Form a hypothesis. State it in one sentence.

Example: "The JWT validator is calling `verify()` with the wrong key format."

If you cannot state a hypothesis, you need more information — add a targeted diagnostic
first (a `console.log`, `print()`, or focused test), gather output, then form the hypothesis.

## Step 3 — Add one targeted diagnostic to confirm or deny the hypothesis

Options:
- A `console.log` or `print()` at the specific suspect location
- A focused test that isolates the suspected component
- A `git blame` to see when this line last changed
- A diff of the relevant file since the last known-good state

Run it. Read the result. Does it confirm or deny your hypothesis?

## Step 4a — Hypothesis confirmed: fix the root cause

- Make the **minimal change** that addresses the root cause
- Remove the diagnostic logging
- Run the **full test suite** to confirm nothing else broke

## Step 4b — Hypothesis denied: revert and try again

Revert the diagnostic. Form a new hypothesis. Go back to Step 2.

## Rules

- Never make multiple simultaneous changes hoping one fixes it.
- Never suppress an error without understanding it (`try/catch` around a broken function is not a fix).
- If you've cycled through 3 hypotheses without progress: **stop and report** what you know. Do not keep digging in the same direction.
- Prefer fixing root causes over workarounds.

## Common failure patterns to check first

| Symptom | First thing to check |
|---------|---------------------|
| "Works on my machine" | Env vars, `.env` files, dependency versions |
| Test passes alone, fails in suite | Test pollution, shared state, async ordering |
| Build works, runtime fails | Missing env var, wrong import path, tree-shaking |
| Intermittent failure | Async race condition, network timeout, non-deterministic order |
