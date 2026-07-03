# Changelog

All notable changes to Flight Plan are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Every release to `main` bumps the version in three places that must agree:
`VERSION`, the README badge (`**vX.Y.Z**`), and the latest entry here. CI enforces it.

## [Unreleased]

## [0.3.0] - 2026-07-02

### Added
- **`/harden` command + skill** — a bounded verify/revise primitive for an existing
  thesis, argument, draft, or plan. Frames the seed as one falsifiable thesis, sets an
  explicit proof bar (strong evidence, falsifier, fragile claims), runs one or two
  conversational verify/revise passes (a third only for high stakes), and locks
  `hardened/final.md` + `hardened/one-paragraph-summary.md`. Companion to `/verify`:
  `/verify` checks that code works, `/harden` checks that an idea holds up. Cherry-picked
  and adapted from the `harden` primitive in Jarad Johnson's cli-skills (MIT); the upstream
  runner machinery (`run-workflow` CLI, `blueprint.json`, launch modes) was deliberately
  dropped in favor of a self-contained conversational loop. See `skills/ATTRIBUTION.md`.

## [0.2.0] - 2026-07-02

### Added
- **Local-agent delegate skills** — three directory-based skills that hand work
  off to a local CLI: `codex` (deep review/planning/scoped edits via the Codex CLI,
  GPT-5.5), `claude-code` (bounded reverse-orchestration via the Claude Code CLI),
  and `opencode` (cheap/fast work via the OpenCode CLI, GLM-5.2). Adapted from
  Jarad Johnson's cli-skills (MIT); see `skills/ATTRIBUTION.md`.
- **Directory-based skills support** — `install.sh` Step 5 now installs both flat
  `skills/*.md` files and directory skills (a folder with `SKILL.md`, `scripts/`,
  and `tests/`), recursively copying each directory and marking its `scripts/*.py`
  delegate scripts executable.

## [0.1.0] - 2026-06-28

First versioned release. Captures the workflow system as it stands plus the Tier 1
and Tier 2 ports from an internal toolkit.

### Added
- **Versioning** — `VERSION` file, this changelog, a README version badge, and
  `install.sh` now prints the installed version and records it at
  `~/.claude/.flight-plan-version`.
- **Test suite + CI** (`.github/workflows/tests.yml`) — shellcheck over the shell
  scripts/hooks, a pytest suite for `scripts/deprecation_scan.py`, an `install.sh`
  smoke/idempotency test, and a command/skill frontmatter validator.
- **branch-guard CI** (`.github/workflows/branch-guard.yml`) — a PR to `main` from
  any branch other than `dev` fails; a `version-consistency` job asserts
  `VERSION` / README badge / CHANGELOG agree. Reusable template at
  `templates/github/branch-guard.yml`, scaffolded by `/branch-model`.
- **Session-start scan** (`hooks/session-scan.sh`) — surfaces interfaces (exports /
  signatures) changed since your last session, and warns when recently-changed code
  uses a pattern recorded as `ACTIVE` in `.claude/memory/deprecations.md`.
- **Deprecation tracking** — `memory-template/deprecations.md`,
  `scripts/deprecation_scan.py`, and the `/deprecate` command.
- **Branch model** — the `main ← dev ← feature` model, with `/branch-model` to set it
  up in any project.

[Unreleased]: https://github.com/ericbrown/flight-plan-public/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/ericbrown/flight-plan-public/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ericbrown/flight-plan-public/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ericbrown/flight-plan-public/releases/tag/v0.1.0
