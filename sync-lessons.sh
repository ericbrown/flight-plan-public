#!/usr/bin/env bash
# sync-lessons.sh
# Bidirectionally merges "Learned Patterns" between ~/.claude/CLAUDE.md (local)
# and this repo's CLAUDE.md.
#
# Usage:
#   ./sync-lessons.sh              # merge local → repo
#   ./sync-lessons.sh --pull       # merge repo → local (after git pull)
#   ./sync-lessons.sh --both       # merge both directions
#
# How it works:
#   - Lessons are identified by "### " headings under "# Learned Patterns"
#   - Deduplicates by heading name — same heading = same lesson
#   - New local lessons go into repo CLAUDE.md
#   - New repo lessons go into ~/.claude/CLAUDE.md
#   - Never overwrites or removes existing lessons

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CLAUDE="$SCRIPT_DIR/CLAUDE.md"
LOCAL_CLAUDE="$HOME/.claude/CLAUDE.md"
MODE="${1:---local-to-repo}"

# Colors
GREEN='\033[0;32m'
# shellcheck disable=SC2034  # kept for parity with other scripts / future use
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "$LOCAL_CLAUDE" ]; then
  echo "No local ~/.claude/CLAUDE.md found. Nothing to sync."
  exit 0
fi

if [ ! -f "$REPO_CLAUDE" ]; then
  echo "No repo CLAUDE.md found at $REPO_CLAUDE"
  exit 1
fi

# --- Extract lessons from a file ---
# Reads everything from "# Learned Patterns" to end of file (or next top-level heading)
extract_lessons() {
  local file="$1"
  awk '/^# Learned Patterns/{found=1; next} found && /^# /{exit} found{print}' "$file"
}

# --- Extract lesson headings (### lines) ---
extract_headings() {
  local content="$1"
  echo "$content" | grep "^### " | sed 's/^### //'
}

# --- Check if a heading exists in a file ---
heading_exists() {
  local heading="$1"
  local file="$2"
  grep -qF "### $heading" "$file" 2>/dev/null
}

# --- Append new lessons to a file ---
append_lessons() {
  local source_file="$1"
  local dest_file="$2"
  local direction="$3"
  local added=0

  local source_lessons
  source_lessons=$(extract_lessons "$source_file")
  
  if [ -z "$source_lessons" ]; then
    echo "  No lessons found in $direction source."
    return
  fi

  # Parse each lesson block (### heading through next ### or end)
  local current_heading=""
  local current_block=""
  local in_lesson=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^###\  ]]; then
      # Save previous block if we were collecting one
      if [ "$in_lesson" = true ] && [ -n "$current_heading" ]; then
        if ! heading_exists "$current_heading" "$dest_file"; then
          # Ensure there's a "# Learned Patterns" section in dest
          if ! grep -q "^# Learned Patterns" "$dest_file"; then
            echo "" >> "$dest_file"
            echo "# Learned Patterns" >> "$dest_file"
            echo "" >> "$dest_file"
          fi
          echo "" >> "$dest_file"
          echo "### $current_heading" >> "$dest_file"
          echo "$current_block" >> "$dest_file"
          echo "  ${GREEN}+${NC} Added: $current_heading"
          ((added++))
        fi
      fi
      current_heading="${line#### }"
      current_block=""
      in_lesson=true
    elif [ "$in_lesson" = true ]; then
      if [ -n "$current_block" ]; then
        current_block="$current_block
$line"
      else
        current_block="$line"
      fi
    fi
  done <<< "$source_lessons"

  # Handle last block
  if [ "$in_lesson" = true ] && [ -n "$current_heading" ]; then
    if ! heading_exists "$current_heading" "$dest_file"; then
      if ! grep -q "^# Learned Patterns" "$dest_file"; then
        echo "" >> "$dest_file"
        echo "# Learned Patterns" >> "$dest_file"
        echo "" >> "$dest_file"
      fi
      echo "" >> "$dest_file"
      echo "### $current_heading" >> "$dest_file"
      echo "$current_block" >> "$dest_file"
      echo "  ${GREEN}+${NC} Added: $current_heading"
      ((added++))
    fi
  fi

  if [ "$added" -eq 0 ]; then
    echo "  No new lessons to add ($direction)."
  else
    echo "  ${GREEN}$added lesson(s) added ($direction).${NC}"
  fi
}

echo "Syncing learned patterns..."
echo ""

case "$MODE" in
  --local-to-repo|"")
    echo "Local → Repo:"
    append_lessons "$LOCAL_CLAUDE" "$REPO_CLAUDE" "local→repo"
    ;;
  --pull|--repo-to-local)
    echo "Repo → Local:"
    append_lessons "$REPO_CLAUDE" "$LOCAL_CLAUDE" "repo→local"
    ;;
  --both)
    echo "Local → Repo:"
    append_lessons "$LOCAL_CLAUDE" "$REPO_CLAUDE" "local→repo"
    echo ""
    echo "Repo → Local:"
    append_lessons "$REPO_CLAUDE" "$LOCAL_CLAUDE" "repo→local"
    ;;
  *)
    echo "Usage: ./sync-lessons.sh [--local-to-repo | --pull | --both]"
    exit 1
    ;;
esac

echo ""
echo "Done. To push to remote:"
echo "  git add CLAUDE.md && git commit -m 'sync lessons' && git push"
