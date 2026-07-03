#!/usr/bin/env bash
# hooks/session-hint.sh
# UserPromptSubmit hook — injects a one-time daily reminder into Claude's
# context so it knows to auto-run /session-start and auto-trigger workflows.
#
# Fires on every user prompt submission, but only injects the reminder
# once per calendar day to avoid noise. Uses a date-stamped state file.

HINT_FILE="${HOME}/.claude/.session-hint-shown"
TODAY=$(date +%Y-%m-%d)

# Already shown today — stay silent
if [ -f "$HINT_FILE" ] && [ "$(cat "$HINT_FILE" 2>/dev/null)" = "$TODAY" ]; then
  exit 0
fi

# Write today's date so we don't fire again until tomorrow
echo "$TODAY" > "$HINT_FILE"

# This output is injected as a <system-reminder> into Claude's context
cat <<'EOF'
WORKFLOW AUTO-TRIGGER REMINDER (shown once per day):

1. If /session-start has NOT been run this session: run it now before responding,
   then present the context summary + enter plan mode.

2. Auto-trigger rules — invoke these WITHOUT being asked:
   - User describes building/adding/implementing something → run /boris workflow
   - User reports a bug/error/failure → run /systematic-debugging
   - User says done/finished/wrap up/goodbye → run /session-end
   - User asks for tests → run /tdd

3. Never wait for the user to say the command name. Detect intent → act.
EOF
