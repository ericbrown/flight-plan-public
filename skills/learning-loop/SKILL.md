# Skill: Learning Loop

## When this skill activates

Activates automatically **whenever the user corrects the agent** — "no, that's wrong,"
"don't do X, do Y," "I told you already," or any correction of behavior, a fact, or an
approach. Also runs as a session-end / nightly backstop over recent session logs.

The point: a static agent makes the same mistake forever. This turns every correction
into permanent improvement, without hand-writing rules — but only once a correction has
proven it's a *pattern*, not a one-off.

## Workflow

**Step 1 — Record the correction the moment it happens.**
```
python3 skills/learning-loop/scripts/cognition.py correction \
  --subject "<short, stable anchor for this correction>" \
  --wrong "<what the agent did wrong>" \
  --correct "<what the user said to do instead>" \
  --keywords "a,b,c"
```
Keep the **subject** stable and consistent across occurrences — it's the dedup anchor
(fuzzy-matched ≥ 0.8, so minor wording drift is fine). The same recurring mistake must
map to the same subject to count toward promotion.

**Step 2 — Let it decide.**
- First occurrence: logged quietly with a 7-day TTL. No rule written yet.
- Recurs (same subject): counter increments, TTL refreshes.
- **3rd occurrence: auto-promotes** — escapes the TTL and is appended to
  `.claude/memory/conventions.md` as a permanent learned pattern. flight-plan's existing
  self-improvement loop can then promote genuinely universal ones up to CLAUDE.md.

**Step 3 — Backstop (session end / nightly).**
Read the last ~2 days of session logs and record any corrections live-capture missed,
using a consistent subject so they count toward the same threshold. Then:
```
python3 skills/learning-loop/scripts/cognition.py sweep   # drop expired, unpromoted
```

## Review
- `cognition.py list` — active corrections and their counts (n/3), plus promoted ones.
- `cognition.py list --all` — includes expired.

## Notes
- The store is `.claude/cognition.db` (add to `.gitignore` — local accumulating state).
- Promotion target and DB path are overridable with `--target` / `--db`.
- Don't force a rule on the first correction — the 3× threshold is what keeps
  one-off preferences out of the permanent patterns.
- Inspired by an internal `evolution.py` learning loop; the LifeOS `cognition.py` is the
  working reference implementation. See `docs/skill-ideas-from-aiden-lucille.md`.
