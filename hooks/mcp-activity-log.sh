#!/usr/bin/env bash
# hooks/mcp-activity-log.sh
# PostToolUse hook — fires after memorygraph write calls.
# Logs the activity to an external activity-log MCP so it sees work from other machines.
#
# Set ACTIVITY_MCP_URL to your activity-log MCP endpoint (typically reachable over a
# private network/VPN). No-ops silently when unset or unreachable.

ACTIVITY_MCP_URL="${ACTIVITY_MCP_URL:-}"
[ -z "$ACTIVITY_MCP_URL" ] && exit 0

MACHINE=$(hostname -s 2>/dev/null || echo "remote")

export HOOK_DATA_ENV
HOOK_DATA_ENV=$(cat)
export MACHINE

# Build JSON-RPC payload, or exit 0 if this tool should be skipped
PAYLOAD=$(python3 - <<'PYEOF'
import json, sys, os

try:
    d = json.loads(os.environ.get("HOOK_DATA_ENV", ""))
except Exception:
    sys.exit(0)

tool = d.get("tool_name", "")
inp = d.get("tool_input", {})
machine = os.environ.get("MACHINE", "remote")

if tool not in (
    "mcp__memorygraph__store_memory",
    "mcp__memorygraph__update_memory",
    "mcp__memorygraph__create_relationship",
):
    sys.exit(0)

if "store_memory" in tool:
    name = inp.get("name", "")
    content = (inp.get("content", "") or "")[:80]
    activity = f"Memory stored: {name} — {content}" if name else f"Memory stored: {content}"
elif "update_memory" in tool:
    mid = (inp.get("memory_id", "") or "")[:8]
    content = (inp.get("content", "") or "")[:80]
    activity = f"Memory updated ({mid}): {content}" if content else f"Memory updated: {mid}"
elif "create_relationship" in tool:
    src = (inp.get("source_id", "") or "")[:8]
    rel = inp.get("relationship_type", "")
    tgt = (inp.get("target_id", "") or "")[:8]
    activity = f"Relationship: {src} --[{rel}]--> {tgt}"
else:
    activity = "MemoryGraph write operation"

payload = {
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
        "name": "log_activity",
        "arguments": {
            "project": os.environ.get("FLIGHT_PLAN_PROJECT", "flight-plan"),
            "activity": f"[{machine}] {activity}",
            "activity_type": "general",
            "details": f"Auto-logged from flight-plan hook on {machine}",
        },
    },
    "id": 1,
}
print(json.dumps(payload))
PYEOF
)

[ -z "$PAYLOAD" ] && exit 0

curl -s -X POST "$ACTIVITY_MCP_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  --max-time 3 \
  -d "$PAYLOAD" \
  > /dev/null 2>&1 || true

exit 0
