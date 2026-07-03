---
description: Toggle auto test runner for this project. Shows current state, enables or disables test_on_edit in .claude/project-config.json.
---

Toggle the post-edit test runner for the current project.

## Step 1 — Read current state

Read `.claude/project-config.json`.

If the file doesn't exist:
```
✗ No .claude/project-config.json found. Run /memory-init first.
```
Stop.

## Step 2 — Show current state and act

**If called with no argument** — show status and ask:
```
test_on_edit: [enabled / disabled]
Test command: [commands.test from project-config, or "not set"]

Options:
  /test-on-edit on   — enable
  /test-on-edit off  — disable
```

**If called with `on`:**

Check `commands.test` in project-config. If it's missing or empty:
- Ask: "What command runs your tests? (e.g. `pytest`, `bun test`, `npm test`)"
- Wait for answer
- Write it to `.claude/project-config.json` under `commands.test`
- Confirm: "Saved test command."

Then run:
```bash
~/flight-plan/scripts/enable-test-on-edit.sh
```

Output the result. Then:
```
✓ Auto test runner enabled.
Claude will now run [test command] after each source file edit.
Results appear inline — Claude sees them and fixes failures before continuing.
```

**If called with `off`:**

Run:
```bash
~/flight-plan/scripts/disable-test-on-edit.sh
```

Output the result.
