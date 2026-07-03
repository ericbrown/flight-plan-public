#!/usr/bin/env bash
# tests/session_scan.sh
# Behavioral test for hooks/session-scan.sh contract/interface-change detection:
# surfaces a changed watched export, ignores non-watched files, silent on rerun and
# in a non-git directory.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO/hooks/session-scan.sh"
TH="$(mktemp -d)"
export HOME="$TH"                 # isolate the per-project state dir under a temp HOME
trap 'rm -rf "$TH"' EXIT

fail=0
ok()  { printf 'ok   - %s\n' "$1"; }
bad() { printf 'FAIL - %s\n' "$1"; fail=1; }

SB="$TH/proj"; mkdir -p "$SB/src/api" "$SB/docs"
cd "$SB" || exit 1
git init -q; git config user.email t@t; git config user.name t
echo init > README.md; git add -A; git commit -qm c0
printf 'export function foo() {}\n' > src/api/x.ts     # watched
printf 'plain docs\n' > docs/notes.md                  # not watched
git add -A; git commit -qm c1

KEY=$(printf '%s' "$SB" | cksum | cut -d' ' -f1)
mkdir -p "$TH/.claude/state"
git rev-parse HEAD~1 > "$TH/.claude/state/last-session-$KEY"

out1="$(cd "$SB" && bash "$HOOK")"
echo "$out1" | grep -q "src/api/x.ts"        && ok "surfaces watched export"        || bad "did not surface watched export"
echo "$out1" | grep -q "export function foo" && ok "shows the changed signature"     || bad "missing changed signature line"
echo "$out1" | grep -q "docs/notes.md"       && bad "leaked non-watched file"        || ok "ignores non-watched file"

out2="$(cd "$SB" && bash "$HOOK")"             # ref advanced -> silent
[ -z "$out2" ] && ok "silent on rerun (ref advanced)" || bad "not silent on rerun"

PLAIN="$TH/plain"; mkdir -p "$PLAIN"
out3="$(cd "$PLAIN" && bash "$HOOK")"
[ -z "$out3" ] && ok "silent in non-git directory" || bad "produced output in non-git dir"

if [ "$fail" -ne 0 ]; then echo "session_scan: FAILED"; exit 1; fi
echo "session_scan: PASSED"
