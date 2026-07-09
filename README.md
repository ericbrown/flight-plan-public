# Flight Plan

**v0.3.0** · [Changelog](CHANGELOG.md) · [Getting started](GETTING_STARTED.md)

A workflow system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that turns an ad-hoc chat session into a disciplined engineering loop — persistent memory across sessions, an enforced plan-first → execute → verify → PR pipeline, auto-triggering skills, git discipline, and optional issue-tracker and activity-log integrations.

---

## What problem does this solve?

Working with an AI coding agent is powerful, but by default every session starts cold. The agent forgets what it learned yesterday, jumps straight to editing files before it understands the task, and has no opinion about how work should flow from idea to merged PR. You end up re-explaining your architecture, babysitting the agent through risky git operations, and cleaning up half-finished branches.

Flight Plan fixes that by imposing a small, consistent operating discipline — nicknamed the **"Boris" workflow** after the plan-first, subagent-heavy style it encodes:

- **Persistent Memory Bank.** Every project gets a `.claude/memory/` directory that survives across sessions — architecture, current goal, decisions, conventions, and a rolling session history. The agent reads it at the start of every session and updates it at the end, so it stays oriented instead of relearning your codebase each time.
- **Plan-first, then execute, then verify, then PR.** Non-trivial work goes through a bounded three-stage planning pipeline with human approval gates, then executes one subagent per task, then runs a real verification suite (typecheck → tests → lint → build) before anything opens a pull request. No silent "looks done to me."
- **Git discipline built in.** A `main ← dev ← feature` branch model is enforced by CI, destructive git operations are guarded with automatic checkpoints, and every feature branch carries its own committed task context for clean cross-machine handoffs.
- **Optional integrations, opt-in only.** An issue tracker (Linear) and an activity-log MCP can be wired in if you use them — and completely ignored if you don't. Nothing here requires them.

The goal is a system you can trust to run long sessions autonomously without going off the rails, and pick back up days later without losing the thread.

---

## What's in here

| Component | What it does |
|-----------|--------------|
| **Commands** | 29 slash commands for planning, verification, git workflow, and session management |
| **Skills** | Auto-triggering behaviors (TDD, systematic debugging, verification gates, local-CLI delegation) |
| **Memory Bank** | Persistent project context that survives across sessions |
| **Hooks** | Pre/post tool-use guards (destructive-op protection, auto-formatting, session scan) |
| **Modes** | Behavioral segmentation (architect / code / debug / review / audit) |
| **Integrations** | Optional issue-tracker sync and activity-log reporting |

---

## Prerequisites

**Required for the core workflow:**

- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** — the harness these commands, skills, and hooks plug into.
- **git** — the entire git workflow, branch model, and checkpoint system depend on it.
- **Python 3.10+** — the installer's settings merge is a `python3` script, and several helper scripts (deprecation scan, delegate skills) are stdlib-only Python.
- **bash + a shell profile** — hooks and the installer are bash; the installer records the installed version to your profile.
- **curl** — used by the optional integrations and a few helper scripts.

**For the full workflow (optional):**

