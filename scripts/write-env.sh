#!/usr/bin/env bash
# write-env.sh — wire the Pulumi stack outputs into the local tooling:
#
#   .env                         bridge CLI settings (the `dotenv` output)
#   .claude/settings.local.json  ELASTIC_KIBANA_HOST + ELASTIC_MCP_API_KEY for the
#                                elastic-memory MCP server declared in .mcp.json
#
# Usage: scripts/write-env.sh            # uses the stack selected in infra/
#        AGENT_MEMORY_STACK=org/agent-memory-infra/dev scripts/write-env.sh
#        AGENT_MEMORY_BACKEND=local scripts/write-env.sh   # local state backend
#
# Keys the stack owns are replaced; anything else already in either file
# (BRIDGE_WATCH_DIRS, other settings, ...) is kept. Both files are gitignored.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
SETTINGS_FILE="$ROOT/.claude/settings.local.json"
STACK_ARGS=()
if [[ -n "${AGENT_MEMORY_STACK:-}" && "${AGENT_MEMORY_BACKEND:-cloud}" == "cloud" ]]; then
  STACK_ARGS=(--stack "$AGENT_MEMORY_STACK")
fi

outputs="$("$ROOT/scripts/pulumi.sh" stack output --json --show-secrets ${STACK_ARGS[@]+"${STACK_ARGS[@]}"})"
dotenv="$(jq -r '.dotenv // empty' <<< "$outputs")"
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

# MCP: Claude Code expands ${ELASTIC_KIBANA_HOST} / ${ELASTIC_MCP_API_KEY} in
# .mcp.json from the session environment, which settings.local.json provides.
mcp_key="$(jq -r '.mcp_api_key // empty' <<< "$outputs")"
kibana_host="$(jq -r '.kibana_url // empty' <<< "$outputs" | sed -E 's#^https?://##; s#/.*$##')"
if [[ -n "$mcp_key" && -n "$kibana_host" ]]; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  current="{}"
  [[ -s "$SETTINGS_FILE" ]] && current="$(cat "$SETTINGS_FILE")"
  jq --arg host "$kibana_host" --arg key "$mcp_key" \
    '.env = ((.env // {}) + {ELASTIC_KIBANA_HOST: $host, ELASTIC_MCP_API_KEY: $key})' \
    <<< "$current" > "$SETTINGS_FILE.tmp"
  mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  echo "Wrote MCP settings to $SETTINGS_FILE (restart Claude Code to pick them up)"
fi
