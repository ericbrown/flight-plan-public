#!/usr/bin/env bash
# hooks/session-scan.sh
# SessionStart hook — surfaces, before any work begins:
#   1. Interfaces (exports / signatures) changed since your LAST session
#   2. Deprecated patterns from .claude/memory/deprecations.md appearing in recent changes
#
# Stays completely silent when there's nothing to report or the repo isn't set up
# for Flight Plan.
#
# No `set -e`: grep returning 1 on no-match is normal control flow here.

PROJECT_DIR="$(pwd)"

# Only operate inside a git repo
git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# ── Watchdog: never block session start ───────────────────────────────────────
# Uses only builtins (sleep, kill) so it works on macOS without coreutils.
( sleep 10; kill -TERM $$ 2>/dev/null ) & _WD=$!
trap 'kill $_WD 2>/dev/null; exit 0' EXIT
trap 'kill $_WD 2>/dev/null; exit 0' TERM

# ── Diff base: persist last-session HEAD per project ──────────────────────────
# Covers ALL commits since you last sat down, not just HEAD~1.
STATE_DIR="$HOME/.claude/state"
mkdir -p "$STATE_DIR" 2>/dev/null || true
_KEY=$(printf '%s' "$PROJECT_DIR" | cksum | cut -d' ' -f1)
_REF_FILE="$STATE_DIR/last-session-$_KEY"
_PREV_REF=$(cat "$_REF_FILE" 2>/dev/null)
git -C "$PROJECT_DIR" rev-parse HEAD > "$_REF_FILE" 2>/dev/null || true

DIFF_BASE="$_PREV_REF"
if [ -z "$DIFF_BASE" ] || ! git -C "$PROJECT_DIR" cat-file -e "${DIFF_BASE}^{commit}" 2>/dev/null; then
  DIFF_BASE="HEAD~1"
fi
# Nothing to diff against (e.g. single-commit repo) → quit silently
git -C "$PROJECT_DIR" cat-file -e "${DIFF_BASE}^{commit}" 2>/dev/null || exit 0

# ── Contract / interface-change detection ─────────────────────────────────────
_CHANGED=$(git -C "$PROJECT_DIR" diff "$DIFF_BASE" --name-only 2>/dev/null)
if [ -n "$_CHANGED" ]; then
  # Watch paths: built-in defaults unioned with optional watch_paths from project-config.json
  _CFG="$PROJECT_DIR/.claude/project-config.json"
  _CFG_PATHS=""
  if [ -f "$_CFG" ]; then
    _CFG_PATHS=$(python3 -c "
import json, sys
try:
    cfg = json.load(open(sys.argv[1]))
    wp = cfg.get('watch_paths') or []
    print('\n'.join(p for p in wp if isinstance(p, str)))
except Exception:
    pass
" "$_CFG" 2>/dev/null)
  fi
  _WATCH_PATHS=$(printf '%s\napi/\nschema/\ntypes/\ncontracts/\nlib/\nsrc/api/\nsrc/lib/\nsrc/types/\nsrc/schema/' "$_CFG_PATHS" | sort -u)

  _HDR=0
  while IFS= read -r _FILE; do
    [ -z "$_FILE" ] && continue

    # Match watch paths or always-watched extensions
    _MATCH=0
    case "$_FILE" in *.d.ts|*.proto|*.graphql) _MATCH=1 ;; esac
    if [ "$_MATCH" -eq 0 ]; then
      while IFS= read -r _PAT; do
        [ -z "$_PAT" ] && continue
        case "$_FILE" in "$_PAT"*) _MATCH=1; break ;; esac
      done <<< "$_WATCH_PATHS"
    fi
    [ "$_MATCH" -eq 0 ] && continue

    # Skip deletions
    [ ! -f "$PROJECT_DIR/$_FILE" ] && continue

    # Added/changed export or signature lines.
    # TS:     export interface|type|class|abstract class|function|const|enum|default
    # Python: top-level def or class (no leading whitespace)
    # OpenAPI/GraphQL schema roots
    _EXPORTS=$(git -C "$PROJECT_DIR" diff "$DIFF_BASE" -- "$_FILE" 2>/dev/null \
      | grep '^+' | grep -v '^+++' \
      | grep -E '^\+(export (interface|type|class|abstract class|function|const|enum|default)|def [A-Za-z_]|class [A-Za-z]|openapi:|swagger:|paths:|components:)')

    if [ -n "$_EXPORTS" ]; then
      if [ "$_HDR" -eq 0 ]; then
        echo "### Interfaces changed since last session — review before starting work"
        echo ""
        _HDR=1
      fi
      echo "**$_FILE**"
      echo "$_EXPORTS" | sed 's/^+/  /'
      echo ""
    fi
  done <<< "$_CHANGED"

  [ "$_HDR" -eq 1 ] && { echo "---"; echo ""; }
fi

# ── Deprecation detection ─────────────────────────────────────────────────────
_DEPR_SCRIPT="$HOME/.claude/scripts/deprecation_scan.py"
if [ -f "$PROJECT_DIR/.claude/memory/deprecations.md" ] && [ -f "$_DEPR_SCRIPT" ]; then
  python3 "$_DEPR_SCRIPT" "$PROJECT_DIR" "$DIFF_BASE" 2>/dev/null || true
fi

exit 0
