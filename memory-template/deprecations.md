# Deprecations

Patterns, libraries, and endpoints you've formally stopped using in this project.
**Append-only** — never edit or delete past entries; mark them `RESOLVED` instead.

The SessionStart scan (`hooks/session-scan.sh` → `scripts/deprecation_scan.py`) reads the
`ACTIVE` entries here and warns if any appear in code changed since your last session.
Record a new one with `/deprecate <name>`.

Each entry:

```
## YYYY-MM-DD — DEPRECATED: <name>
Replaced by: <what to use instead>
Why: <one line — the reason it's deprecated>
Status: ACTIVE        # ACTIVE = warn on use; RESOLVED = migration complete, stop warning
Ticket: <PROJ-123 or none>
```

The `<name>` drives keyword matching — use the literal import/symbol/endpoint string
(e.g. `axios`, `passport.js`, `/api/v1/payments`) so the scan can find it in diffs.

---

## 2026-01-01 — DEPRECATED: axios
Replaced by: the native `fetch` API (Node 18+ / browsers)
Why: extra dependency; `fetch` covers our use and trims bundle size.
Status: RESOLVED
Ticket: none

<!-- ^ example entry (RESOLVED, so it never fires). Delete it once you add real ones. -->
