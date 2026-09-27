#!/usr/bin/env bash
# sbx-startup.sh — run by the elastic-memory kit on every sandbox start.
# Idempotent and non-fatal: each step skips when its inputs are missing.
#
#   1. put `bridge` on PATH (~/.local/bin/bridge -> <workspace>/bridge)
#   2. deploy the agent-memory hooks + skill with APM when apm is installed
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
  # Unset the MCP values so APM keeps the ${...} placeholders in .mcp.json
  # instead of writing the key into a committed file.
  (cd "$ROOT" && env -u ELASTIC_MCP_API_KEY -u ELASTIC_KIBANA_HOST apm install >/dev/null 2>&1) \
    && log "APM hooks, skill + MCP server deployed" \
    || log "apm install failed; hooks from the committed .claude/ still apply"
fi

if [[ ! -f "$ROOT/.env" ]] && command -v pulumi >/dev/null 2>&1; then
  if "$ROOT/scripts/write-env.sh" >/dev/null 2>&1; then
    log ".env written from the Pulumi stack"
  else
    log "no .env yet: run 'pulumi up' in infra/, then scripts/write-env.sh"
  fi
fi
exit 0
