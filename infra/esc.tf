# Everything an agent needs at runtime, as a Pulumi ESC environment instead of
# .env files:
#
#   pulumi env run <org>/agent-memory/runtime -- claude
#
# In Docker Sandboxes the two keys stay on the host: `sbx secret set-custom
# --command "pulumi env get ... --show-secrets"` resolves them from here and the
# sandbox only sees placeholders (kit/README.md).
provider "pulumiservice" {
  # The provider defaults to PULUMI_BACKEND_URL, which is file:// when
  # scripts/pulumi.sh runs with the local state backend.
  api_url = "https://api.pulumi.com"
}

locals {
  kibana_host = trimprefix(ec_elasticsearch_project.memory.endpoints.kibana, "https://")

  runtime_environment = {
    values = {
      elastic = {
        esUrl        = ec_elasticsearch_project.memory.endpoints.elasticsearch
        kibanaUrl    = ec_elasticsearch_project.memory.endpoints.kibana
        kibanaHost   = local.kibana_host
        agentId      = var.agent_id
        bridgeApiKey = { "fn::secret" = elasticstack_elasticsearch_security_api_key.bridge.encoded }
        mcpApiKey    = { "fn::secret" = elasticstack_elasticsearch_security_api_key.mcp.encoded }
      }
      environmentVariables = {
        BRIDGE_ES_URL               = "$${elastic.esUrl}"
        BRIDGE_AGENT_ID             = "$${elastic.agentId}"
        BRIDGE_ENTITY_INDEX         = "${var.agent_id}-entities"
        BRIDGE_ENTITY_HISTORY_INDEX = "${var.agent_id}-entity-history"
        KIBANA_URL                  = "$${elastic.kibanaUrl}"
        ELASTIC_KIBANA_HOST         = "$${elastic.kibanaHost}"
        BRIDGE_ES_API_KEY           = "$${elastic.bridgeApiKey}"
        ELASTIC_MCP_API_KEY         = "$${elastic.mcpApiKey}"
      }
    }
  }
}

resource "pulumiservice_environment" "runtime" {
  organization = var.esc_organization
  project      = var.esc_project
  name         = var.esc_environment
  yaml         = stringasset(yamlencode(local.runtime_environment))
}

output "esc_environment" {
  value = "${var.esc_organization}/${var.esc_project}/${var.esc_environment}"
}
