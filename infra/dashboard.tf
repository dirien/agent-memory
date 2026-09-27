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

  panels = [for panel in local.dashboard.panels : {
    id          = try(panel.id, null)
    type        = panel.type
    grid        = panel.grid
    config_json = jsonencode(panel.config)
  }]

  depends_on = [elasticstack_elasticsearch_index.memory]
}
