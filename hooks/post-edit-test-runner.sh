#!/usr/bin/env bash
# hooks/post-edit-test-runner.sh
# PostToolUse hook — fires after Edit/Write/MultiEdit tool calls.
# Auto-runs scoped tests after source file edits, feeds output back to Claude.
# Opt-in per project: set "test_on_edit": true in .claude/project-config.json
# Input: tool result JSON via stdin.

set -euo pipefail

TOOL_INPUT=$(cat)
FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('file_path') or d.get('path') or d.get('filePath') or '')
" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Walk up from CWD to find project root (contains .claude/project-config.json)
PROJECT_ROOT="$PWD"
SEARCH_DIR="$PWD"
while [ "$SEARCH_DIR" != "/" ]; do
  if [ -f "$SEARCH_DIR/.claude/project-config.json" ]; then
    PROJECT_ROOT="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

CONFIG="$PROJECT_ROOT/.claude/project-config.json"
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

# Check opt-in flag
ENABLED=$(python3 -c "
import json
try:
  d = json.load(open('$CONFIG'))
  print('yes' if d.get('test_on_edit') else 'no')
except:
  print('no')
" 2>/dev/null || echo "no")

if [ "$ENABLED" != "yes" ]; then
  exit 0
fi

# Skip non-source files — config, docs, data formats
EXT="${FILE_PATH##*.}"
case "$EXT" in
  md|json|yaml|yml|toml|lock|txt|env|gitignore|dockerignore|log|csv|sql)
    exit 0
    ;;
esac

# Get test command from project-config — prefer test_single (scoped), fall back to test
TEST_CMD=$(python3 -c "
import json
d = json.load(open('$CONFIG'))
cmds = d.get('commands', {})
print(cmds.get('test_single') or cmds.get('test') or '')
" 2>/dev/null || echo "")

if [ -z "$TEST_CMD" ]; then
  exit 0
fi

echo ""
echo "┌─ test-runner: $(basename "$FILE_PATH") ──────────────────────"
cd "$PROJECT_ROOT"
eval "$TEST_CMD" 2>&1 || true
echo "└──────────────────────────────────────────────────────────────"
echo ""

exit 0
