# Read-only key for the Agent Builder MCP server built into Kibana
# ({kibana}/api/agent_builder/mcp). Lets an MCP client such as Claude Code
# search and run ES|QL over the memory indices, nothing else.
resource "elasticstack_elasticsearch_security_api_key" "mcp" {
  name = "agent-memory-mcp-${var.agent_id}"

  role_descriptors = jsonencode({
    agent_memory_mcp = {
      cluster = ["monitor_inference"]
      indices = [{
        names      = keys(local.indices)
        privileges = ["read", "view_index_metadata"]
      }]
      applications = [{
        application = "kibana-.kibana"
        privileges  = ["feature_agentBuilder.read", "feature_actions.read"]
        resources   = ["space:default"]
      }]
    }
  })

  metadata = jsonencode({
    managed_by = "pulumi"
    purpose    = "agent-builder-mcp"
  })

  depends_on = [elasticstack_elasticsearch_index.memory]
}

output "mcp_url" {
  value = "${ec_elasticsearch_project.memory.endpoints.kibana}/api/agent_builder/mcp"
}

output "mcp_api_key" {
  value     = elasticstack_elasticsearch_security_api_key.mcp.encoded
  sensitive = true
}
