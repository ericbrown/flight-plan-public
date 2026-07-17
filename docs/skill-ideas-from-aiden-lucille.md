# Skill Ideas from aiden + Lucille — for Flight Plan

Reviewed 2026-07-17: [taracodlabs/aiden](https://github.com/taracodlabs/aiden) (AGPL — borrow patterns, not code) and an internal agent platform. Both have a meta/self-improvement layer. This maps the pieces that fit **Flight Plan's actual nature — a Claude Code workflow toolkit** (commands, auto-trigger skills, Memory Bank, hooks, Linear sync, multi-CLI delegation: claude/codex/grok/opencode + second-opinion).

> Note: an earlier note mis-filed Flight Plan as a "provider router" (Ollama local-first / modelDiscovery / VRAM-aware selection). That's wrong — FP delegates to CLI *tools*, not raw model APIs, so a provider router doesn't fit. Those ideas belong to a tool that calls model APIs directly.

## What fits (ranked)

### 1. Learning Loop — corrections auto-promote to Learned Patterns (TOP)
- **FP today:** `sync-lessons.sh` manually merges hand-written "Learned Patterns" between `~/.claude/CLAUDE.md` and the repo. There's no way to notice a *recurring* correction and promote it automatically.
- **The skill:** a small SQLite corrections store — dedup by fuzzy subject signature, a 7-day TTL, `record()` increments + refreshes on recurrence, and after the SAME correction recurs **3×** it auto-promotes into the Learned Patterns (which `sync-lessons.sh` then syncs to CLAUDE.md). Capture two ways: **live** (a hook/command records when the user corrects the agent) + a **session-end/nightly scrape** of session logs for what live-capture missed.
- **Why top:** FP *defines* the Learned Patterns that shape every project you touch. This turns that from hand-curated into self-improving — the highest-leverage change available here.
- **Effort:** small. One script + wire promotion into the Learned-Patterns section + a capture hook.

### 2. Harness-first discipline (TOP)
- **FP today:** `tdd`, `systematic-debugging`, `verification-before-completion`, `test-and-fix`.
- **The gap:** no "reproduce the observed bug on the REAL code path *before* fixing" skill. TDD tests a contract; systematic-debugging investigates; neither forces a failing reproduction rig first.
- **The skill:** before a non-trivial fix, write a harness that runs the real production path with the failure injected and **fails before the fix**; only then fix; the harness stays as a regression lock. A new `skills/harness-first.md` slotting between systematic-debugging and tdd.
- **Precondition for AutoFix (#3).**
- **Effort:** small — a skill doc + a `tests/harness/` convention.

### 3. AutoFix (strong)
- **FP today:** `test-and-fix` (manual iterate-until-green).
- **The skill:** error source (CI log / issue / failing test) → generate a fix → apply → **verify against the harness suite** (reject if a NEW failure appears) → open a PR (auto-merge only if small + green). Uses FP's existing multi-CLI delegation to generate/verify.
- **Depends on #2** — don't ship without harnesses; the agent generates plausible-but-wrong fixes otherwise.
- **Effort:** medium.

### 4. Flight Plan Doctor (practical)
- **FP today:** `install.sh` (safe re-run) but no health check.
- **The skill:** a `/doctor` command that validates the install + environment — memory bank present, hooks installed, the delegate CLIs (claude/codex/grok/opencode) available + authed, Linear configured, `secrets.env` present, settings merged. Checks are pure functions → `CheckResult{name, status, detail}`.
- Catches "grok CLI not authed" / "hooks didn't install" before they cause a confusing mid-session failure. No auto-repair — FP has no data pipelines to repair.
- **Effort:** small.

## Situational
### costTracker — per-delegation cost ledger
FP delegates to several paid CLIs (grok/codex/opencode). A small ledger logging tokens/cost per delegation + second-opinion, so a multi-tool session's cost is visible.

## What does NOT fit
- **Auto-repair of data syncs, decay/consolidation of a graph memory, anticipatory calendar prep, audio briefings** — all data/service-specific. FP's memory is per-project markdown (a Memory Bank), not a graph DB or running pipelines.
- **Provider router / Ollama local-first / modelDiscovery VRAM-aware** — FP delegates to CLI *tools*, not raw model APIs.

## Build order (if pursued)
1. **Learning Loop** — highest leverage, small.
2. **Harness-first** — small, unlocks #3.
3. **AutoFix** — medium, needs #2.
4. **Doctor** — small, independent.
5. **costTracker** — whenever.

All generalize cleanly (no project-specific coupling), which is exactly why they fit a portable, public-facing toolkit.
