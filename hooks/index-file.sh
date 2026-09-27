#!/usr/bin/env bash
# Claude Code PostToolUse hook — index written/edited markdown files
#
# Reads JSON from stdin (Claude Code hook payload), extracts file_path,
# filters to *.md only, then calls `bridge entity index-file`. Always exits 0.

set -uo pipefail

# shellcheck source=hooks/resolve-bridge.sh
source "$(dirname "$0")/resolve-bridge.sh" || exit 0

# Read hook payload from stdin
payload="$(cat)"

# Extract file path from tool input
file_path="$(echo "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // empty' 2>/dev/null || true)"

# Only index markdown files
[[ -z "$file_path" ]] && exit 0
[[ "$file_path" != *.md ]] && exit 0
[[ -f "$file_path" ]] || exit 0

"$BRIDGE_BIN" entity index-file "$file_path" --quiet >/dev/null 2>&1 || true
exit 0
