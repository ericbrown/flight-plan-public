# Research log

A lightweight, git-carried notebook for durable work notes. This is a plain
directory of dated Markdown files (`YYYY-MM-DD.md`) that travels with the repo,
so context survives across sessions and machines without depending on any
external service.

## Why it exists

Two things write here:

- **`/session-end`** — when you close out a session, a short entry can be
  appended summarizing what was done, decided, and what to resume next.
- **The activity-log MCP hook (optional)** — if you wire up
  `ACTIVITY_MCP_URL` (see the README's "Activity-log MCP integration" section),
  the `mcp-activity-log.sh` hook records tool activity to your MCP server. The
  research log is the local, in-repo counterpart: it needs no server and is
  readable straight from the tree.

Neither is required. If you never configure the MCP and never run `/session-end`,
this directory simply stays empty except for this file.

## Conventions

- One file per day: `research-log/2026-07-03.md`.
- Append, don't overwrite — each entry is a timestamped note under the day's file.
- Dated logs are gitignored by default (see `.gitignore`) so day-to-day notes
  don't clutter history. Remove the ignore rule if you want to commit them.

This README is tracked so the directory always exists in a fresh clone.
