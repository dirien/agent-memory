# Memory curation: a Kibana Workflow (workflows/memory-curation.yaml) that asks
# TypeSafe Jev about every new memory and its nearest older neighbours, then
# supersedes, flags or links them with a Painless rule. Off unless
# typesafe_api_key is set, so a stack without a Jev key gets neither the
# connector nor the workflow.
locals {
  # Only whether a key is set; the key itself stays secret.
  curation_enabled = nonsensitive(var.typesafe_api_key != "")

  jev_connector = {
    name = "typesafe-jev"
    config = {
      url      = "https://api.typesafe.ai"
      hasAuth  = false
      authType = null # Kibana rejects any authType when hasAuth is false
      headers  = { "Content-Type" = "application/json" }
    }
    # Encrypted by Kibana; never returned on read.
    secrets = { secretHeaders = { Authorization = "Bearer ${var.typesafe_api_key}" } }
  }
}

# Workflow http steps only call out through Kibana's .http connector type,
# which elastic/elasticstack can't create (its connector map ends at .webhook),
# so this one object goes through Kibana's connector API directly.
resource "restapi_object" "jev_connector" {
  count = local.curation_enabled ? 1 : 0

  path        = "/api/actions/connector"
  data        = jsonencode(merge(local.jev_connector, { connector_type_id = ".http" }))
  update_data = jsonencode(local.jev_connector) # PUT doesn't accept connector_type_id

  ignore_changes_to       = ["secrets"]
  ignore_server_additions = true
}

resource "elasticstack_kibana_agentbuilder_workflow" "curation" {
  count = local.curation_enabled ? 1 : 0

  configuration_yaml = replace(
    file("workflows/memory-curation.yaml"),
    "__JEV_CONNECTOR_ID__",
    restapi_object.jev_connector[0].id,
  )

  # The workflow searches and updates agent-memory and writes agent-curation.
  depends_on = [elasticstack_elasticsearch_index.memory]
}
