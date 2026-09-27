# The repo's dashboard export stays the single source of truth; each panel's
# config is passed through as-is (markdown and vis panels accept config_json).
locals {
  dashboard = jsondecode(file("${path.module}/../setup/dashboards/agent-memory-overview.json"))
}

resource "elasticstack_kibana_dashboard" "overview" {
  title       = local.dashboard.title
  description = "What your coding agents remember: memories, sessions, tasks and entities."

  time_range = {
    from = local.dashboard.time_range.from
    to   = local.dashboard.time_range.to
  }

  query = {
    language = "kql"
    text     = ""
  }

  refresh_interval = {
    pause = false
    value = 30000
  }

  # Lists of objects are blocks in Pulumi HCL (single objects stay
  # arguments), so generate one panels block per exported panel.
  dynamic "panels" {
    for_each = local.dashboard.panels
    content {
      id          = try(panels.value.id, null)
      type        = panels.value.type
      grid        = panels.value.grid
      config_json = jsonencode(panels.value.config)
    }
  }

  depends_on = [elasticstack_elasticsearch_index.memory]
}
