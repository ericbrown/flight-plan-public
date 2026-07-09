# Attribution

The four delegate skills bundled here — `codex/`, `claude-code/`, `opencode/`, and
`grok-build/` — plus the `harden` command/skill are adapted from Jarad Johnson's
**cli-skills** project:

- Upstream: https://github.com/Jdjohnson/skills
- License: MIT
- Copyright (c) 2026 Jarad Johnson

## Adaptations made for flight-plan

These copies are not verbatim. The following changes were made while porting them into
this repo:

- **Linux path support.** The upstream safety rails were anchored to macOS `/Users/...`
  paths. Each delegate script now carries a `/home/...` sibling alongside every
  `/Users/...` secret-redaction pattern (downloaded-source-package detection and the
  per-tool `auth.json` path scrubbers), and the unsafe-cwd guard now treats `/home` the
  same as `/Users` so a delegated agent cannot be pointed at `/home` as its working
  directory on Linux. CLI binary discovery also adds the common Linux locations
  (`/usr/local/bin`, `/usr/bin`, `~/.local/bin`) alongside the Homebrew path. The macOS
  behavior is preserved so the skills still work if run on a Mac. `grok-build` additionally
  drops the upstream author's hardcoded `/Users/<author>/.grok/bin/grok` default candidate
  in favor of the generic `~/.grok/bin/grok` plus the Linux locations.
- **Invocation-path rewrite.** Every `SKILL.md` invocation example was rewritten from the
  upstream `.dot-skills/<name>/scripts/...` layout to
  `~/.claude/skills/<name>/scripts/...`, which is where flight-plan's installer places
  these skills.
- **Orchestrator framing.** First-person-tool and Mac-app framing (and direct references
  to the upstream author) were genericized to neutral orchestrator phrasing: delegation
  runs "from an orchestrating agent (Codex, OpenCode, or another local agent)" and
  operator-facing instructions refer to "the operator" rather than a named person.
- **Dropped `agents/openai.yaml`.** The upstream agent definition file was not vendored.

## `harden` (cherry-picked and adapted)

`commands/harden.md` and `skills/harden.md` adapt the `harden` verify/revise primitive
from the same upstream repo (the `harden` mode of the upstream `run` skill). This is an
adaptation, not a verbatim vendor:

- **Kept:** the verify/revise idea — frame the seed as one falsifiable thesis, set an
  explicit proof bar (strong evidence, falsifier, fragile claims), run one or two bounded
  verify/revise passes (a third only for high stakes), lock `hardened/final.md` +
  `hardened/one-paragraph-summary.md`, and ask only questions that change the proof bar.
- **Dropped:** all runner machinery flight-plan does not have — the `run-workflow` CLI,
  `blueprint.json`, `session.md`/`progress.md` runtime scaffolding, the runner-handoff
  command set, and launch modes. The loop is conversational, not orchestrated.
- **Rerouted:** the upstream "seed too foggy → route to `steelman`" step points instead
  at sharpening the thesis (or flight-plan's `/plan-context`), since flight-plan has no
  `steelman` skill.

The delegate scripts remain stdlib-only Python, and all upstream safety scaffolding is
preserved: prompts are never concatenated into shell commands, `--dangerously-*` flags are
never passed, the audit-prompt gate blocks client-private data before any external handoff,
and secrets are redacted from all captured output.

## MIT License (upstream)

```
MIT License

Copyright (c) 2026 Jarad Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
