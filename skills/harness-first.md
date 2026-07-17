# Skill: Harness-First

## When this skill activates

Activates before any **non-trivial fix or feature** — especially a fix for a bug that
was *observed* (in production, CI, or a failing run) rather than one you can reason out
from the code alone. It sits between `systematic-debugging` (investigate) and `tdd`
(build to a spec): here you first build the reproduction that proves the bug, then fix.

Skip it for trivial, obvious one-line changes. Reach for it whenever "did that actually
fix it?" is a real question.

## The discipline

**Write the harness that reproduces the bug, and confirm it FAILS, before you touch the fix.**

A harness is not a unit test of a function's contract. It's a deliberately-scoped rig
that runs the **real code path** with the observed failure conditions, and asserts the
specific wrong outcome you're chasing (wrong value, crash, hang, wrong final state).

| | Unit test | Harness |
|---|---|---|
| Goal | Verify a function's contract | Reproduce one observed bug |
| Code path | Often mocked at boundaries | Real path, controlled inputs |
| Failure | Assertion mismatch | Wrong final state / crash / timeout |

## Workflow

1. **Reproduce first.** Write `tests/harness/test_<bug>_harness.py` (or your project's
   test dir) that exercises the real path and asserts the bug. **Run it. It MUST fail.**
   If it passes, it isn't exercising the broken path — fix the harness before the code.
2. **Now fix.** Change the code.
3. **Re-run the harness.** Green → the fix is real. Red → the fix is wrong; iterate.
4. **Leave the harness in.** It's a regression lock — a future change can't silently
   un-fix the bug.

## Why

Without a harness the loop is: theorize → change → deploy → wait → "maybe?" — hours per
iteration on a running system. With one, it's minutes, and the fix is *proven*, not
plausible. This is also the precondition for any autonomous fix loop (see `AutoFix`) —
without a harness the agent generates plausible-but-wrong fixes and nobody catches it.

Inspired by an internal HARNESS-PATTERN discipline. See `docs/skill-ideas-from-aiden-lucille.md`.
