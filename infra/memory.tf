# The seven indices the bridge CLI writes to, plus the curation workflow's
# decision log. Field sets mirror what lib/*.sh and curation.tf index, so
# Pulumi owns the whole schema instead of dynamic mapping.
locals {
  keyword  = { type = "keyword" }
  text     = { type = "text" }
  date     = { type = "date" }
  boolean  = { type = "boolean" }
  float    = { type = "float" }
  text_kw  = { type = "text", fields = { keyword = { type = "keyword" } } }
  semantic = { type = "semantic_text", inference_id = var.embedding_inference_id }

  indices = {
    "agent-memory" = {
      memory_id        = local.keyword
      agent            = local.keyword
      type             = local.keyword
      category         = local.keyword
      title            = local.text_kw
      title_semantic   = local.semantic
      content          = local.text
      content_semantic = local.semantic
      tags             = local.keyword
      source           = local.keyword
      access_scope     = local.keyword
      supersedes       = local.keyword
      created_at       = local.date
      updated_at       = local.date
      # Set by the memory-curation workflow (curation.tf)
      status        = local.keyword
      superseded_by = local.keyword
      superseded_at = local.date
      curated_at    = local.date
      needs_review  = local.boolean
      review_reason = local.keyword
      review_with   = local.keyword
      duplicate_of  = local.keyword
      subsumed_by   = local.keyword
    }

    # One document per (new memory, older neighbour) pair the curation workflow judged:
    # Jev's raw votes, so thresholds can be tuned and decisions audited in Kibana.
    "agent-curation" = {
      execution_id    = local.keyword
      at              = local.date
      new_id          = local.keyword
      candidate_id    = local.keyword
      candidate_score = local.float
      model           = local.keyword
      answers         = { type = "object" }
      # superseded | review | duplicate | candidate_subsumed | new_subsumed | none
      outcome       = local.keyword
      review_reason = local.keyword
    }

    "agent-messages" = {
      message_id       = local.keyword
      thread_id        = local.keyword
      in_reply_to      = local.keyword
      from_agent       = local.keyword
      to_agent         = local.keyword
      type             = local.keyword
      status           = local.keyword
      priority         = local.keyword
      subject          = local.text_kw
      subject_semantic = local.text
      body             = local.text
      body_semantic    = local.text
      tags             = local.keyword
      machine          = local.keyword
      created_at       = local.date
      read_at          = local.date
    }

    "agent-sessions" = {
      session_id       = local.keyword
      agent            = local.keyword
      machine          = local.keyword
      action           = local.keyword
      summary          = local.text
      summary_semantic = local.text
      files_touched    = local.keyword
      tags             = local.keyword
      task_id          = local.keyword
      timestamp        = local.date
    }

    "agent-tasks" = {
      task_id        = local.keyword
      parent_task_id = local.keyword
      agent          = local.keyword
      machine        = local.keyword
      title          = local.text
      title_semantic = local.text
      description    = local.text
      status         = local.keyword
      priority       = local.keyword
      tags           = local.keyword
      outcome        = local.text
      created_at     = local.date
      updated_at     = local.date
      completed_at   = local.date
    }

    "agent-status" = {
      agent           = local.keyword
      machine         = local.keyword
      status          = local.keyword
      current_task_id = local.keyword
      last_heartbeat  = local.date
    }

    "${var.agent_id}-entities" = {
      entity_id        = local.keyword
      agent            = local.keyword
      entity_type      = local.keyword
      title            = local.text_kw
      title_semantic   = local.semantic
      content          = local.text
      content_semantic = local.semantic
      status           = local.keyword
      priority         = local.keyword
      initiative       = local.keyword
      tags             = local.keyword
      source_path      = local.keyword
      summary          = local.text
      created_at       = local.date
      updated_at       = local.date
    }

    "${var.agent_id}-entity-history" = {
      event_id    = local.keyword
      entity_id   = local.keyword
      entity_type = local.keyword
      title       = local.keyword
      status      = local.keyword
      snapshot_at = local.date
    }
  }
}

resource "elasticstack_elasticsearch_index" "memory" {
  for_each = local.indices

  name     = each.key
  mappings = jsonencode({ properties = each.value })

  # Demo stack: let `pulumi destroy` remove the indices without a two-step apply.
  deletion_protection = false
}

# A key scoped to exactly these indices. This is what the bridge CLI (and the
# Claude Code hooks) use; the admin credentials never leave the stack.
resource "elasticstack_elasticsearch_security_api_key" "bridge" {
  name = "agent-memory-${var.agent_id}"

  role_descriptors = jsonencode({
    agent_memory = {
      cluster = ["monitor", "monitor_inference"]
      indices = [{
        names      = keys(local.indices)
        privileges = ["all"]
      }]
    }
  })

  metadata = jsonencode({
    managed_by = "pulumi"
    agent      = var.agent_id
  })

  depends_on = [elasticstack_elasticsearch_index.memory]
}
