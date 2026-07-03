#!/usr/bin/env bash
# hooks/destructive-ops-guard.sh
# PreToolUse hook — fires before bash tool calls.
# Creates a checkpoint tag + stashes dirty tree before destructive git operations.
# Input: the bash command is passed via stdin as JSON: {"command": "..."}

set -euo pipefail

# Read the command from stdin (Claude Code passes tool input as JSON)
TOOL_INPUT=$(cat)
COMMAND=$(echo "$TOOL_INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- Detect dangerous patterns ---
IS_DANGEROUS=false
DANGER_REASON=""

case "$COMMAND" in
  *"git reset --hard"*)
    IS_DANGEROUS=true
    DANGER_REASON="git reset --hard"
    ;;
  *"rm -rf"*)
    IS_DANGEROUS=true
    DANGER_REASON="rm -rf"
    ;;
  *"git push --force"*|*"git push -f "*)
    IS_DANGEROUS=true
    DANGER_REASON="force push"
    ;;
  *"git clean -fd"*|*"git clean -f"*)
    IS_DANGEROUS=true
    DANGER_REASON="git clean"
    ;;
  *"DROP TABLE"*|*"drop table"*)
    IS_DANGEROUS=true
    DANGER_REASON="SQL DROP TABLE"
    ;;
esac

if [ "$IS_DANGEROUS" = false ]; then
  exit 0
fi

# --- Create checkpoint before proceeding ---
TIMESTAMP=$(date +%Y%m%d-%H%M)
TAG_NAME="checkpoint-before-$TIMESTAMP"

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "[guard] Warning: $DANGER_REASON detected but not in a git repo. Proceeding without checkpoint." >&2
  exit 0
fi

# Stash dirty files if any
DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIRTY" -gt 0 ]; then
  git stash push -m "auto-stash before $DANGER_REASON ($TIMESTAMP)" 2>/dev/null || true
  echo "[guard] Stashed $DIRTY modified file(s) as: auto-stash before $DANGER_REASON ($TIMESTAMP)" >&2
fi

# Create checkpoint tag
git tag "$TAG_NAME" 2>/dev/null || true
echo "[guard] Checkpoint created: $TAG_NAME (before $DANGER_REASON)" >&2
echo "[guard] To restore: git checkout $TAG_NAME  or  /rollback $TAG_NAME" >&2

# Allow the operation to proceed
exit 0
