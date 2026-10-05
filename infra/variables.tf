variable "project_name" {
  description = "Name of the Elasticsearch Serverless project"
  type        = string
  default     = "agent-memory"
}

variable "region" {
  description = "Elastic Cloud region for the project (see: GET /api/v1/serverless/regions)"
  type        = string
  default     = "aws-us-east-1"
}

variable "agent_id" {
  description = "Short agent name. Becomes BRIDGE_AGENT_ID and prefixes the entity indices."
  type        = string
  default     = "claude"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,30}$", var.agent_id))
    error_message = "agent_id must be lowercase letters, digits and dashes (it becomes an index name prefix)."
  }
}

variable "esc_organization" {
  description = "Pulumi Cloud organization that owns the runtime ESC environment (agent-memory/runtime)"
  type        = string
}

variable "esc_project" {
  description = "ESC project for the runtime environment"
  type        = string
  default     = "agent-memory"
}

variable "esc_environment" {
  description = "ESC environment name for what agents need at runtime"
  type        = string
  default     = "runtime"
}

variable "embedding_inference_id" {
  description = "Inference endpoint behind the semantic_text fields. Serverless ships Jina v5 on the Elastic Inference Service."
  type        = string
  default     = ".jina-embeddings-v5-text-small"
}

variable "typesafe_api_key" {
  description = "TypeSafe Jev API key for the memory-curation workflow. Empty (the default) skips the Jev connector and the workflow."
  type        = string
  default     = ""
  sensitive   = true
}
