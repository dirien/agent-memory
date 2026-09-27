#!/usr/bin/env bash
# Sourced by the hook scripts. Sets BRIDGE_BIN or returns 1 when no bridge CLI
# is reachable, so a project without agent-memory configured never breaks.
#
# Lookup order: $BRIDGE_BIN, the bridge next to this hooks/ dir (repo clone),
# the project root (the project is agent-memory itself), then `bridge` on PATH.
# APM copies only the hooks/ bundle into .claude/hooks/agent-memory/.

_hooks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${BRIDGE_BIN:-}" ]]; then
  if [[ -x "$_hooks_dir/../bridge" ]]; then
    BRIDGE_BIN="$_hooks_dir/../bridge"
  elif [[ -n "${CLAUDE_PROJECT_DIR:-}" && -x "$CLAUDE_PROJECT_DIR/bridge" ]]; then
    BRIDGE_BIN="$CLAUDE_PROJECT_DIR/bridge"
  else
    BRIDGE_BIN="$(PATH="$HOME/.local/bin:$PATH" command -v bridge 2>/dev/null || true)"
  fi
fi

[[ -n "$BRIDGE_BIN" && -x "$BRIDGE_BIN" ]] || return 1
export BRIDGE_BIN
