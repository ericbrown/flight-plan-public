#!/usr/bin/env bash
# scripts/disable-test-on-edit.sh
# Run from a project root to disable auto test runs after file edits.

set -euo pipefail

CONFIG=".claude/project-config.json"

if [ ! -f "$CONFIG" ]; then
  echo "✗ No $CONFIG found."
  exit 1
fi

CURRENT=$(python3 -c "
import json
d = json.load(open('$CONFIG'))
print(d.get('test_on_edit', False))
" 2>/dev/null || echo "False")

if [ "$CURRENT" = "False" ]; then
  echo "Already disabled — test_on_edit is already false in $CONFIG"
  exit 0
fi

python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
d['test_on_edit'] = False
with open('$CONFIG', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"

echo "✓ test_on_edit disabled in $CONFIG"
