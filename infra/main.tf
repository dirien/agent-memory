terraform {
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "0.13.1"
    }
    # 0.16.1+ adds elasticsearch_query_ruleset with a required `_id` attribute,
    # which terraform-provider 1.4.0 rejects (pulumi/pulumi-terraform-provider#117).
    # sdks/elasticstack/hcl.sdk.json pins terraform-provider 1.3.0, which still
    # loads it; don't rerun `pulumi install` until the bridge is fixed, or it
    # re-resolves to 1.4.0 and fails.
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.16.5"
    }
    # Native Pulumi package: writes the ESC environment the agents read.
    pulumiservice = {
      source  = "pulumi/pulumiservice"
      version = "1.4.0"
    }
  }
}

# Reads EC_API_KEY from the environment: a Pulumi ESC environment, or the
# Docker Sandboxes credential proxy (see kit/spec.yaml).
provider "ec" {}

resource "ec_elasticsearch_project" "memory" {
  name          = var.project_name
  region_id     = var.region
  optimized_for = "general_purpose"

  metadata = {
    tags = {
      purpose = "agent-memory"
      managed = "pulumi"
    }
  }
}

# Everything inside the project (indices, API key, dashboard) talks to its
# endpoints with the admin credentials the project returns on create.
provider "elasticstack" {
  elasticsearch {
    endpoints = [ec_elasticsearch_project.memory.endpoints.elasticsearch]
    username  = ec_elasticsearch_project.memory.credentials.username
    password  = ec_elasticsearch_project.memory.credentials.password
  }
  kibana {
    endpoints = [ec_elasticsearch_project.memory.endpoints.kibana]
    username  = ec_elasticsearch_project.memory.credentials.username
    password  = ec_elasticsearch_project.memory.credentials.password
  }
}
