#!/usr/bin/env bash
# demo-sandbox.sh — create one demo sandbox (DEMO.md): Claude Code with the
# infrastructure and agent-memory kits, working in a clone of this repo,
# against the memory backend in the ESC environment $E. Keys are not passed:
# the sandbox gets the set-custom placeholders (DEMO.md, step 0).
#
#   scripts/demo-sandbox.sh fri ~/demo/agent-memory && sbx run --name fri
#
# Plain bash on purpose: zsh trips over the array expansions this replaces.
set -euo pipefail
name="${1:?usage: scripts/demo-sandbox.sh <sandbox-name> <workspace>}"
ws="${2:?usage: scripts/demo-sandbox.sh <sandbox-name> <workspace>}"
E="${E:-dirien/agent-memory/runtime}"
KIT="${KIT:-ghcr.io/dirien/agent-memory-kit:latest}"
val() { pulumi env get "$E" "elastic.$1" --value string; }

[[ -d "$ws/.git" ]] || { echo "not a git clone: $ws" >&2; exit 1; }

sbx create --name "$name" --skills=off \
  --env BRIDGE_ES_URL="$(val esUrl)" \
  --env BRIDGE_AGENT_ID="$(val agentId)" \
  --env ELASTIC_KIBANA_HOST="$(val kibanaHost)" \
  --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 \
  --kit "$KIT" \
  claude "$ws"

echo "created $name ($KIT) on $ws; now: sbx run --name $name"
