# elastic-memory kit (Docker Sandboxes)

A `schemaVersion: "2"`, `kind: mixin` kit that gives Claude Code in a sandbox a
persistent memory in Elasticsearch, **in any project**. It fetches the
agent-memory CLI at a pinned ref, installs its hooks, skill and Elastic MCP
server at user scope with APM, and allows egress to Elastic Cloud and your
project's endpoints. Settings come in as environment variables, the keys as
proxy placeholders: there are no `.env` files and no keys in the sandbox.

Stack it after
[`dirien/infrastructure-sandbox-kit`](https://github.com/dirien/infrastructure-sandbox-kit),
which brings APM (and Pulumi). Published as `ghcr.io/dirien/agent-memory-kit`.

## Run it

Prerequisites: the backend is deployed (`infra/`), which also creates the
`<org>/agent-memory/runtime` ESC environment, and `pulumi` on the host is logged
in to that org.

```bash
E=<org>/agent-memory/runtime
PULUMI_BIN="$(command -v pulumi)"      # sbx wants an absolute path for --command

# 1. Keys: the sandbox sees placeholders; sandboxd resolves the real values on the
#    host from ESC when a request to the matching host needs them.
sbx secret set-custom --host '*.es.us-east-1.aws.elastic.cloud' --env BRIDGE_ES_API_KEY \
  --command "$PULUMI_BIN env get $E elastic.bridgeApiKey --value string --show-secrets | tr -d '\n'"
sbx secret set-custom --host '*.kb.us-east-1.aws.elastic.cloud' --env ELASTIC_MCP_API_KEY \
  --command "$PULUMI_BIN env get $E elastic.mcpApiKey --value string --show-secrets | tr -d '\n'"

# 2. Settings (not secret) and the kits. Any project folder works.
v() { pulumi env get "$E" "elastic.$1" --value string; }
sbx create --name my-agent --skills=off \
  --env BRIDGE_ES_URL="$(v esUrl)" \
  --env BRIDGE_AGENT_ID="$(v agentId)" \
  --env ELASTIC_KIBANA_HOST="$(v kibanaHost)" \
  --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 \
  --kit ghcr.io/dirien/agent-memory-kit:v0.2.0 \
  claude /path/to/any/project
sbx run --name my-agent
```

`set-custom` won't overwrite an existing secret for the same variable ("custom
secret env ... already exists"). To repoint one, remove it by its placeholder
and create it again with the same placeholder, so running sandboxes keep
working: `sbx secret rm --placeholder <sbx-cs-…> -f`, then the `set-custom`
command above plus `--placeholder <sbx-cs-…>`.

Keep `sbx create` and `sbx run` separate: the kit's startup step installs the
hooks while the sandbox starts, before Claude does. Remote kit sources need a
one-time `sbx settings set kit.allowedSources '["docker.io/","ghcr.io/dirien/","github.com/dirien/"]'`.

Inside the sandbox:

```text
! bridge status                   # online, 7 indices
! echo "$BRIDGE_ES_API_KEY"        # sbx-cs-… placeholder, not the key
/mcp                              # elastic-memory connected
```

## What it declares

| Block | What it does |
|---|---|
| `permissions.network.allow` | `api.elastic-cloud.com`, your project's `*.es.<region>.elastic.cloud` and `*.kb.<region>.elastic.cloud`, `codeload.github.com` (the agent-memory tarball), the Pulumi service, the OpenTofu registry and GitHub (providers), Ubuntu mirrors, npm |
| `credentials` | service `elastic-cloud`: `EC_API_KEY` for `pulumi up` in an agent-memory workspace; the proxy injects `Authorization: ApiKey <key>` on `api.elastic-cloud.com` |
| `environment.variables` | `AGENT_MEMORY_BACKEND` (from the `backend` arg), `BRIDGE_TIMEOUT=10` |
| `setup.install` | installs `jq`, `curl`, `openssl` if missing; downloads agent-memory at `KIT_REF` into `~/.local/share/agent-memory` |
| `setup.files` | records the workspace path and the `agent_memory_dir` choice |
| `setup.startup` | runs `scripts/sbx-startup.sh` from that copy on every start: links `bridge` into `~/.local/bin` and runs `apm install -g --target claude`, so the hooks, the `agent-memory` skill and the `elastic-memory` MCP server land in this sandbox's `~/.claude` only |
| `agentInstructions` | tells Claude to recall before re-deriving, and that the keys are placeholders |

`KIT_REF` in the source spec names a release tag; `scripts/push-kit.sh` rewrites
it to the exact commit SHA in the published artifact.

## Arguments

| Arg | Default | Purpose |
|---|---|---|
| `elastic_region` | `us-east-1.aws` | Region part of the project endpoints. Pulumi's `aws-us-east-1` becomes `us-east-1.aws`. |
| `agent_memory_dir` | `bundled` | `bundled` installs the copy fetched at `KIT_REF`. `workspace` uses the primary workspace (an agent-memory clone you're developing). An absolute path uses a clone mounted there as an extra workspace. |
| `backend` | `local` | State backend for `scripts/pulumi.sh` when the workspace is an agent-memory clone: `local` (`infra/.pulumi-state`) or `cloud`. See the known issue below. |

Pass them with `--kit-arg elastic-memory.<arg>=<value>`.

## Why placeholders, not kit credentials

Kit `credentials` (like the `elastic-cloud` one above) inject a header on the
hosts they name, overwriting whatever the request carried. `sbx secret
set-custom` works differently: the sandbox gets a placeholder in the variable,
and the proxy replaces only that placeholder in the request headers, for any
host matching the pattern (wildcards allowed).
([reference](https://docs.docker.com/reference/cli/sbx/secret/set-custom/), experimental.)

Verified on 2026-09-27 for both keys: a request carrying only the placeholder
reached Kibana (MCP key) or Elasticsearch (bridge key) with the real key,
because sandboxd replayed the `pulumi env get` command; a request with any other
`ApiKey` value got `401`. After rotating the MCP key in Pulumi, the placeholder
kept working without touching the sbx secret.

## Known issue: `pulumi up` and the proxy-managed Pulumi token

This only matters when you run the Pulumi program inside a sandbox. The
infrastructure kit's `pulumi` credential sets `Authorization: token <PAT>` on
every request to `api.pulumi.com`, whatever the CLI sent. Read-only commands
work, but an update authenticates its event, checkpoint and `complete` calls
with a per-update `update-token`, and those come back `401`. `pulumi up` then
fails with *"this command requires logging in"* after it has already changed
cloud resources.

So `scripts/pulumi.sh` defaults to a local state backend in a sandbox
(`backend=local`): state in `infra/.pulumi-state`, and the run wrapped in
`pulumi env run`, which only *reads* ESC. A `set-custom` placeholder for the
Pulumi token would likely avoid the overwrite; that's not tested yet.

## Validate and publish

`.github/workflows/publish-kit.yaml` installs `sbx`, runs `sbx kit validate`
and `sbx kit push` on every kit change on `main` (`:latest`) and on `v*` tags.
Locally, with `sbx` on the host:

```bash
sbx kit validate ./kit
TAG=v0.2.0 scripts/push-kit.sh
```
