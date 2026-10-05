#!/usr/bin/env bash
# sbx-startup.sh — run by the elastic-memory kit on every sandbox start, from
# the agent-memory copy the kit installs (or a clone you point it at).
# Idempotent and non-fatal.
#
#   1. put `bridge` on PATH (~/.local/bin/bridge -> this copy's bridge)
#   2. install this agent-memory APM package at user scope: hooks, skill and
#      the elastic-memory MCP server go into this sandbox's ~/.claude only, so
#      the shared workspace stays free of them
#
# Settings come from the environment (sbx create --env ...), the keys from
# proxy placeholders (sbx secret set-custom); there is no .env.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
log() { echo "[elastic-memory] $*"; }

mkdir -p "$HOME/.local/bin"
if [[ -x "$ROOT/bridge" ]]; then
  ln -sfn "$ROOT/bridge" "$HOME/.local/bin/bridge"
  log "bridge -> $ROOT/bridge"
fi

if command -v apm >/dev/null 2>&1 && [[ -f "$ROOT/apm.yml" ]]; then
  # One agent-memory install at a time. APM keys user-scope installs by source
  # path, so the kit's bundled copy and a workspace clone would both stay
  # installed and every hook would fire twice. Remove any other agent-memory
  # copy (a local path in the user manifest with this script in it) first.
  manifest="$HOME/.apm/apm.yml"
  if [[ -f "$manifest" ]]; then
    while IFS= read -r dep; do
      [[ "$dep" == "$ROOT" || ! -f "$dep/scripts/sbx-startup.sh" ]] && continue
      (cd "$HOME" && apm uninstall -g "$dep" </dev/null >/dev/null 2>&1) \
        && log "removed the agent-memory install from $dep" \
        || log "could not remove the agent-memory install from $dep"
    done < <(sed -n 's|^[[:space:]]*-[[:space:]]*\(/.*\)$|\1|p' "$manifest")
  fi

  # User scope, Claude only. Unset the MCP values so APM keeps the ${...}
  # placeholders for Claude Code to expand at runtime. Runs from $HOME so no
  # project-level files land in the workspace.
  (cd "$HOME" && env -u ELASTIC_MCP_API_KEY -u ELASTIC_KIBANA_HOST \
    apm install -g --target claude "$ROOT" </dev/null >/dev/null 2>&1) \
    && log "agent-memory hooks, skill + MCP server installed in ~/.claude" \
    || log "apm install -g failed; this sandbox has no agent-memory hooks"
else
  log "apm not found: stack this kit after the infrastructure kit"
fi
exit 0
