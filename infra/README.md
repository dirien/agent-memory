# infra: the memory backend in Pulumi HCL

This Pulumi program (`runtime: hcl`) creates everything agent-memory needs
on Elastic Cloud Serverless:

| Resource | Provider | What for |
|---|---|---|
| `ec_elasticsearch_project` | `elastic/ec` | the Serverless project (Elasticsearch + Kibana) |
| `elasticstack_elasticsearch_index` ×7 | `elastic/elasticstack` | `agent-memory`, `agent-messages`, `agent-sessions`, `agent-tasks`, `agent-status`, `<agent>-entities`, `<agent>-entity-history`; `semantic_text` fields use Jina v5 on the Elastic Inference Service |
| `elasticstack_elasticsearch_security_api_key` | `elastic/elasticstack` | a key scoped to those indices, for the `bridge` CLI |
| `elasticstack_kibana_dashboard` | `elastic/elasticstack` | the Agent Memory overview, built from `setup/dashboards/agent-memory-overview.json` |
| `elasticstack_elasticsearch_security_api_key` (`mcp`) | `elastic/elasticstack` | a read-only key for Kibana's Agent Builder MCP server (`feature_agentBuilder.read` + `read` on the memory indices) |

Both providers are Terraform providers. Pulumi HCL pulls them from the OpenTofu
registry and bridges them on the fly; `pulumi install` records that in
`sdks/*/hcl.sdk.json` (checked in).

## What you need

1. **Pulumi CLI 3.256+** and a Pulumi Cloud login (`pulumi login`).
2. **An Elastic Cloud account.** A trial works: <https://cloud.elastic.co/registration>.
3. **An Elastic Cloud API key** that can create Serverless projects. Create it
   under *Organization → API keys* (<https://cloud.elastic.co/account/keys>) with
   a role that may create and delete Elasticsearch projects; on a personal trial,
   the organization-owner role is the simple choice. This is the Elastic Cloud
   key, not a key from inside a project.
4. A place for that key. `ec` reads `EC_API_KEY`:

   ```bash
   # Pulumi ESC (works everywhere; the stack imports this environment).
   # esc/elastic-cloud.yaml exports EC_API_KEY from a placeholder you replace:
   pulumi env init <org>/agent-memory/elastic-cloud -f esc/elastic-cloud.yaml
   read -rs EC_KEY && printf '%s' "$EC_KEY" | \
     pulumi env set <org>/agent-memory/elastic-cloud elastic.apiKey --secret -f -

   # or, inside a Docker Sandbox, bind it on the host (see ../kit/README.md)
   sbx secret set -g elastic-cloud
   ```

## Deploy

With a Pulumi Cloud stack (on your machine):

```bash
cd infra
pulumi stack init <org>/dev            # Pulumi.dev.yaml imports agent-memory/elastic-cloud
pulumi config set agent_id claude      # optional: BRIDGE_AGENT_ID, prefixes the entity indices
pulumi config set region aws-us-east-1 # optional
pulumi up
../scripts/write-env.sh                # writes ../.env from the stack outputs
../bridge status
```

With a local state backend (the default inside the Docker Sandboxes kit):

```bash
export AGENT_MEMORY_BACKEND=local      # the kit sets this for you
scripts/pulumi.sh preview              # from the repo root
scripts/pulumi.sh up
scripts/write-env.sh
bridge status
```

`scripts/pulumi.sh` keeps state in `infra/.pulumi-state` (stack `local`,
gitignored) and runs Pulumi inside `pulumi env run <you>/agent-memory/elastic-cloud`,
so `EC_API_KEY` and `PULUMI_CONFIG_PASSPHRASE` come from ESC. Set
`AGENT_MEMORY_ESC_ENV` to use another environment. Why the sandbox needs this:
[`../kit/README.md`](../kit/README.md#known-issue-pulumi-up-and-the-proxy-managed-pulumi-token).

Project creation takes about a minute. The first write to a `semantic_text`
field can take a few seconds while the inference endpoint warms up.

## Outputs

| Output | |
|---|---|
| `elasticsearch_url`, `kibana_url` | project endpoints |
| `dashboard_url` | the Agent Memory overview in Kibana |
| `bridge_api_key` (secret) | the scoped key |
| `dotenv` (secret) | a ready `.env`; `scripts/write-env.sh` merges it into `../.env` |
| `mcp_url`, `mcp_api_key` (secret) | Agent Builder MCP endpoint and its read-only key; `scripts/write-env.sh` puts the host and key into `../.claude/settings.local.json` for the `elastic-memory` server in `.mcp.json` |

## Config

| Key | Default | |
|---|---|---|
| `project_name` | `agent-memory` | Serverless project name |
| `region` | `aws-us-east-1` | Elastic Cloud region (`GET https://api.elastic-cloud.com/api/v1/serverless/regions`) |
| `agent_id` | `claude` | `BRIDGE_AGENT_ID`; lowercase, becomes an index prefix |
| `embedding_inference_id` | `.jina-embeddings-v5-text-small` | inference endpoint behind the `semantic_text` fields |

## Tear down

```bash
pulumi destroy
```

The indices set `deletion_protection = false`, so destroy removes them in one
pass along with the project.

## Notes

- `elastic/elasticstack` is pinned to `0.16.0`. From `0.16.1` on, the provider
  ships `elasticsearch_query_ruleset`, whose `_id` output the dynamic Terraform
  bridge can't map yet, and `pulumi install` fails.
- The project's admin credentials only exist in state (as secrets) and are
  used by the `elasticstack` provider. Nothing outside the stack gets them.
- Kibana's dashboards API no longer accepts a `treemap` panel, so "Memory by
  Type" is a `pie`. Its `config_json` spells out the defaults Kibana fills in
  (legend, styling, colors); with 0.16.0 anything left implicit shows up as
  drift on every preview.
