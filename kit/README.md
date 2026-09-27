# elastic-memory kit (Docker Sandboxes)

A `schemaVersion: "2"`, `kind: mixin` kit that wires agent-memory into a Claude
Code sandbox. Stack it after
[`dirien/infrastructure-sandbox-kit`](https://github.com/dirien/infrastructure-sandbox-kit),
which brings Pulumi, APM and the guardrail hooks:

```bash
# one-time, on the host
sbx secret set pulumi              # Pulumi Cloud token (ESC reads go through it)
pulumi env init <org>/agent-memory/elastic-cloud -f infra/esc/elastic-cloud.yaml
# then set elastic.apiKey and state.passphrase in it (see ../infra/README.md)

# from the root of your agent-memory clone
sbx run \
  --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 \
  --kit ./kit \
  claude .
```

Inside the sandbox:

```bash
scripts/pulumi.sh up       # local state backend, EC_API_KEY from ESC
scripts/write-env.sh       # .env for the bridge CLI
bridge status
```

Kits apply in `--kit` order, so the infrastructure kit's Pulumi and APM are on
PATH before this kit's startup step runs. Remote kit sources need a one-time
`sbx settings set kit.allowedSources '["docker.io/","ghcr.io/dirien/","github.com/dirien/"]'`;
local `./kit` paths are allowed by default.

## What it declares

| Block | What it does |
|---|---|
| `permissions.network.allow` | `api.elastic-cloud.com`, your project's `*.es.<region>.elastic.cloud` and `*.kb.<region>.elastic.cloud`, the Pulumi service, the OpenTofu registry and GitHub (the `ec` and `elasticstack` providers), Ubuntu mirrors, npm |
| `credentials` | service `elastic-cloud`: `EC_API_KEY` is proxy-managed, and the proxy injects `Authorization: ApiKey <key>` on `api.elastic-cloud.com` |
| `environment.variables` | `AGENT_MEMORY_BACKEND` and `AGENT_MEMORY_STACK` (from the args), `BRIDGE_TIMEOUT=10` |
| `setup.install` | installs `jq`, `curl`, `openssl` when the image lacks them |
| `setup.files` | records the workspace path (`${WORKDIR}`) for the startup step |
| `setup.startup` | runs `scripts/sbx-startup.sh`: links `bridge` into `~/.local/bin`, runs `apm install` (hooks + skill), writes `.env` from the stack when it's missing |
| `agentInstructions` | tells Claude to recall before re-deriving and to remember decisions |

## Arguments

| Arg | Default | Purpose |
|---|---|---|
| `elastic_region` | `us-east-1.aws` | Region part of the project endpoints. Pulumi's `aws-us-east-1` becomes `us-east-1.aws`. |
| `backend` | `local` | State backend for `scripts/pulumi.sh`: `local` (`infra/.pulumi-state`) or `cloud` (Pulumi Cloud). See the known issue below. |

Pass them with `--kit-arg elastic-memory.<arg>=<value>`.

## The credential, two ways

`pulumi up` needs `EC_API_KEY`. Pick one:

- **Pulumi ESC**: store it in the `agent-memory/elastic-cloud` environment
  ([template](../infra/esc/elastic-cloud.yaml)). This also works outside a
  sandbox, and the local backend needs the environment for its passphrase anyway.
- **Sandbox proxy**: `sbx secret set elastic-cloud`. The proxy sets
  `Authorization: ApiKey <key>` on every `api.elastic-cloud.com` request, so it
  wins even if ESC still holds the placeholder. The key never enters the container.

The project's own API key (the one `bridge` uses) is created by Pulumi and lands
in the workspace's `.env` through `scripts/write-env.sh`. It is scoped to the
agent-memory indices only.

## MCP key through the proxy

The `elastic-memory` MCP server in `.mcp.json` sends
`Authorization: ApiKey ${ELASTIC_MCP_API_KEY}` to your project's Kibana. Keep
the key on the host with a custom secret: the sandbox gets a placeholder in
`ELASTIC_MCP_API_KEY`, and the proxy replaces the placeholder in the request
headers for the matching hosts
([`sbx secret set-custom`](https://docs.docker.com/reference/cli/sbx/secret/set-custom/),
experimental; wildcard hosts are allowed there, while kit `credentials` inject
only on the hosts they name). The Kibana host itself isn't secret; pass it at
creation. On the host, from the repo root:

```bash
E=<org>/agent-memory/elastic-cloud
# once, after `pulumi up`: copy the key and host from the stack into ESC
scripts/pulumi.sh stack output mcp_api_key --show-secrets | tr -d '\n' | \
  pulumi env set $E mcp.apiKey --secret -f -
pulumi env set $E mcp.kibanaHost "$(scripts/pulumi.sh stack output kibana_url | sed 's#^https://##')" --plaintext

# sbx resolves the key on the host when needed (absolute path required for --command)
PULUMI_BIN="$(command -v pulumi)"
sbx secret set-custom --host '*.kb.us-east-1.aws.elastic.cloud' --env ELASTIC_MCP_API_KEY \
  --command "$PULUMI_BIN env get $E mcp.apiKey --value string --show-secrets | tr -d '\n'"
sbx create --name <sandbox> \
  --env ELASTIC_KIBANA_HOST="$(pulumi env get $E mcp.kibanaHost --value string)" \
  --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 --kit ./kit claude .
```

Inside the sandbox `echo "$ELASTIC_MCP_API_KEY"` prints the placeholder, and
`/mcp` shows `elastic-memory` connected.

Verified on 2026-09-27: a request carrying only the placeholder reached the MCP
endpoint with the real key (sandboxd replayed the `pulumi env get` command), and
a request with any other `ApiKey` value got `401`. Unlike kit `credentials`
injection, the custom secret replaces its placeholder and leaves other
`Authorization` values alone, which is also what Pulumi's `update-token` calls
need (see the known issue below; not yet tested for Pulumi). If you'd rather skip the proxy, pass
both values with `sbx create --env-file .mcp.env ...`; the key then lives in the
container's environment.

## Known issue: `pulumi up` and the proxy-managed Pulumi token

The credential proxy sets `Authorization: token <PAT>` on every request to
`api.pulumi.com`, whatever the CLI sent. Read-only commands (`whoami`,
`preview`'s plan, `pulumi env`) are fine, but an update authenticates its
event, checkpoint and `complete` calls with a per-update `update-token`, and
those come back `401`. `pulumi up` then fails with *"this command requires
logging in"* after it has already changed cloud resources.

That's why the kit defaults to `backend=local`: `scripts/pulumi.sh` keeps the
state in `infra/.pulumi-state` (stack `local`) and wraps the run in
`pulumi env run`, which only *reads* ESC, and reads work through the proxy.
ESC supplies `EC_API_KEY` and `PULUMI_CONFIG_PASSPHRASE`
(see [`../infra/esc/elastic-cloud.yaml`](../infra/esc/elastic-cloud.yaml)).

```bash
scripts/pulumi.sh preview
scripts/pulumi.sh up
scripts/write-env.sh
```

To keep state in Pulumi Cloud instead (`--kit-arg elastic-memory.backend=cloud`),
the sandbox needs a real token and no proxy binding for `pulumi`. A global
secret can't be disabled for one sandbox, so move the others to scoped secrets
before removing the global one (on the host):

```bash
printf '%s\n' "$PULUMI_ACCESS_TOKEN" | sbx secret set pulumi --sandbox <each-other-sandbox>
sbx secret rm pulumi
sbx exec -d <this-sandbox> bash -c \
  "printf 'export PULUMI_ACCESS_TOKEN=%s\n' \"$PULUMI_ACCESS_TOKEN\" >> /etc/sandbox-persistent.sh"
```

Then a bogus token must be rejected from inside the sandbox:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H 'Authorization: token bogus' https://api.pulumi.com/api/user   # 401
```

## Validate

`sbx` is a host tool, so validate on the host:

```bash
sbx kit validate ./kit
sbx kit inspect ./kit --json
```
