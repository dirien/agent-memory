#!/usr/bin/env bash
# pulumi.sh — run pulumi against infra/ with the right state backend.
#
#   AGENT_MEMORY_BACKEND=cloud (default)
#     Plain `pulumi` on the selected Pulumi Cloud stack. The stack imports the
#     agent-memory/elastic-cloud ESC environment itself.
#
#   AGENT_MEMORY_BACKEND=local
#     State in infra/.pulumi-state, stack "local". EC_API_KEY and
#     PULUMI_CONFIG_PASSPHRASE come from the ESC environment via `pulumi env run`.
#     Use this inside Docker Sandboxes: the credential proxy breaks Pulumi Cloud
#     updates (see kit/README.md), while ESC reads still work.
#
# Usage: scripts/pulumi.sh preview | up | destroy | stack output ...
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INFRA="$ROOT/infra"

case "${AGENT_MEMORY_BACKEND:-cloud}" in
  cloud)
    exec pulumi --cwd "$INFRA" "$@"
    ;;
  local)
    esc_env="${AGENT_MEMORY_ESC_ENV:-$(pulumi whoami)/agent-memory/elastic-cloud}"
    mkdir -p "$INFRA/.pulumi-state"
    # The outer `pulumi env run` talks to Pulumi Cloud; only the inner pulumi
    # sees the file:// backend.
    exec pulumi env run "$esc_env" -- bash -c '
      set -euo pipefail
      infra="$1"; shift
      export PULUMI_BACKEND_URL="file://$infra/.pulumi-state"
      pulumi --cwd "$infra" stack select --create local >/dev/null
      exec pulumi --cwd "$infra" "$@"
    ' _ "$INFRA" "$@"
    ;;
  *)
    echo "AGENT_MEMORY_BACKEND must be 'cloud' or 'local'" >&2
    exit 2
    ;;
esac
