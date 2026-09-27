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
Before re-deriving a past decision, run `bridge recall "<what you need>"`.
Store new decisions with `bridge remember <type> "<text>" --title "<title>"`.
EOF
exit 0
