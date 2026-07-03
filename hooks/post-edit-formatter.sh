#!/usr/bin/env bash
# hooks/post-edit-formatter.sh
# PostToolUse hook — fires after file edit tool calls (Write, Edit, MultiEdit).
# Auto-formats the edited file to avoid CI failures from formatting drift.
# Input: tool result JSON via stdin.

set -euo pipefail

TOOL_INPUT=$(cat)
FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
# Try common field names used by different tool versions
print(d.get('file_path') or d.get('path') or d.get('filePath') or '')
" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"

# --- Run formatter based on file type ---
case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs)
    # Try prettier, then eslint --fix
    if command -v prettier &>/dev/null; then
      prettier --write "$FILE_PATH" --log-level silent 2>/dev/null || true
    elif command -v npx &>/dev/null; then
      npx --yes prettier --write "$FILE_PATH" --log-level silent 2>/dev/null || true
    fi
    ;;
  py)
    if command -v ruff &>/dev/null; then
      ruff format "$FILE_PATH" --quiet 2>/dev/null || true
    elif command -v black &>/dev/null; then
      black "$FILE_PATH" --quiet 2>/dev/null || true
    fi
    ;;
  go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  rs)
    if command -v rustfmt &>/dev/null; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  sh|bash)
    if command -v shfmt &>/dev/null; then
      shfmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *)
    # Unknown type — skip silently
    ;;
esac

exit 0
