---
description: Write a failing test first, then implement, then refactor. Auto-triggers when implementing any new function, class, endpoint, or feature.
---

Implement `$ARGUMENTS` (or the feature described in context) using strict
test-driven development. No implementation before a failing test. No exceptions.

## RED — Write the failing test first

Before writing a single line of implementation:

1. Write a test that describes the **expected behavior** (not the implementation)
2. Run it — confirm it **fails with a meaningful error** (not a syntax error, not a missing import)
3. If the test passes before any implementation exists, the test is wrong — rewrite it

Test names describe behavior:
- Good: `should return 401 when token is expired`
- Bad: `test_jwt_validator_line_47`

## GREEN — Minimum implementation to pass

1. Write only what's needed to make **this specific test** pass
2. Do not add functionality not yet covered by a test
3. Run the test — confirm it **passes**
4. Run the full suite — confirm **nothing else regressed**

## REFACTOR — Clean up after green

1. Improve code quality without changing behavior
2. Run the **full test suite** after every refactor step
3. If tests break during refactor: revert the refactor. Green first, then clean.

## Rules

- Never write implementation before a failing test exists.
- If the project has an existing test file for this module, add to it — don't create a separate file.
- Use the test framework already in the project (`package.json`, `pyproject.toml`, or `.claude/project-config.json`). Don't introduce a new one.
- Always run tests and print output before reporting results — never claim "tests pass" without running them.

Check `.claude/memory/conventions.md` for project-specific testing patterns before starting.
