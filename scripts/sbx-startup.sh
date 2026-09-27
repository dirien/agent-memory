#!/usr/bin/env bash
# sbx-startup.sh — run by the elastic-memory kit on every sandbox start.
# Idempotent and non-fatal: each step skips when its inputs are missing.
#
#   1. put `bridge` on PATH (~/.local/bin/bridge -> <workspace>/bridge)
#   2. install the agent-memory APM package at user scope (hooks, skill and the
#      elastic-memory MCP server into this sandbox's ~/.claude only; the shared
#      workspace stays free of them, so other sandboxes on it don't get them)
#   3. write .env from the Pulumi stack when .env is missing and the stack is up
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
log() { echo "[elastic-memory] $*"; }

mkdir -p "$HOME/.local/bin"
if [[ -x "$ROOT/bridge" ]]; then
  ln -sfn "$ROOT/bridge" "$HOME/.local/bin/bridge"
  log "bridge -> $ROOT/bridge"
fi

if command -v apm >/dev/null 2>&1 && [[ -f "$ROOT/apm.yml" ]]; then
  # User scope, Claude only. Unset the MCP values so APM keeps the ${...}
  # placeholders for Claude Code to expand at runtime. Runs from $HOME so no
  # project-level files land in the shared workspace.
  (cd "$HOME" && env -u ELASTIC_MCP_API_KEY -u ELASTIC_KIBANA_HOST \
    apm install -g --target claude "$ROOT" </dev/null >/dev/null 2>&1) \
    && log "agent-memory hooks, skill + MCP server installed in ~/.claude" \
    || log "apm install -g failed; this sandbox has no agent-memory hooks"
fi

if [[ ! -f "$ROOT/.env" ]] && command -v pulumi >/dev/null 2>&1; then
  if "$ROOT/scripts/write-env.sh" >/dev/null 2>&1; then
    log ".env written from the Pulumi stack"
  else
    log "no .env yet: run 'pulumi up' in infra/, then scripts/write-env.sh"
  fi
fi
exit 0
