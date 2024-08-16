variable "region" {
  description = "AWS Deployment region"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private Subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "msk_cluster_bootstrap" {
  type = string
}

variable "connector_iam_role" {
  description = "Connector IAM role"
  type        = string
}

variable "s3_bucket_name" {
  description = "Owner email for tag"
  type        = string
}

variable "msk_plugin_file" {
  description = "Owner email for tag"
  type        = string
}

variable "mongo_username" {
  description = "Mongo connect string"
  type        = string
}

variable "mongo_password" {
  description = "Mongo connect string"
  type        = string
}

variable "mongo_hostname" {
  description = "Mongo connect string"
  type        = string
}
