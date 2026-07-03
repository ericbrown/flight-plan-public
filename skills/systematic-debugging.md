# Skill: Systematic Debugging

## When this skill activates
Activates automatically when a test fails unexpectedly, a build errors out, or
a runtime error appears. Do not guess-and-check. Follow this process.

## Workflow

**Step 1 — Read the full error before doing anything.**
Do not modify code until you have read the complete error message, stack trace,
and any relevant log output. Partial reads lead to wrong fixes.

**Step 2 — Form a hypothesis. State it in one sentence.**
Example: "The JWT validator is calling `verify()` with the wrong key format."
If you can't state a hypothesis, you need more information — add logging first.

**Step 3 — Add one targeted diagnostic to confirm or deny the hypothesis.**
- A `console.log` or `print()` at the specific suspect location
- A focused test that isolates the suspected component
- A `git blame` to see when this line last changed

Run it. Read the result. Does it confirm or deny your hypothesis?

**Step 4a — Hypothesis confirmed**: fix the specific root cause.
- Make the minimal change that addresses the root cause
- Remove the diagnostic logging
- Run the full test suite to confirm nothing else broke

**Step 4b — Hypothesis denied**: revert the diagnostic, form a new hypothesis, repeat.

## Rules

- Never make multiple simultaneous changes hoping one fixes it.
- Never suppress an error without understanding it.
- If you've been through 3 hypothesis cycles without progress: stop and report to
  the user with what you know. Don't keep digging in the same direction.
- Prefer fixing root causes over adding workarounds. A `try/catch` around a broken
  function is not a fix.

## Common failure patterns to check first

- **"works on my machine"**: check env vars, `.env` files, dependency versions
- **Test passes alone, fails in suite**: test pollution, shared state, async ordering
- **Build works, runtime fails**: missing env var, wrong import path, tree-shaking removed something
- **Intermittent failure**: async race condition, network timeout, non-deterministic order
