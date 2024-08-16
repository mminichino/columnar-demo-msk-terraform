##
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

data "aws_msk_configuration" "cluster" {
  name = var.msk_configuration_name
}

resource "terraform_data" "enable_public_access" {
  triggers_replace = [
    var.msk_cluster_id
  ]
  provisioner "local-exec" {
    command = "aws kafka update-connectivity --cluster-arn ${var.msk_cluster_arn} --current-version ${var.msk_cluster_version} --connectivity-info '{\"PublicAccess\": {\"Type\": \"SERVICE_PROVIDED_EIPS\"}}' --region ${var.region}"
  }
}
