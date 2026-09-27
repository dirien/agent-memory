# elastic-memory kit (Docker Sandboxes)

A `schemaVersion: "2"`, `kind: mixin` kit that wires agent-memory into a Claude
Code sandbox. Stack it after
[`dirien/infrastructure-sandbox-kit`](https://github.com/dirien/infrastructure-sandbox-kit),
which brings Pulumi, APM and the guardrail hooks:

```bash
# one-time, on the host
sbx secret set -g pulumi           # Pulumi Cloud token
sbx secret set -g elastic-cloud    # Elastic Cloud API key (see ../infra/README.md)

# from the root of your agent-memory clone
sbx run \
  --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 \
  --kit ./kit \
  --kit-arg elastic-memory.stack=<org>/agent-memory-infra/dev \
  claude .
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
| `environment.variables` | `AGENT_MEMORY_STACK` (from the `stack` arg), `BRIDGE_TIMEOUT=10` |
| `setup.install` | installs `jq`, `curl`, `openssl` when the image lacks them |
| `setup.files` | records the workspace path (`${WORKDIR}`) for the startup step |
| `setup.startup` | runs `scripts/sbx-startup.sh`: links `bridge` into `~/.local/bin`, runs `apm install` (hooks + skill), writes `.env` from the stack when it's missing |
| `agentInstructions` | tells Claude to recall before re-deriving and to remember decisions |

## Arguments

| Arg | Default | Purpose |
|---|---|---|
| `elastic_region` | `us-east-1.aws` | Region part of the project endpoints. Pulumi's `aws-us-east-1` becomes `us-east-1.aws`. |
| `stack` | empty | Fully qualified stack for `scripts/write-env.sh`. Empty means the stack selected in `infra/`. |

Pass them with `--kit-arg elastic-memory.<arg>=<value>`.

## The credential, two ways

`pulumi up` needs `EC_API_KEY`. Pick one:

- **Sandbox proxy**: `sbx secret set -g elastic-cloud`. The key never enters the
  container.
- **Pulumi ESC**: store it in the `agent-memory/elastic-cloud` environment the
  stack imports. This also works outside a sandbox. If both are set, the ESC
  value wins inside the Pulumi process, and the proxy still rewrites the header.

The project's own API key (the one `bridge` uses) is created by Pulumi and lands
in the workspace's `.env` through `scripts/write-env.sh`. It is scoped to the
agent-memory indices only.

## Validate

`sbx` is a host tool, so validate on the host:

```bash
sbx kit validate ./kit
sbx kit inspect ./kit --json
```
