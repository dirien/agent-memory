#!/usr/bin/env bash
# write-env.sh — write agent-memory's .env from the Pulumi stack outputs.
#
# Usage: scripts/write-env.sh            # uses the stack selected in infra/
#        AGENT_MEMORY_STACK=org/agent-memory-infra/dev scripts/write-env.sh
#
# Keys the stack owns are replaced; anything else already in .env
# (BRIDGE_WATCH_DIRS, BRIDGE_MEMORY_PATH, ...) is kept.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
STACK_ARGS=()
[[ -n "${AGENT_MEMORY_STACK:-}" ]] && STACK_ARGS=(--stack "$AGENT_MEMORY_STACK")

dotenv="$(pulumi stack output dotenv --show-secrets --cwd "$ROOT/infra" ${STACK_ARGS[@]+"${STACK_ARGS[@]}"})"
if [[ -z "$dotenv" ]]; then
  echo "Stack has no 'dotenv' output yet. Run 'pulumi up' in infra/ first." >&2
  exit 1
fi

managed='^(BRIDGE_ES_URL|BRIDGE_ES_API_KEY|BRIDGE_AGENT_ID|KIBANA_URL|BRIDGE_ENTITY_INDEX|BRIDGE_ENTITY_HISTORY_INDEX)='
umask 077
{
  echo "# Managed by scripts/write-env.sh from the Pulumi stack. Re-run after 'pulumi up'."
  echo "$dotenv"
  if [[ -f "$ENV_FILE" ]]; then
    grep -v -E "$managed" "$ENV_FILE" | grep -v '^# Managed by scripts/write-env.sh' || true
  fi
} > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"

echo "Wrote $ENV_FILE ($(grep -c '=' "$ENV_FILE") settings). Check it with: ./bridge status"
