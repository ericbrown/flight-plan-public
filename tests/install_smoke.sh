#!/usr/bin/env bash
# tests/install_smoke.sh
# Runs install.sh into a throwaway HOME and asserts it installed the expected
# artifacts, merged the SessionStart hook, recorded the version, and is idempotent.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TH="$(mktemp -d)"
trap 'rm -rf "$TH"' EXIT

fail=0
ok()   { printf 'ok   - %s\n' "$1"; }
bad()  { printf 'FAIL - %s\n' "$1"; fail=1; }

HOME="$TH" bash "$REPO/install.sh" >"$TH/install1.log" 2>&1 \
  && ok "install.sh run 1 exits 0" || bad "install.sh run 1 nonzero (see below)"

[ -x "$TH/.claude/hooks/session-scan.sh" ]        && ok "session-scan.sh installed +x"     || bad "session-scan.sh missing/not executable"
[ -f "$TH/.claude/scripts/deprecation_scan.py" ]  && ok "deprecation_scan.py installed"     || bad "deprecation_scan.py missing"
[ -f "$TH/.claude/scripts/second-opinion.py" ]    && ok "second-opinion.py installed"       || bad "second-opinion.py missing"

ver_repo="$(tr -d '[:space:]' < "$REPO/VERSION")"
ver_inst="$(tr -d '[:space:]' < "$TH/.claude/.flight-plan-version" 2>/dev/null || true)"
[ -n "$ver_inst" ] && [ "$ver_inst" = "$ver_repo" ] \
  && ok "recorded version matches VERSION ($ver_repo)" \
  || bad "recorded version '$ver_inst' != VERSION '$ver_repo'"

python3 - "$TH/.claude/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
ss = d.get("hooks", {}).get("SessionStart", [])
cmds = [h.get("command", "") for g in ss for h in g.get("hooks", [])]
hits = [c for c in cmds if "session-scan.sh" in c]
print("ok   - SessionStart hook registered" if len(hits) == 1
      else f"FAIL - expected 1 SessionStart session-scan hook, got {len(hits)}")
sys.exit(0 if len(hits) == 1 else 1)
PY
[ $? -eq 0 ] || fail=1

# Idempotency: a second install must not duplicate the SessionStart group.
HOME="$TH" bash "$REPO/install.sh" >"$TH/install2.log" 2>&1 \
  && ok "install.sh run 2 exits 0" || bad "install.sh run 2 nonzero"
groups=$(python3 -c "import json;print(len(json.load(open('$TH/.claude/settings.json'))['hooks'].get('SessionStart',[])))")
[ "$groups" = "1" ] && ok "SessionStart not duplicated on re-run" || bad "SessionStart duplicated ($groups groups)"

if [ "$fail" -ne 0 ]; then
  echo "--- install1.log (tail) ---"; tail -20 "$TH/install1.log"
  echo "install_smoke: FAILED"; exit 1
fi
echo "install_smoke: PASSED"
