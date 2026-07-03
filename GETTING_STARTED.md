# Getting Started with Flight Plan

Flight Plan is a workflow toolkit for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It adds a set of slash commands, auto-triggering skills, lifecycle hooks, and a persistent "Memory Bank" that give Claude Code a disciplined, repeatable way to work: **load context → plan → get your approval → execute → verify → open a pull request.**

This guide walks a brand-new user from zero to a shipped PR. No prior knowledge of the toolkit is assumed. Follow it top to bottom the first time; after that, sections 4 and 8 are the daily loop.

Everything in Flight Plan is optional except the core loop. Linear, the activity-log MCP, and cross-model review are all opt-in and safe to skip.

---

## Table of contents

1. [Prerequisites](#1-prerequisites)
2. [Install Flight Plan](#2-install-flight-plan)
3. [One-time project setup](#3-one-time-project-setup)
4. [Your first task, end to end](#4-your-first-task-end-to-end)
5. [Optional: Linear integration](#5-optional-linear-integration)
6. [Optional: activity-log MCP](#6-optional-activity-log-mcp)
7. [Optional: cross-model review](#7-optional-cross-model-review)
8. [Ending a session](#8-ending-a-session)
9. [Day two: updating, syncing, and parallel sessions](#9-day-two-updating-syncing-and-parallel-sessions)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites

### Required

| Tool | Why it's needed | Check it's installed |
|------|-----------------|----------------------|
| **Claude Code CLI** | Flight Plan is a set of commands, skills, and hooks that run *inside* Claude Code. Without it, nothing here works. | `claude --version` |
| **git** | Flight Plan's entire workflow is built around branches, commits, and PRs. | `git --version` |
| **Python 3.10+** | The installer uses `python3` to deep-merge your `settings.json`. Helper scripts (second-opinion, deprecation scan) also use it. | `python3 --version` |
| **bash** | `install.sh` and the hooks are bash scripts. | `bash --version` |
| **A shell profile** — `~/.zshrc` or `~/.bashrc` | The installer appends one line to source your secrets file (only if you create one). | `ls -a ~ | grep -E 'zshrc|bashrc'` |
| **curl** | The installer uses it to probe whether an optional activity-log MCP is reachable. | `curl --version` |

If `claude` is not on your `PATH`, install Claude Code first (see the [official docs](https://docs.anthropic.com/en/docs/claude-code)) and confirm `claude --version` prints a version before continuing.

### Optional (each one is independently skippable)

| Tool | What it unlocks | Skip it if... |
|------|-----------------|---------------|
| **GitHub `gh` CLI** (authenticated) | The PR-creation step (`/commit-push-pr`, `/boris` Phase 7) uses `gh` to open pull requests. | You don't need Claude to open PRs for you — you can push and open the PR by hand. |
| **A Linear MCP** | Automatic issue creation and progress tracking during the planning pipeline. | You don't use Linear. The commands simply become no-ops. |
| **An OpenRouter API key** | The cross-model "second opinion" review helper (`reviewing-docs` skill / `second-opinion.py`). | You don't want a second model reviewing your docs. |
| **An activity-log MCP endpoint** | Reports session summaries and memory writes to a central aggregator of your own. | You have no such aggregator. It stays off when unset. |

> **The golden rule:** if an optional integration isn't configured, Flight Plan detects that and quietly moves on. Nothing in the core loop depends on any of them.

---

## 2. Install Flight Plan

### 2.1 Clone and run the installer

```bash
git clone https://github.com/ericbrown/flight-plan-public.git ~/flight-plan
cd ~/flight-plan
./install.sh
```

You'll see output like this (versions and counts will differ):

```
Flight Plan Installer  v0.3.0
=========================

Backing up ~/.claude/ → /home/you/.claude/backups/20260703-101500
  backed up: CLAUDE.md
  backed up: settings.json
  backed up: commands/
...
Installing commands...
  + commands/boris.md
  + commands/session-start.md
  ...
Merging settings...
  Existing settings.json — merging hooks + permissions...
  Merged.
...
Flight Plan v0.3.0 installed!

Installed to: /home/you/.claude/
Backup at:    /home/you/.claude/backups/20260703-101500
```

### 2.2 What `install.sh` actually does

The installer targets `~/.claude/` (Claude Code's global config directory). Step by step:

1. **Backs up your existing config.** If `~/.claude/` already exists, it copies `CLAUDE.md`, `settings.json`, and the `commands/ agents/ skills/ hooks/ scripts/` directories into a **timestamped** backup folder like `~/.claude/backups/20260703-101500/`. Nothing you had is destroyed.
2. **Creates the directory structure** under `~/.claude/` if it's missing.
3. **Copies the commands** (`commands/*.md`) — the slash commands you'll type in Claude Code.
4. **Copies the agents** (`agents/*.md`) — specialist subagents the workflow delegates to.
5. **Copies the skills** (`skills/`) — both flat `*.md` skills and "directory skills" (a folder with its own `SKILL.md`, `scripts/`, and `tests/`). Any Python scripts inside a directory skill are made executable.
6. **Copies the hooks** (`hooks/*.sh`) and marks them executable — lifecycle guards that run around your tool use (for example, a guard before destructive git operations, and a session-start scan).
7. **Copies the helper scripts** (`scripts/*`) that hooks and commands call.
8. **Merges `CLAUDE.md` intelligently.** If you already have a `~/.claude/CLAUDE.md`, the installer keeps everything under your existing `# Learned Patterns` heading and appends it to the new file, so your accumulated lessons survive the upgrade. If you have no existing file, it just installs the repo's copy.
9. **Deep-merges `settings.json` with `python3`.** Rather than overwriting, it unions the hook groups (adding only ones you don't already have, matched by command path) and unions your `permissions.allow` / `permissions.deny` lists. This is why Python 3 is a hard requirement — without it this step fails.
10. **Optionally registers an activity-log MCP.** If (and only if) an activity-log endpoint is configured and reachable, it registers it with `claude mcp add`. Off by default. See [section 6](#6-optional-activity-log-mcp).
11. **Pulls learned patterns** from the repo (via `sync-lessons.sh --pull`) if any are present.
12. **Optionally wires `secrets.env` into your shell.** If — and only if — you've created a `secrets.env` file (you haven't yet, and that's fine), it appends a single `source` line to `~/.zshrc` and `~/.bashrc`. See [section 7](#7-optional-cross-model-review).
13. **Records the installed version** to `~/.claude/.flight-plan-version`.

### 2.3 It's safe to re-run

`install.sh` is **idempotent**. Every run makes a fresh timestamped backup, re-merges rather than clobbers, and skips anything already in place. Re-running it is exactly how you upgrade (see [section 9](#9-day-two-updating-syncing-and-parallel-sessions)). If a run ever goes wrong, your previous config is sitting in the `backups/` folder printed at the end.

---

## 3. One-time project setup

Flight Plan keeps per-project memory in a `.claude/` folder inside each repo. You initialize this once per project.

```bash
cd /path/to/your/project
claude
```

Then, inside Claude Code:

```
/memory-init
```

Claude will ask you a short batch of questions (answer them all in one message):

1. What is this project? (one sentence)
2. Primary language and framework?
3. Package manager? (npm / bun / pip / etc.)
4. Test command? (e.g. `pytest`, `bun test`)
5. Typecheck command? (e.g. `mypy .`, `bun run typecheck`)
6. Lint command? (e.g. `ruff check .`, `bun run lint`)
7. Build command? (or "none")
8. Dev server command? (or "none")
9. Auto-run tests after every file edit? (yes/no)

From your answers it creates:

- **`.claude/project-config.json`** — your project name, stack, and the exact test/typecheck/lint/build/dev commands. Every command that needs to run your test suite reads it from here, so you set them once.
- **`.claude/memory/`** — the Memory Bank, a set of markdown files that persist context across sessions:

| File | What it holds |
|------|---------------|
| `projectContext.md` | What the project is, its architecture, stack, key entry points |
| `activeContext.md` | The "latest state" snapshot: current goal, approach, what to try next |
| `progress.md` | Task tracking — Completed / In progress / Up next |
| `decisionLog.md` | Architectural decisions with rationale and rejected alternatives |
| `conventions.md` | Project-specific patterns and corrections (auto-updated as you correct Claude) |
| `sessionHistory.md` | Append-only rolling log of session summaries |
| `deprecations.md` | Patterns you've formally deprecated (the session-start scan warns if changed code uses one) |
| `sessions/` | One dated file per session — the full history |

- **`.claude/loop.md`** — customizes what a bare `/loop` does in this project (maintenance defaults).

Finally it asks whether to commit `.claude/` to git. **Say yes** if you want cross-machine handoffs (any machine that pulls the repo gets full context); say no to keep Claude's context out of the repo, in which case it adds `.claude/memory/` to `.gitignore`.

You only do this once. After that, every session automatically loads this context.

---

## 4. Your first task, end to end

This is the core loop, and the whole point of Flight Plan. We'll build a small example feature: **"add a `--json` output flag to the report command."** Substitute your own task anywhere you see it.

### 4.1 Start the session

**`/session-start` is always the first thing you do in a Flight Plan project — before describing a task, before touching a file, before anything else.** It's what loads the Memory Bank so the agent knows where the project stands instead of working blind. Make it a reflex: open Claude Code, run `/session-start`, *then* start working. (It has a companion at the other end — `/session-end`, covered in [section 8](#8-ending-a-session) — that you run as the *last* thing before you stop. The two bookend every session.)

Inside Claude Code:

```
/session-start
```

This runs silently, then prints a compact summary. It:

- reads your Memory Bank (`projectContext.md`, `activeContext.md`, `progress.md`, `conventions.md`, recent session files),
- reads any branch-level `.claude/task-context.md`,
- captures git state (`git branch --show-current`, `git status --short`, `git log --oneline -5`),
- reads `.claude/project-config.json`,
- then **enters plan mode and stops.**

Expected output looks roughly like:

```
## Session Start — your-project

Branch: dev | Status: clean
Last commit: chore: init claude memory bank

Last session: First session — project setup and orientation.
In progress: nothing active
Up next: Explore codebase and fill in projectContext.md

Conventions: none
```

The key thing: **Claude will not write code yet.** It's waiting for a task and an approved plan.

### 4.2 Describe the task

Just say what you want, in plain language:

```
Add a --json flag to the report command so it can emit machine-readable output.
```

Because the message describes something to build, Flight Plan routes it into the **Boris workflow** automatically (that's `/boris` — you don't have to type the command name). You can invoke it explicitly if you prefer:

```
/boris add a --json flag to the report command
```

### 4.3 The Boris workflow (plan → gate → execute → verify → PR)

`/boris` runs an orchestrated, gated workflow. There are exactly **two approval gates**, and it never executes without your explicit go-ahead.

**Phase 1 — Orient and brainstorm.** Claude scopes the request, asks up to a few clarifying questions **one at a time** (only things it can't learn by reading the code), then proposes 2–3 distinct approaches with tradeoffs. You pick one.

**Phase 2 — Design doc.** Claude writes a short design document, section by section, confirming each with you, and saves it to `docs/specs/YYYY-MM-DD-<feature>-design.md`. A one-pass spec-reviewer subagent sanity-checks it. Then:

> **Gate 1:** "Design doc saved. Ready to write the plan?"

**Phase 3 — Plan.** Claude writes `plan.md` — a goal, an approach, and a task list in **batches of 5**, pausing after each batch so you can annotate (`<!-- skip -->`, `<!-- use X instead -->`, `<!-- do this last -->`). If a Linear MCP is connected, one issue is created per task (see [section 5](#5-optional-linear-integration)); if not, tasks are written with `TBD` placeholders and it moves on. Then:

> **Gate 2:** "Say 'go' when ready."

This is the **plan-approval gate.** Nothing is implemented until you literally type:

```
go
```

**Phase 4 — Execute.** Claude works one task at a time. For each task it: (optionally) writes a failing test first, implements against the design's patterns, then runs **typecheck → scoped tests → lint in that order.** If a task passes, it self-checks the diff against the acceptance criteria, commits, and moves on. If a task **fails verification, it reverts that task's changes and stops** — it does not patch over a bad approach.

**Phase 5 — Full verification.** After all tasks, it runs the whole suite: typecheck → full tests → lint → build. See [`/verify`](#43a-the-verification-gate) below.

**Phase 6 — Simplify (optional).** It offers to run a cleanup pass over the changed files (dead code, unused imports) with no behavior changes.

**Phase 7 — Create PR.** It shows you the remote, branch, and commit list, asks for confirmation, pushes, and opens the PR (needs `gh`; see [section 10](#10-troubleshooting) if `gh` isn't authenticated).

#### The 3-stage pipeline (the manual alternative to `/boris`)

`/boris` is a convenience wrapper. For finer control you can drive the same pipeline by hand:

```
/plan-context     # Stage 1: scope + likely-affected files. Approval gate.
/plan-tasks       # Stage 2: tasks in batches of 5, Linear issues per batch. Annotation gate.
/execute          # Stage 3: one subagent per task, verification gate per task.
```

- **`/plan-context`** lists only the affected files, reference patterns, external dependencies, out-of-scope items, and open questions — then stops and asks *"Scope looks right?"* It writes no plan yet. (Max 20 affected files; more than that is a signal the task is too big.)
- **`/plan-tasks`** writes `plan.md` and an `ACCEPTANCE.md`, five tasks at a time, pausing for your annotations. It does **not** proceed to execute on its own.
- **`/execute`** reads the annotated `plan.md` and runs each task with the per-task verification gate described above.

Why three stages instead of one big plan? A batch of five tasks always terminates; an unbounded "generate the whole plan" pass sometimes doesn't. The gates keep you in control of scope before any code is written.

<a id="43a-the-verification-gate"></a>
### 4.4 The verification gate

At any point you can run the full suite yourself:

```
/verify
```

It reads your commands from `.claude/project-config.json` and runs, stopping on the first hard failure:

```
## Verify

typecheck    PASS
tests        PASS (42 passed, 0 failed)
lint         PASS
build        PASS
smoke test   SKIPPED

Overall: PASS
```

On PASS it tells you you're "Ready for /simplify or /commit-push-pr." On FAIL it prints the exact error and **stops without trying to fix it** — that's your cue to decide the next move. Verification is a gate, not a rubber stamp: nothing is marked done until it's proven.

### 4.5 Branching: work never happens on `main`

Flight Plan follows a strict branch model: **`main ← dev ← feature`.**

- `main` is production. `dev` is integration. All actual work happens on a short-lived **feature branch off `dev`**, named `<user>/<feature>` (substitute your own handle for `<user>`).
- Before cutting a branch, hard-sync so it isn't born behind:

  ```bash
  git fetch origin
  git checkout dev
  git reset --hard origin/dev
  git checkout -b <user>/<feature>
  ```

- **Never commit directly to `dev` or `main`.** Every change reaches them through a pull request.
- Merge PRs with `gh pr merge --merge` — **never squash, never rebase a PR branch, never force-push** a shared branch.
- After a merge: `git checkout dev && git pull`, then branch the next task off the freshly updated `dev`.

You can scaffold a feature branch plus its cross-machine handoff context in one step:

```
/task-branch feature/json-report-flag
```

This creates the branch and writes a committed `.claude/task-context.md` (objective, plan, decisions, resume prompt) so any machine that pulls the branch has the full picture.

To set up the `main ← dev ← feature` model in a fresh repo — create `dev`, install the branch-guard CI that blocks any non-`dev` PR into `main`, and make `dev` the default branch — run `/branch-model` once.

### 4.6 Ship it

When verification is green, open the PR:

```
/commit-push-pr
```

This command:

1. Reads git state (`git remote -v`, current branch, status, diff stat).
2. **Shows you the exact remote and branch and asks "Push to [remote] on [branch]? (yes/no)"** — it never pushes without your confirmation.
3. Stages, writes a descriptive imperative commit message, commits.
4. Pushes to `origin <branch>`.
5. Opens a PR (via `gh`) titled after the commit, with a Summary / Changes / Verification body.
6. If Linear is connected, adds a completion comment with the PR link to each completed issue (it never closes issues — you do that yourself).

That's the whole loop: **`/session-start` → describe task → `/boris` (or the 3-stage pipeline) → say `go` → `/verify` → `/commit-push-pr`.** You now have a PR from `<user>/<feature>` into `dev`.

---

## 5. Optional: Linear integration

Linear is entirely opt-in. Flight Plan detects at runtime whether a Linear MCP is available.

**If you have a Linear MCP connected:**

- During `/plan-tasks` (or `/boris` Phase 3), one Linear issue is created per task, in a single batched call per batch of five.
- When `/execute` starts a task, that issue moves to **In Progress.**
- Progress comments are posted at each meaningful stage (delegated to subagent, test red, implementation written, committed).
- `/session-end` posts a session summary to each touched issue.
- `/commit-push-pr` adds the PR link to completed issues.
- Issues are **never auto-closed.** You close them when you're satisfied.
- The Linear team/project ID is saved to `.claude/project-config.json` on first use, so you're never asked twice.
- Use `/linear-update` any time for an ad-hoc progress comment.

**If you do NOT have a Linear MCP:**

Nothing breaks. Every Linear step degrades gracefully — tasks are written with `TBD` placeholders, a note is added, and the workflow continues. You can simply ignore the Linear commands; they're unused.

---

## 6. Optional: activity-log MCP

If you run a central "activity log" aggregator of your own (an MCP server that collects what your Claude sessions did across machines), you can point Flight Plan at it. This is off by default and does nothing unless you set it up.

Set the endpoint as an environment variable (use your own host and port — these are placeholders), then register it with Claude Code:

```bash
export ACTIVITY_MCP_URL=http://YOUR_MCP_HOST:PORT/mcp
claude mcp add activity-log "$ACTIVITY_MCP_URL"
```

Once registered:

- A hook fires after memory writes to report them to the aggregator.
- `/session-end` calls the activity-log tool with a full session summary (see [section 8](#8-ending-a-session)).

Behavior when it's not set up:

- **Unset:** the installer and commands skip it entirely.
- **Set but unreachable** (server asleep, off a VPN / private network, wrong host): the hook **fails silently and never blocks your session.** You'll just see it noted as "not connected" in the session-end summary.

There is no requirement to run one. Most users never will.

---

## 7. Optional: cross-model review

Flight Plan can get a genuinely *different* model to review a document you (or Claude) produced — a user guide against the code it describes, a research summary against its sources, a blog post's factual claims. This is the `reviewing-docs` skill, powered by `scripts/second-opinion.py`. It's useful precisely because it stops the model that wrote something from grading its own homework.

### 7.1 Set up a key

Copy the template and add your key:

```bash
cd ~/flight-plan
cp secrets.env.example secrets.env
```

Edit `secrets.env` and set your OpenRouter key (one key reaches many models):

```bash
export OPENROUTER_API_KEY="sk-or-..."
# Optional overrides:
# export OPENROUTER_MODEL="google/gemini-3.1-pro-preview"
# export REVIEW_PROVIDER="openrouter"
```

Then wire it into your shell by re-running the installer, and load it:

```bash
./install.sh          # appends a source line for secrets.env to your shell profile
source ~/.zshrc       # or ~/.bashrc, or just open a new terminal
```

### 7.2 secrets.env is gitignored

`secrets.env` is listed in `.gitignore` and **never gets committed.** Only `secrets.env.example` (which contains no real keys) is in the repo. A secret can't safely travel inside a repository, so each machine keeps its own `secrets.env` — paste your key once per machine, or copy the file between your own machines securely.

### 7.3 Using it

The `reviewing-docs` skill auto-triggers when you ask Claude to "review this document against the source" / "verify these claims" / "does this guide hold up." Under the hood it calls `scripts/second-opinion.py`, which the installer copies to `~/.claude/scripts/`. You can also run it by hand:

```bash
# Fidelity review of a guide against the code it documents:
python3 ~/.claude/scripts/second-opinion.py --doc guide.md --source <(cat src/**/*.py) --provider openrouter

# Flag every confident factual claim in an AI-written doc that needs checking:
python3 ~/.claude/scripts/second-opinion.py --doc post.md --provider openrouter --mode review

# Then web-verify those claims with a live-search model:
python3 ~/.claude/scripts/second-opinion.py --doc post.md --provider openrouter --model perplexity/sonar-pro --mode verify
```

The script is **stdlib-only** — no `pip install`, no dependencies. `--doc`, `--source`, and `--rubric` each accept either a file path or literal text (a path that exists is read; anything else is treated as the text itself), so process substitution like `<(cat src/**/*.py)` works for the source.

### 7.4 Providers

One helper, five backends. It auto-detects which to use by which key is set (in the order below), or you force one with `--provider` / `REVIEW_PROVIDER`.

| Provider | Env key | Notes |
|----------|---------|-------|
| `openrouter` | `OPENROUTER_API_KEY` | One key reaches any model. Default and recommended. Routes to Gemini 3.1 Pro by default. |
| `gemini` | `GEMINI_API_KEY` | Google AI Studio direct; has a free tier. Default model `gemini-2.5-flash`. |
| `github-models` | `GITHUB_TOKEN` | Free, rate-limited access to OpenAI/other models via your GitHub token. |
| `openai` | `OPENAI_API_KEY` | OpenAI API, pay per token. Default model `gpt-4o`. |
| `codex` | *(none — needs `codex` CLI on PATH)* | Agentic pass: the Codex CLI reads sources itself. Auto-selected only if no API key is set. |

Auto-detection precedence: `REVIEW_PROVIDER` (if set) → `openrouter` → `gemini` → `github-models` → `openai` → `codex` (if the CLI is on PATH). If none resolve, the script exits `2` and the skill falls back to a Claude-only review.

### 7.5 The two modes

`--mode` controls the rubric the reviewer is given:

- **`review`** (default) — a blind, adversarial reading. With `--source`, it checks the document for **fidelity** to that source: fabrications, overstatements, dropped caveats, misattributions, things the source covered that the doc dropped. Without `--source`, it flags every confidently stated fact that has no citation and marks it `NEEDS EXTERNAL VERIFICATION`, plus overstatements and internal contradictions.
- **`verify`** — a live web citation check. It pulls the checkable claims (statistics, named studies, attributions, dated facts, quotes) and, per claim, returns a verdict (`supported | overstated | misattributed | unsupported-or-fabricated | cannot-verify`) with the source URL it checked. Use a live-search model for this: `--model perplexity/sonar-pro`.

The intended flow for an AI-written doc with no source is two passes: `--mode review` to surface the claims, then `--mode verify` (Sonar) to confirm them on the web.

> **Model choice for verify matters.** Use `perplexity/sonar-pro`, **not** base `perplexity/sonar` — the base tier loops on short documents (it once repeated a single line 496 times). Every call is token-capped and repetition-penalised, and a degenerate-output guard fails loudly (exit `3`) rather than letting a looped response silently pass the gate.

### 7.6 Tuning and model overrides

Model IDs drift. Every default is env-overridable, so a `400` from a retired slug is a one-line fix — check the provider's current model list and set the matching var:

| Variable | Default | Purpose |
|----------|---------|---------|
| `OPENROUTER_MODEL` | `google/gemini-3.1-pro-preview` | Default OpenRouter model |
| `GEMINI_MODEL` | `gemini-2.5-flash` | Gemini-direct model |
| `OPENAI_MODEL` | `gpt-4o` | OpenAI model |
| `GITHUB_MODEL` | `openai/gpt-4o` | GitHub Models model |
| `OPENROUTER_URL` / `GITHUB_MODELS_URL` | *(provider default)* | Override the endpoint if it moves |
| `REVIEW_MAX_TOKENS` | `4000` | Hard cap on output (bounds runaway/looping models) |
| `REVIEW_TEMPERATURE` | `0.2` | Lower = more deterministic review |
| `REVIEW_FREQ_PENALTY` | `0.6` | Discourages degenerate repetition |

`--model` overrides the model for a single call without touching the env var.

### 7.7 CLI flags and exit codes

```
--doc PATH|TEXT       Document under review (required).
--source PATH|TEXT    Source of truth. Optional; rarely needed in --mode verify.
--rubric PATH|TEXT    Extra instructions appended to the rubric.
--provider NAME       openrouter | gemini | github-models | openai | codex.
--model M             Override the model for this call.
--mode review|verify  review = adversarial fidelity; verify = live web citation check.
```

| Exit code | Meaning |
|-----------|---------|
| `0` | Review ran; findings printed to stdout. |
| `2` | No provider/key configured, or an unknown provider was named. Skill falls back to Claude-only review. |
| `3` | Provider/API error, or the model produced degenerate (looping) output. |

Findings go to **stdout**; a one-line banner (`# Second opinion via: <provider> [mode=<mode>]`) and all errors go to **stderr**, so you can pipe the review cleanly into another tool.

If no key is set, the helper exits cleanly (`2`) and the skill does a single-model review instead. Skipping this feature costs you nothing.

---

## 8. Ending a session

**`/session-end` is always the last thing you do before you stop — the closing bookend to the `/session-start` you opened with.** Running it is what carries this session's context, decisions, and lessons forward; if you close Claude Code without it, that work is lost and your next `/session-start` comes up cold. Run it even after a short session — a five-minute fix still produced state worth saving.

When you're done for the day, tell Claude you're wrapping up ("done", "that's it for today", "end session") or run:

```
/session-end
```

This closes out cleanly:

1. **Cognitive briefing** — Claude synthesizes the session's goal, approach, what failed, current state, and what to do next.
2. **Updates the Memory Bank** — rewrites `activeContext.md` (the latest-state snapshot), writes a **new dated file** in `.claude/memory/sessions/`, moves items through `progress.md` (Up next → In progress → Completed, never deleting history), appends to `sessionHistory.md`, records any corrections in `conventions.md`, and logs architectural decisions in `decisionLog.md`.
3. **Research log (optional, in-repo)** — if a `research-log/` directory exists it writes a dated narrative entry (context, what we did, what we found, what changed, what's next) that travels with the repo via GitHub. If no `research-log/` exists, it asks once before creating one — it never silently starts a notebook in someone else's repo.
4. **Linear** — posts a session summary to each touched issue (status unchanged; issues stay open).
5. **Branch context** — updates and commits `.claude/task-context.md` if you're on a feature branch.
6. **README** — updates it if features, setup, or architecture changed this session.
7. **Activity-log MCP** — if connected, logs the session summary; otherwise skips silently.
8. **Uncommitted-changes check** — offers to commit or stash anything left over.

It ends with a summary and a reminder about syncing learned patterns. Your next session picks up exactly where this one left off via `/session-start`.

---

## 9. Day two: updating, syncing, and parallel sessions

### Update the toolkit

Pull the latest and re-run the installer. It's idempotent and backs up first:

```bash
cd ~/flight-plan
git pull
./install.sh
```

Your `# Learned Patterns` in `~/.claude/CLAUDE.md` and your machine-specific settings are preserved through the merge.

### Sync learned patterns across machines

As you correct Claude, lessons accumulate in `~/.claude/CLAUDE.md`. Move them into the repo (and to your other machines) with:

```bash
cd ~/flight-plan
./sync-lessons.sh                          # pushes local lessons into the repo copy
git add CLAUDE.md
git commit -m "sync lessons"
git push

# On another machine:
git pull && ./sync-lessons.sh --pull       # merges repo lessons back into ~/.claude
```

### Run parallel sessions with git worktrees

To work on several branches at once without stashing or conflicts, use git worktrees — each gets its own directory, terminal, and Claude session:

```bash
git worktree add ~/your-project-2 -b <user>/new-api
git worktree add ~/your-project-3 -b <user>/some-fix
```

Open a Claude Code session in each. Each worktree carries its own branch and `.claude/task-context.md`, so there's no cross-talk. See the **`worktrees`** skill for the full setup and conventions.

---

## 10. Troubleshooting

**`install.sh` fails while merging settings.**
The settings merge is done by `python3`. If Python 3 isn't installed or isn't on your `PATH`, this step errors out. Install Python 3.10+ and confirm `python3 --version` works, then re-run `./install.sh`. Your previous config is safe in the timestamped `backups/` folder printed at the top of the run.

**The PR step fails or does nothing.**
Opening a PR needs the GitHub `gh` CLI, authenticated. Check with `gh auth status`; if it isn't logged in, run `gh auth login` and follow the prompts. Without `gh`, you can still push your branch manually (`git push -u origin <user>/<feature>`) and open the PR from the GitHub web UI — the rest of the workflow is unaffected.

**A push seems to be going to the wrong place.**
Every push command shows you the remote and branch and asks for confirmation first. Run `git remote -v` yourself to verify the target before you type "yes." This is deliberate — with multiple repos in flight, "push this" is ambiguous.

**Linear commands aren't doing anything.**
That's expected if you don't have a Linear MCP connected. Linear is opt-in; the commands degrade to no-ops and the workflow continues with `TBD` placeholders. Nothing to fix.

**Cross-model review says "no provider configured."**
The `reviewing-docs` helper needs an API key (for example `OPENROUTER_API_KEY`) set in your environment. Follow [section 7](#7-optional-cross-model-review), or just skip the feature — Claude will do a single-model review instead.

**The activity-log MCP shows "not connected."**
It's either unset or unreachable. If you don't run an aggregator, ignore it — it's off by default. If you do, confirm `ACTIVITY_MCP_URL` points at a running host (reachable from this machine, on your VPN / private network if needed) and that `claude mcp add activity-log "$ACTIVITY_MCP_URL"` succeeded. Either way it fails silently and never blocks your work.

**I want to undo an install or a change.**
Installer backups live in `~/.claude/backups/<timestamp>/`. For code changes, `/checkpoint` creates a named save point before risky operations and `/rollback` restores one; `/undo` reverts the last Claude-made commit safely.

---

That's the whole system. The daily rhythm is just: **`/session-start`, describe what you want, approve the plan, let it execute and verify, `/commit-push-pr`, then `/session-end`.** Everything else — Linear, the activity-log MCP, cross-model review — is optional sugar you can adopt whenever you're ready.
