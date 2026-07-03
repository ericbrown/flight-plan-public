#!/usr/bin/env bash
# scripts/enable-test-on-edit.sh
# Run from a project root to enable auto test runs after file edits.
# Requires .claude/project-config.json (created by /memory-init).

set -euo pipefail

CONFIG=".claude/project-config.json"

if [ ! -f "$CONFIG" ]; then
  echo "✗ No $CONFIG found. Run /memory-init first to set up this project."
  exit 1
fi

# Check current state
CURRENT=$(python3 -c "
import json
d = json.load(open('$CONFIG'))
print(d.get('test_on_edit', False))
" 2>/dev/null || echo "False")

if [ "$CURRENT" = "True" ]; then
  echo "Already enabled — test_on_edit is already true in $CONFIG"
  exit 0
fi

# Check a test command exists
TEST_CMD=$(python3 -c "
import json
d = json.load(open('$CONFIG'))
print(d.get('commands', {}).get('test') or '')
" 2>/dev/null || echo "")

if [ -z "$TEST_CMD" ]; then
  echo "No test command set in $CONFIG."
  printf "What command runs your tests? (e.g. pytest, bun test, npm test): "
  read -r TEST_CMD
  if [ -z "$TEST_CMD" ]; then
    echo "No command entered. Exiting."
    exit 1
  fi
  python3 << PYEOF
import json
with open('$CONFIG') as f:
    d = json.load(f)
if not isinstance(d.get('commands'), dict):
    d['commands'] = {}
d['commands']['test'] = '$TEST_CMD'
with open('$CONFIG', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
PYEOF
  echo "✓ Saved test command to $CONFIG"
fi

# Flip the flag
python3 << PYEOF
import json
with open('$CONFIG') as f:
    d = json.load(f)
d['test_on_edit'] = True
with open('$CONFIG', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
PYEOF

echo "✓ test_on_edit enabled in $CONFIG"
echo "  Test command: $TEST_CMD"
echo "  Claude will now run tests automatically after each file edit."
