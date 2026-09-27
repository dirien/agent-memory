#!/usr/bin/env bash
# Claude Code SessionStart hook — sync auto-memory files into Elasticsearch,
# send a heartbeat, and remind the agent that recall is one command away.
# Stdout becomes session context. Always exits 0.

set -uo pipefail

# shellcheck source=hooks/resolve-bridge.sh
source "$(dirname "$0")/resolve-bridge.sh" || exit 0

# `bridge` exits non-zero when .env/BRIDGE_* are missing: stay silent then.
synced="$("$BRIDGE_BIN" sync-memories --quiet 2>/dev/null)" || exit 0
"$BRIDGE_BIN" heartbeat >/dev/null 2>&1 || true

[[ -n "$synced" ]] && echo "$synced"
cat <<'EOF'
agent-memory is active: your memories live in Elasticsearch and survive this session.
Before re-deriving a past decision, run `bridge recall "<what you need>"` (it prints each memory's content).
Store new decisions with `bridge remember <type> "<text>" --title "<title>"`.
Over the elastic-memory MCP server, memories are in the agent-memory index and tasks in agent-tasks.
EOF

# Unfinished work from earlier sessions, so "what's still open?" needs no lookup.
open_tasks="$("$BRIDGE_BIN" task open --limit 5 2>/dev/null)" || open_tasks=""
if [[ -n "$open_tasks" && "$open_tasks" != "No open tasks." ]]; then
  echo "Open tasks from earlier sessions (bridge task update/done <task_id> to move them on):"
  echo "$open_tasks" | sed 's/^/  /'
fi
# In Docker Sandboxes the keys are proxy placeholders by design; say so, so the
# agent doesn't mistake them for leaked credentials.
if [[ "${BRIDGE_ES_API_KEY:-}" == sbx-cs-* || "${ELASTIC_MCP_API_KEY:-}" == sbx-cs-* ]]; then
  echo "BRIDGE_ES_API_KEY / ELASTIC_MCP_API_KEY hold Docker Sandboxes proxy placeholders (sbx-cs-...), not keys: the proxy swaps in the real values on the way out. Printing them is harmless; nothing to rotate."
fi
exit 0
