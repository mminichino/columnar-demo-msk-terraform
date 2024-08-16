terraform {
  required_providers {
    kafka = {
      source  = "Mongey/kafka"
      version = "0.7.1"
    }
  }
}

provider "kafka" {
  bootstrap_servers = split(",", var.msk_cluster_bootstrap)
  tls_enabled       = true
  sasl_mechanism    = "aws-iam"
  sasl_aws_region   = var.region
}

resource "kafka_acl" "allow_all" {
  resource_name       = "allow_all"
  resource_type       = "Any"
  acl_principal       = "User:*"
  acl_host            = "*"
  acl_operation       = "All"
  acl_permission_type = "Allow"
}
