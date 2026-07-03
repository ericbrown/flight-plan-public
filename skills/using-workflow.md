---
name: using-workflow
description: Use when the user wants to build something, add a feature, fix a bug, change behavior, or start any coding task. Activates on phrases like "let's build", "add X", "fix this", "I want to", "implement", "create", "update", or any description of work to be done. Check this skill BEFORE clarifying questions, BEFORE writing any code, BEFORE making any changes.
---

# Using the Workflow

You have a complete development workflow. Use it automatically — don't wait to be asked.

## The rule

Before ANY coding task, check if the boris workflow applies.
If there's even a 1% chance this is a development task: use the workflow.
Typing `/boris` is optional — the workflow activates on natural language.

## When to activate automatically

- "Let's add X to Y" → boris workflow
- "I want to build X" → boris workflow  
- "Fix this bug" → boris workflow
- "Update the X to do Y" → boris workflow
- "I need X" (anything code-related) → boris workflow
- "Can you implement X" → boris workflow

## When NOT to activate

- Pure questions ("how does X work?")
- Explaining code without changing it
- Reading/reviewing files the user points at
- Debugging an immediate error in the current session (use systematic-debugging instead)

## How to activate without /boris

When you detect a development task from natural language, say:

"I'll run the full workflow for this — let me start by asking a couple of questions to make sure I understand what you're really trying to build."

Then proceed with boris Phase 1 (clarifying questions), Phase 2 (scope), etc.
The user never needs to type /boris. Their natural description of work is enough.

## Skill check discipline

Before every response where you're about to write code, ask yourself:
- Does a workflow skill apply here? (tdd, systematic-debugging, using-workflow)
- If yes: invoke it. Don't rationalize skipping it.
- Skills tell you HOW to do things. Your instincts tell you WHAT to do.
  Use both.

## Priority

User's explicit instructions (CLAUDE.md, direct requests) > workflow skills > default behavior.
If the user says "just fix it quickly without a plan," follow their instruction.
