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
