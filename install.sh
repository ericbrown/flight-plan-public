#!/usr/bin/env bash
# install.sh
# Installs flight-plan into ~/.claude/
# Safe to re-run — backs up existing config, preserves machine-specific settings,
# merges learned patterns instead of overwriting them.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "unknown")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
printf "${BOLD}Flight Plan Installer${NC}  v%s\n" "$VERSION"
echo "========================="
echo ""

# ── Step 1: Backup existing config ────────────────────────────────────────────
if [ -d "$CLAUDE_DIR" ]; then
  echo "Backing up ~/.claude/ → $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  for f in CLAUDE.md settings.json; do
    [ -f "$CLAUDE_DIR/$f" ] && cp "$CLAUDE_DIR/$f" "$BACKUP_DIR/$f" && echo "  backed up: $f"
  done
  for d in commands agents skills hooks scripts; do
    [ -d "$CLAUDE_DIR/$d" ] && cp -r "$CLAUDE_DIR/$d" "$BACKUP_DIR/$d" && echo "  backed up: $d/"
  done
else
  mkdir -p "$CLAUDE_DIR"
fi

echo ""

# ── Step 2: Directory structure ───────────────────────────────────────────────
echo "Creating directories..."
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/scripts"

# ── Step 3: Commands ──────────────────────────────────────────────────────────
echo "Installing commands..."
for f in "$SCRIPT_DIR/commands/"*.md; do
  name=$(basename "$f")
  cp "$f" "$CLAUDE_DIR/commands/$name"
  printf "  ${GREEN}+${NC} commands/%s\n" "$name"
done

# ── Step 4: Agents ────────────────────────────────────────────────────────────
echo "Installing agents..."
for f in "$SCRIPT_DIR/agents/"*.md; do
  name=$(basename "$f")
  cp "$f" "$CLAUDE_DIR/agents/$name"
  printf "  ${GREEN}+${NC} agents/%s\n" "$name"
done

# ── Step 5: Skills ────────────────────────────────────────────────────────────
# Flat skills (skills/*.md) install as single files; directory skills
# (skills/<name>/ with SKILL.md + scripts/ + tests/) install as whole trees.
echo "Installing skills..."
for f in "$SCRIPT_DIR/skills/"*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  cp "$f" "$CLAUDE_DIR/skills/$name"
  printf "  ${GREEN}+${NC} skills/%s\n" "$name"
done
for d in "$SCRIPT_DIR/skills/"*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  # Clear any prior install first. `cp -r src/ dest` nests to dest/name/name
  # when dest already exists, so a re-install would double the path.
  rm -rf "$CLAUDE_DIR/skills/$name"
  cp -r "$d" "$CLAUDE_DIR/skills/$name"
  for py in "$CLAUDE_DIR/skills/$name/scripts/"*.py; do
    [ -f "$py" ] && chmod +x "$py"
  done
  printf "  ${GREEN}+${NC} skills/%s/ (directory skill)\n" "$name"
done

# ── Step 6: Hooks ─────────────────────────────────────────────────────────────
echo "Installing hooks..."
for f in "$SCRIPT_DIR/hooks/"*.sh; do
  name=$(basename "$f")
  cp "$f" "$CLAUDE_DIR/hooks/$name"
  chmod +x "$CLAUDE_DIR/hooks/$name"
  printf "  ${GREEN}+${NC} hooks/%s\n" "$name"
done

# ── Step 6b: Scripts ──────────────────────────────────────────────────────────
# Helper scripts the hooks/commands call (e.g. deprecation_scan.py, second-opinion.py).
echo "Installing scripts..."
for f in "$SCRIPT_DIR/scripts/"*; do
  [ -f "$f" ] || continue   # skip __pycache__/ and other dirs
  name=$(basename "$f")
  cp "$f" "$CLAUDE_DIR/scripts/$name"
  case "$name" in *.sh) chmod +x "$CLAUDE_DIR/scripts/$name" ;; esac
  printf "  ${GREEN}+${NC} scripts/%s\n" "$name"
done

