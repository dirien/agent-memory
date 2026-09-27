#!/usr/bin/env bash
# Claude Code SessionEnd hook — sync auto-memory one last time (a sandbox may
# be gone before the next SessionStart), log the session end and suspend
# in-flight tasks so the next session can pick them up. Always exits 0.
# Claude Code gives SessionEnd hooks 1.5s by default, raised to the hook's
# timeout (15s in .apm/hooks/agent-memory.json).

set -uo pipefail

# shellcheck source=hooks/resolve-bridge.sh
source "$(dirname "$0")/resolve-bridge.sh" || exit 0

payload="$(cat)"
reason="$(echo "$payload" | jq -r '.reason // "other"' 2>/dev/null || echo other)"

"$BRIDGE_BIN" sync-memories --quiet >/dev/null 2>&1 || true
"$BRIDGE_BIN" log session-end "Claude Code session ended ($reason)" \
  --tags "claude-code,$reason" --quiet >/dev/null 2>&1 || true
"$BRIDGE_BIN" suspend-tasks >/dev/null 2>&1 || true
exit 0
