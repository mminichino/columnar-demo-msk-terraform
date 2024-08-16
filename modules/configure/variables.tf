variable "region" {
  type = string
}

variable "msk_cluster_id" {
  description = "Cluster ID"
  type        = string
}

variable "msk_cluster_name" {
  description = "Cluster Name"
  type        = string
}

variable "msk_configuration_name" {
  description = "Config Name"
  type        = string
}

variable "msk_cluster_arn" {
  description = "Cluster ARN"
  type        = string
}