# ── Step 7: CLAUDE.md — merge learned patterns ────────────────────────────────
echo "Installing CLAUDE.md..."
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "  Existing CLAUDE.md found — preserving learned patterns..."
  cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.new"

  # Extract everything after "# Learned Patterns" from the existing file
  EXISTING_PATTERNS=$(awk '/^# Learned Patterns/{found=1; next} found{print}' \
    "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || true)

  if [ -n "$EXISTING_PATTERNS" ]; then
    # Strip the patterns section from the new file, append existing ones
    # (new file's patterns are already seeded from the repo)
    echo "" >> "$CLAUDE_DIR/CLAUDE.md.new"
    echo "$EXISTING_PATTERNS" >> "$CLAUDE_DIR/CLAUDE.md.new"
    echo "  Merged $(echo "$EXISTING_PATTERNS" | grep -c "^### " || echo 0) existing patterns"
  fi
  mv "$CLAUDE_DIR/CLAUDE.md.new" "$CLAUDE_DIR/CLAUDE.md"
else
  cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  printf "  ${GREEN}+${NC} CLAUDE.md\n"
fi

# ── Step 8: settings.json — deep merge ────────────────────────────────────────
echo "Merging settings..."
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BASE_SETTINGS="$SCRIPT_DIR/settings.base.json"

if [ -f "$SETTINGS_FILE" ]; then
  echo "  Existing settings.json — merging hooks + permissions..."
  python3 - "$SETTINGS_FILE" "$BASE_SETTINGS" <<'PYEOF'
import json, sys

existing_path, base_path = sys.argv[1], sys.argv[2]

with open(existing_path) as f:
    existing = json.load(f)
with open(base_path) as f:
    base = json.load(f)

merged = {**existing}

# Merge hooks — add base hook groups not already present (match by command path)
if 'hooks' not in merged:
    merged['hooks'] = {}

for hook_event, base_groups in base.get('hooks', {}).items():
    if hook_event not in merged['hooks']:
        merged['hooks'][hook_event] = base_groups
        continue
    # Collect existing command paths for this event
    existing_cmds = set()
    for group in merged['hooks'][hook_event]:
        for h in group.get('hooks', []):
            existing_cmds.add(h.get('command', ''))
    # Add base groups whose commands aren't already present
    for group in base_groups:
        group_cmds = {h.get('command', '') for h in group.get('hooks', [])}
        if not group_cmds.issubset(existing_cmds):
            merged['hooks'][hook_event].append(group)

# Merge permissions — union of allow, union of deny
if 'permissions' not in merged:
    merged['permissions'] = base.get('permissions', {})
else:
    base_allow = set(base.get('permissions', {}).get('allow', []))
    exist_allow = set(merged.get('permissions', {}).get('allow', []))
    merged['permissions']['allow'] = sorted(exist_allow | base_allow)

    base_deny = set(base.get('permissions', {}).get('deny', []))
    exist_deny = set(merged.get('permissions', {}).get('deny', []))
    merged['permissions']['deny'] = sorted(exist_deny | base_deny)

with open(existing_path, 'w') as f:
    json.dump(merged, f, indent=2)
    f.write('\n')
print("  Merged.")
PYEOF
else
  cp "$BASE_SETTINGS" "$SETTINGS_FILE"
  printf "  ${GREEN}+${NC} settings.json\n"
fi

# ── Step 9: Register activity-log MCP (optional) ─────────────────────────────
ACTIVITY_MCP_URL="${ACTIVITY_MCP_URL:-}"
if [ -z "$ACTIVITY_MCP_URL" ]; then
  echo "  no ACTIVITY_MCP_URL set — skipping optional activity-log MCP"
else
  echo "Checking activity-log MCP..."
  if curl -s --max-time 2 "$ACTIVITY_MCP_URL" > /dev/null 2>&1; then
    # Check if already registered
    if claude mcp list 2>/dev/null | grep -q "activity-log"; then
      echo "  activity-log MCP already registered — skipping"
    else
      claude mcp add activity-log "$ACTIVITY_MCP_URL" 2>/dev/null \
        && printf "  ${GREEN}+${NC} activity-log MCP registered: %s\n" "$ACTIVITY_MCP_URL" \
        || printf "  ${YELLOW}Could not register activity-log MCP (is 'claude' CLI in PATH?)${NC}\n"
    fi
  else
    printf "  ${YELLOW}activity-log MCP not reachable — skipping${NC}\n"
    echo "  To register later: claude mcp add activity-log http://YOUR_MCP_HOST:PORT/mcp"
  fi
fi

echo "Pulling learned patterns from repo..."
if [ -f "$SCRIPT_DIR/sync-lessons.sh" ]; then
  bash "$SCRIPT_DIR/sync-lessons.sh" --pull 2>/dev/null \
    || printf "  ${YELLOW}No new lessons to pull yet${NC}\n"
fi

# ── Step 10: Wire secrets.env into the shell (if present) ─────────────────────
SECRETS_FILE="$SCRIPT_DIR/secrets.env"
echo "Checking secrets.env..."
if [ -f "$SECRETS_FILE" ]; then
  SOURCE_LINE="[ -f \"$SECRETS_FILE\" ] && source \"$SECRETS_FILE\"  # flight-plan secrets"
  for prof in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [ -f "$prof" ] || continue
    if grep -qF "flight-plan secrets" "$prof"; then
      echo "  already sourced in $(basename "$prof")"
    else
      printf '\n%s\n' "$SOURCE_LINE" >> "$prof"
      printf "  ${GREEN}+${NC} sourcing secrets.env from %s (open a new shell to load)\n" "$(basename "$prof")"
    fi
  done
else
  printf "  ${YELLOW}No secrets.env yet${NC} — cp secrets.env.example secrets.env, add your keys, re-run install.\n"
fi

# ── Step 11: Record installed version ─────────────────────────────────────────
printf '%s\n' "$VERSION" > "$CLAUDE_DIR/.flight-plan-version"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
printf "${GREEN}${BOLD}Flight Plan v%s installed!${NC}\n" "$VERSION"
echo ""
echo "Installed to: $HOME/.claude/"
echo "Backup at:    $BACKUP_DIR"
echo "Version:      $VERSION  (recorded at ~/.claude/.flight-plan-version)"
echo ""
echo "First-time setup:"
echo "  cd /your/project"
echo "  claude"
echo "  /memory-init       ← run once per project"
echo ""
echo "Every session:"
echo "  /session-start     ← loads context, enters plan mode"
echo "  /boris <task>      ← say what to build, answer questions, say 'go'"
echo "  /session-end       ← saves everything, updates Linear"
echo ""
echo "To update:"
echo "  cd $SCRIPT_DIR && git pull && ./install.sh"
echo ""
