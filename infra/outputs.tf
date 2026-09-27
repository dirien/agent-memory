output "project_id" {
  value = ec_elasticsearch_project.memory.id
}

output "elasticsearch_url" {
  value = ec_elasticsearch_project.memory.endpoints.elasticsearch
}

output "kibana_url" {
  value = ec_elasticsearch_project.memory.endpoints.kibana
}

output "dashboard_url" {
  value = "${ec_elasticsearch_project.memory.endpoints.kibana}/app/dashboards#/view/${elasticstack_kibana_dashboard.overview.dashboard_id}"
}

output "agent_id" {
  value = var.agent_id
}

output "bridge_api_key" {
  value     = elasticstack_elasticsearch_security_api_key.bridge.encoded
  sensitive = true
}

# Everything the bridge CLI needs, ready to drop into agent-memory's .env:
#   pulumi stack output dotenv --show-secrets > ../.env
output "dotenv" {
  sensitive = true
  value     = <<-EOT
    BRIDGE_ES_URL=${ec_elasticsearch_project.memory.endpoints.elasticsearch}
    BRIDGE_ES_API_KEY=${elasticstack_elasticsearch_security_api_key.bridge.encoded}
    BRIDGE_AGENT_ID=${var.agent_id}
    KIBANA_URL=${ec_elasticsearch_project.memory.endpoints.kibana}
    BRIDGE_ENTITY_INDEX=${var.agent_id}-entities
    BRIDGE_ENTITY_HISTORY_INDEX=${var.agent_id}-entity-history
  EOT
}
