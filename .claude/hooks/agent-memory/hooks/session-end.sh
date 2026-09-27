#!/usr/bin/env bash
# Claude Code SessionEnd hook — log the session end and suspend in-flight tasks
# so the next session can pick them up. Always exits 0.

set -uo pipefail

# shellcheck source=hooks/resolve-bridge.sh
source "$(dirname "$0")/resolve-bridge.sh" || exit 0

payload="$(cat)"
reason="$(echo "$payload" | jq -r '.reason // "other"' 2>/dev/null || echo other)"

"$BRIDGE_BIN" log session-end "Claude Code session ended ($reason)" \
  --tags "claude-code,$reason" --quiet >/dev/null 2>&1 || true
"$BRIDGE_BIN" suspend-tasks >/dev/null 2>&1 || true
exit 0