- **GitHub [`gh` CLI](https://cli.github.com/)** — required to open and merge pull requests from the git commands.
- **A Linear MCP** — the Linear integration is entirely opt-in. If you don't use Linear, just ignore the `/linear-update` command and the Linear steps in the planning pipeline; nothing else depends on it.
- **An OpenRouter API key** — only needed for the optional cross-model helpers (`second-opinion` / `reviewing-docs`), which ask a different model for an independent review. Leave it unset to skip them.

---

## Install

```bash
git clone https://github.com/ericbrown/flight-plan-public.git ~/flight-plan
cd ~/flight-plan
./install.sh
```

The installer is safe to re-run. It backs up existing config, merges learned patterns into your global `~/.claude/CLAUDE.md`, installs both flat and directory-based skills, and preserves machine-specific settings.

**Update anytime:**

```bash
cd ~/flight-plan && git pull && ./install.sh
```

New here? Start with **[GETTING_STARTED.md](GETTING_STARTED.md)** for a guided first-project walkthrough.

---

## Quick start

### First time in a project

```bash
cd /your/project
claude
/memory-init       # one-time: creates .claude/memory/ for persistent context
```

### Every session

**`/session-start` is the first thing you run and `/session-end` is the last — every time you touch a project with Flight Plan.** They're the bookends that make everything else work: `/session-start` loads the Memory Bank so the agent knows where things stand before it does anything, and `/session-end` writes back what changed so the next session starts warm instead of cold. Skip the start and the agent works blind; skip the end and the session's context, decisions, and lessons are lost.

```bash
/session-start     # FIRST — loads context, shows project state, enters plan mode
# ... do your work ...
/session-end       # LAST — saves context, captures lessons, syncs integrations
```

Everything between them — planning, execution, git, Linear — is optional depending on the task. The two bookends are not. Get in the habit of opening with `/session-start` and closing with `/session-end` on every session, even a five-minute one.

---

## Core concepts

### Memory Bank

Each project gets `.claude/memory/` — persistent context that Claude reads at session start and updates as it works:

| File | Purpose |
|------|---------|
| `projectContext.md` | Architecture, stack, key entry points |
| `activeContext.md` | Current goal, approach, what failed, what to try next |
| `progress.md` | Done / in progress / up next |
| `decisionLog.md` | Architecture decisions with rationale and alternatives |
| `conventions.md` | Project-specific patterns and corrections (auto-updated) |
| `sessionHistory.md` | Rolling session summaries (append-only) |

Run `/memory-init` once per project to create these from the starter templates.

Branch-level context lives at `.claude/task-context.md` (committed to git). It's created by `/task-branch`, updated by `/session-end`, and removed by `/task-done` — so a `git pull` on any machine restores full context for the branch: objective, plan, key decisions, current progress, and a resume prompt.

### Skills (auto-triggering)

Skills activate based on context — no command needed:

| Skill | Activates when... |
|-------|------------------|
| `tdd` | Implementing new functions, classes, or endpoints |
| `systematic-debugging` | Tests fail or a build errors out |
| `verification-before-completion` | About to mark a task done |
| `harden` | Stress-testing an existing thesis, argument, draft, or plan before it's used |
| `finishing-a-branch` | All tasks complete, ready for PR |
| `worktrees` | Running parallel sessions on the same repo |
| `reviewing-docs` | Reviewing a generated document against its source — code, research, notes (blind, adversarial, fidelity-checked) |
| `codex` | Delegate deep review, planning, or scoped edits to a local Codex CLI |
| `claude-code` | Delegate bounded work to a local Claude Code CLI (reverse orchestration from another agent) |
| `opencode` | Delegate cheap, fast work to a local OpenCode CLI |
| `grok-build` | Delegate fast, lightweight coding work to a local Grok Build CLI (Composer 2.5) when speed matters more than depth |

The last four are **directory skills** — each is a folder under `skills/` with a `SKILL.md`, an executable delegate script under `scripts/`, and `tests/`. They let one agent hand work off to another local CLI. These plus the `harden` primitive are adapted from Jarad Johnson's [cli-skills](https://github.com/Jdjohnson/skills) (MIT) — see [`skills/ATTRIBUTION.md`](skills/ATTRIBUTION.md) for the exact adaptations and the upstream license.

### Planning pipeline

For anything non-trivial, use the three-stage planning pipeline. Each stage terminates at a human gate, which is what keeps long planning from hanging or over-generating:

```
/plan-context    →  scope + affected files only (approval gate)
/plan-tasks      →  tasks in batches of 5, issues created (annotation gate)
/execute         →  one subagent per task, issue tracker updated throughout
```

The idea: never write an entire plan in one unbounded pass. A batch of five tasks always terminates; an entire plan sometimes doesn't. You annotate `plan.md` between stages, and those inline comments steer the architecture before any code is written.

Or run all three stages with gates in one shot:

```
/boris <task>    →  plan → annotate → "go" → execute → verify → PR
```

### Session-start scan

A `SessionStart` hook (`session-scan`) runs automatically at the start of every session and stays silent unless it has something to say:

- **Interface changes** — diffs the project since your *last* session (not just the last commit — it remembers where you left off) and surfaces changed exports, function signatures, and schema files before you touch code. It watches `api/ schema/ types/ lib/ src/api/ …` plus `.d.ts` / `.proto` / `.graphql`. Add project-specific paths via a `watch_paths` array in `.claude/project-config.json`.
- **Deprecation warnings** — if recently-changed code uses something recorded in `.claude/memory/deprecations.md` as `ACTIVE`, it warns with the replacement. Record one with `/deprecate <name>`; mark it `RESOLVED` when the migration is done.

### Branch model

The git workflow is `main ← dev ← feature`: all work lands on `dev`, and `main` only ever merges `dev`. A `branch-guard` CI workflow enforces it — a PR to `main` from anything other than `dev` fails. Feature branches use a `<user>/<feature>` (or `feature/<name>`) prefix.

Set this up in any project with one command:

```
/branch-model    # creates dev, installs .github/workflows/branch-guard.yml, makes dev the default branch
```

The reusable workflow lives at `templates/github/branch-guard.yml`.

### Design docs

Before writing code on a significant change, scaffold a design doc:

```
/design-doc <slug>    # creates docs/specs/YYYY-MM-DD-<slug>-design.md on the current branch
```

The convention: **cut the feature branch first, then commit the design doc as the first commit on that branch.** That makes the design doc part of the PR, not an afterthought. The template lives at `docs/specs/TEMPLATE.md` — sections: Context · Decision · Alternatives · Rollout · Open questions.

### Modes

Switch Claude's behavior for different phases of work:

| Mode | Behavior |
|------|----------|
| `/mode architect` | Read-only design — no file edits |
| `/mode code` | Full implementation (default) |
| `/mode debug` | Investigation, hypothesis-driven, minimal writes |
| `/mode review` | Strictly read-only review |
| `/mode audit` | Security scanning with logging |

---

## All commands

There are 29 slash commands, grouped below.

### Session

| Command | What it does |
|---------|-------------|
| `/session-start` | Load Memory Bank, orient to project, enter plan mode |
| `/session-end` | Save context, capture lessons, sync integrations |
| `/digest [days]` | Generate a rollup from sessions + research-log (default: 7 days) |
| `/context` | Show context window usage + Memory Bank status |
| `/handoff` | Save cognitive state for cross-session handoff |
| `/memory-init` | Initialize the Memory Bank (once per project) |
| `/deprecate <name>` | Record a deprecated pattern (session-start scan warns on use) |

### Planning

| Command | What it does |
|---------|-------------|
| `/boris <task>` | Full workflow: plan → execute → verify → PR |
| `/plan-context` | Stage 1: scope + affected files |
| `/plan-tasks` | Stage 2: tasks in batches, issues created |
| `/execute` | Stage 3: run tasks via subagents |

### Quality

| Command | What it does |
|---------|-------------|
| `/verify` | typecheck → tests → lint → build |
| `/harden` | Verify/revise a thesis, argument, draft, or plan into a defensible artifact (checks an idea, not code) |
| `/test-and-fix` | Run tests, fix failures iteratively until green |
| `/test-on-edit` | Run the relevant tests automatically after edits |
| `/systematic-debugging` | Hypothesis-driven diagnosis — read error, form hypothesis, targeted diagnostic, fix root cause |
| `/tdd` | Write a failing test first, minimum implementation to pass, then refactor |
| `/simplify` | Clean up code after implementation without changing behavior |
| `/review-changes` | Pre-commit review of uncommitted changes |

### Git

| Command | What it does |
|---------|-------------|
| `/task-branch <name>` | Create a feature branch + task context |
| `/task-done` | Verify, PR, clean up task context |
| `/commit-push-pr` | Stage, commit, push, create a PR |
| `/checkpoint [name]` | Create a named git save point |
| `/rollback [target]` | Restore a checkpoint or go back N commits |
| `/undo` | Revert the last commit safely |
| `/branch-model` | Set up `main ← dev ← feature`: create dev, install branch-guard CI, make dev default |
| `/design-doc <slug>` | Scaffold `docs/specs/YYYY-MM-DD-<slug>-design.md` on the current branch |

### Modes

| Command | What it does |
|---------|-------------|
| `/mode <name>` | Switch working mode: `architect` (read-only design), `code`, `debug`, `review`, `audit` |

### Linear (optional)

| Command | What it does |
|---------|-------------|
| `/linear-update` | Add a progress comment to the current issue |
| `/linear-update <ID>` | Comment on a specific issue |
| `/linear-update plan` | Push the plan to all issues in it |

---

## Hooks

| Hook | Trigger | What it does |
|------|---------|--------------|
| `destructive-ops-guard` | Before `git reset --hard`, `rm -rf`, force-push | Creates a checkpoint, stashes dirty files |
| `post-edit-formatter` | After file edits | Auto-formats by file type |
| `session-scan` | Session start | Surfaces interfaces changed since your last session + warns on deprecated-pattern usage |
| `session-hint` | On prompt submit | Injects a one-time daily reminder to auto-run `/session-start` and auto-trigger workflows |
| `post-edit-test-runner` | After file edits | Runs scoped tests after source edits, feeds output back (opt-in per project) |
| `mcp-activity-log` | After MCP memory writes | Best-effort report to an optional activity-log server (see below) |

---

## Issue-tracker integration (optional)

Flight Plan can drive [Linear](https://linear.app/) so that development work is always tracked, but the integration is entirely opt-in. If you don't use Linear, ignore this section and the `/linear-update` command — nothing else in the toolkit depends on it.

When enabled, the planning commands keep an issue tracker in lockstep with the work:

- Issues are created during `/plan-tasks`, one per task.
- Each issue moves to **In Progress** when `/execute` starts that task.
- Progress comments are posted at each meaningful stage.
- A session summary is posted by `/session-end`.
- Issues are never auto-closed — only you close them.

Team/project IDs are saved to `.claude/project-config.json` after first use.

---

## Activity-log MCP integration (optional)

Flight Plan can report session activity to an external MCP **activity-log** server, so a central aggregator can stay aware of work across multiple machines. This is entirely optional and **off by default** — when the `ACTIVITY_MCP_URL` environment variable is unset, nothing is sent.

Two things feed the activity log when it's configured:

| Event | How |
|-------|-----|
| MCP memory write | The `hooks/mcp-activity-log.sh` PostToolUse hook fires after memory writes |
| Session end | `/session-end` reports a full session summary |

Both are **best-effort** and fail silently if the server is unreachable (env var unset, host asleep, off-network) — they never block your session.

### Configure

```bash
export ACTIVITY_MCP_URL=http://YOUR_MCP_HOST:PORT/mcp
claude mcp add activity-log "$ACTIVITY_MCP_URL"
```

Use your own host and port in place of `YOUR_MCP_HOST:PORT`.

For machines that can't reach the MCP server directly, a companion `research-log/` notebook carries session "thinking" back through git instead — commit it on one machine, pull it on another, and the central aggregator picks it up from the repo.

---

## Cross-model review (optional)

The problem with having one model review its own writing is that it grades its own homework. Flight Plan ships `scripts/second-opinion.py` to get a *genuinely different* model to review a document — a user guide against the code it describes, a research summary against its sources, or a blog post's factual claims. It's the engine behind the `reviewing-docs` skill, which auto-triggers when you ask Claude to "review this against the source" / "verify these claims" / "does this hold up." It's **stdlib-only** (no `pip install`) and entirely opt-in: with no API key set it exits cleanly and the skill falls back to a Claude-only review.

**Providers** — one helper, five backends, auto-detected by which key is set (override with `--provider` or `REVIEW_PROVIDER`):

| Provider | Env key | Notes |
|----------|---------|-------|
| `openrouter` | `OPENROUTER_API_KEY` | One key reaches any model. Default; routes to Gemini 3.1 Pro. |
| `gemini` | `GEMINI_API_KEY` | Google AI Studio direct; free tier. |
| `github-models` | `GITHUB_TOKEN` | Free, rate-limited, via your GitHub token. |
| `openai` | `OPENAI_API_KEY` | OpenAI API, pay per token. |
| `codex` | *(needs `codex` CLI on PATH)* | Agentic pass; reads sources itself. |

**Two modes** — `--mode review` (default) is a blind adversarial read: with `--source` it checks fidelity to that source (fabrications, overstatements, dropped caveats); without one it flags every uncited confident claim. `--mode verify` is a live web citation check that returns a per-claim verdict with source URLs — use a search model (`--model perplexity/sonar-pro`).

```bash
# Fidelity review of a guide against the code it documents:
python3 ~/.claude/scripts/second-opinion.py --doc guide.md --source <(cat src/**/*.py) --provider openrouter

# Surface AI-written claims that need checking, then web-verify them:
python3 ~/.claude/scripts/second-opinion.py --doc post.md --provider openrouter --mode review
python3 ~/.claude/scripts/second-opinion.py --doc post.md --provider openrouter --model perplexity/sonar-pro --mode verify
```

Every default model ID and generation setting is env-overridable (`OPENROUTER_MODEL`, `REVIEW_MAX_TOKENS`, etc.), so a `400` from a drifted model slug is a one-line fix. Exit codes: `0` ran, `2` no provider configured (falls back), `3` API error or degenerate output. Full reference, tuning table, and the two-pass verify workflow: [GETTING_STARTED §7](GETTING_STARTED.md#7-optional-cross-model-review).

---

## Parallel sessions

Run multiple Claude Code sessions at once using git worktrees — each gets its own branch, terminal, and task context, with no stashing and no conflicts:

```bash
# Create parallel worktrees
git worktree add ~/project-2 -b feature/new-api
git worktree add ~/project-3 -b fix/some-bug

# Each worktree gets its own terminal + Claude session
```

See the `worktrees` skill for the full setup and conventions.

---

## Syncing learned patterns

Lessons accumulate in `~/.claude/CLAUDE.md` as you correct Claude over time. Sync them across machines through the repo:

```bash
cd ~/flight-plan
./sync-lessons.sh              # local → repo
git add CLAUDE.md && git commit -m "sync lessons" && git push

# On another machine:
git pull && ./sync-lessons.sh --pull
```

---

## File structure

```
flight-plan/
  CLAUDE.md              # Global instructions + learned patterns
  install.sh             # Installer (safe to re-run)
  sync-lessons.sh        # Lesson sync across machines
  settings.base.json     # Hook config + permissions
  VERSION                # Single source of truth for the version

  commands/              # Slash commands
  skills/                # Auto-triggering behaviors (flat *.md + directory skills with SKILL.md/scripts/tests)
  scripts/               # Helper scripts (second-opinion, deprecation_scan)
  agents/                # Subagent definitions
  hooks/                 # Lifecycle hooks (incl. session-scan, mcp-activity-log)
  memory-template/       # Starter files for /memory-init
  templates/github/      # Reusable CI (branch-guard) for /branch-model
  research-log/          # Session "thinking" notebook synced via git
  docs/specs/            # Design docs (YYYY-MM-DD-<slug>-design.md) — scaffold with /design-doc
  .github/workflows/     # This repo's own CI (branch-guard, tests)
```

---

## License

Flight Plan is released under the MIT License — see [`LICENSE`](LICENSE).

The three delegate skills (`codex/`, `claude-code/`, `opencode/`) and the `harden` command/skill are adapted from Jarad Johnson's **cli-skills** ([github.com/Jdjohnson/skills](https://github.com/Jdjohnson/skills)), also MIT. Full details of what was kept, dropped, and changed — plus the upstream license text — are in [`skills/ATTRIBUTION.md`](skills/ATTRIBUTION.md).
