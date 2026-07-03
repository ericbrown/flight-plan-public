---
name: verification-before-completion
description: Use after implementing any fix or feature before declaring it done. Activates when about to mark a task complete, say "that's fixed", "done", or "it works". Ensures the fix actually works — not just that tests pass.
---

# Verification Before Completion

Passing tests ≠ actually working. Use this skill before declaring anything done.

## The discipline

Never say "fixed", "done", or "complete" until you've verified with this checklist.
Tests passing is necessary but not sufficient.

## Checklist

**1. Run the specific scenario that was broken**
Don't just run the test suite. Actually exercise the exact thing that was reported.
If it was a bug: reproduce the original bug scenario and confirm it no longer occurs.
If it was a feature: exercise the feature the way a real user would.

**2. Check adjacent behavior wasn't broken**
Run tests for files you touched AND files that import them.
A fix that breaks a caller is not a fix.

**3. Verify in the actual environment**
Unit tests pass ≠ works in the running app.
If possible: start the dev server and manually verify the behavior.
If not possible: note it and flag for the user.

**4. Check edge cases of the fix**
What happens at the boundaries of your change?
Empty input, null values, maximum values, concurrent calls — pick the 2-3 most likely to break.

**5. Read the diff one more time**
Before committing, read `git diff` of your changes.
Look for: debug artifacts (console.log, print, TODO), accidental deletions, copy-paste errors.

## When a task is actually done

Only mark a task complete when:
- [ ] The specific scenario works
- [ ] Adjacent tests still pass
- [ ] Diff is clean (no artifacts)
- [ ] You could explain to the user exactly what you changed and why it fixes the problem

## The rule about "it seems to work"

"It seems to work" is not done. "I verified it works by doing X" is done.
If you can't describe how you verified it: you haven't verified it.
