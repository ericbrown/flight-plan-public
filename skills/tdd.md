# Skill: Test-Driven Development

## When this skill activates
Activates automatically when implementing any new function, class, API endpoint,
or feature. Do not wait to be asked — this is the default workflow.

## Workflow

### RED — Write the failing test first

Before writing a single line of implementation code:
- Write a test that describes the expected behavior
- Run it. Confirm it **FAILS with a meaningful error** (not a syntax error, not a missing import)
- If the test passes before any implementation exists, the test is wrong — rewrite it

Use this `/goal` condition to run RED autonomously:
```
/goal the failing test for [feature] exists and fails with a meaningful error — or stop after 5 turns
```

---

### GREEN — Minimum implementation to pass

- Write only what's needed to make the specific test pass
- Do not add functionality not yet covered by a test
- Run the test. Confirm it **PASSES**

Use this `/goal` condition to run GREEN autonomously:
```
/goal [test name] passes with minimum implementation and no other tests regress — or stop after 10 turns
```

---

### REFACTOR — Clean up after green

- Improve code quality without changing behavior
- Run the full test suite after every refactor step — not just the one test
- If tests break during refactor: revert the refactor. Green first, then clean.

Use this `/goal` condition for the full cycle:
```
/goal [feature] is fully implemented with passing tests, lint is clean, and no existing tests regress — or stop after 20 turns
```

---

## Rules

- Never write implementation before a failing test exists. No exceptions.
- If the codebase already has a test file for this module, add to it. Don't create a separate file.
- Use the test framework already in the project (`package.json`, `pyproject.toml`, or `.claude/project-config.json`). Don't introduce a new framework.
- Test names describe behavior, not implementation:
  - Good: `should return 401 when token is expired`
  - Bad: `test_jwt_validator_line_47`
- The `/goal` evaluator reads the transcript only — Claude must **run the tests and print output** for the evaluator to verify the condition. Never report "tests pass" without running them.

## Reference
Read `.claude/memory/conventions.md` for project-specific testing patterns.
