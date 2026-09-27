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

variable "embedding_inference_id" {
  description = "Inference endpoint behind the semantic_text fields. Serverless ships Jina v5 on the Elastic Inference Service."
  type        = string
  default     = ".jina-embeddings-v5-text-small"
}
