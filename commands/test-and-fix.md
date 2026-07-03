---
description: Run tests, analyze failures, fix them, repeat until green. Uses systematic-debugging skill.
---

Run the test suite and fix failures iteratively until all tests pass.
This uses the systematic-debugging skill — hypothesis-driven, one fix at a time.

## Step 1 — Run full test suite

Use the test command from `.claude/project-config.json`.
If not set, infer from `package.json` scripts, `pytest.ini`, etc.

Capture the full output. Count failures.

If all pass: output "All tests passing. Nothing to fix." and stop.

## Step 2 — Analyze failures

For each failing test:
1. Read the full error and stack trace.
2. Form a hypothesis in one sentence: "This fails because X."
3. Group related failures — often one root cause produces many test failures.

Output:
```
[N] tests failing.

Root causes identified:
1. [hypothesis 1] — affects [N] tests
2. [hypothesis 2] — affects [N] tests
```

## Step 3 — Fix loop (one root cause at a time)

For each root cause, in order of most-to-least failures affected:

**3a — Fix the root cause** (minimum change, no refactoring):
- Make only the change needed to address this specific root cause
- Do not touch anything outside the scope of this fix

**3b — Run tests scoped to the affected files:**
Using `test_single` command from project-config, or scoped run by file glob.

**3c — If fixed:** Note it. Move to next root cause.
**3d — If still failing:** You had the wrong hypothesis. Revert this change.
Form a new hypothesis and try again.
After 3 failed hypotheses on the same failure: stop and report. Don't keep digging.

## Step 4 — Run full suite

After all root causes are addressed, run the full test suite once more.

## Step 5 — Output

```
## test-and-fix complete

Tests: [N] passing, [N] still failing
Fixed: [list of what was fixed]
Still failing: [list with reason if couldn't fix]

[If all green]: Ready for /verify → /commit-push-pr
[If still failing]: See above — manual intervention needed
```

## Rules

- Never suppress a failing test. Never mark a test as skipped to make it "pass."
- One fix at a time. No shotgun changes.
- If a test is testing the wrong thing: flag it and ask the user before changing it.
- Maximum 3 hypothesis cycles per failing test before escalating to user.
