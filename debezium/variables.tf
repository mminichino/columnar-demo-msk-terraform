variable "region" {
  description = "AWS Deployment region"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnets_cidr" {
  type        = list
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list
  description = "The CIDR block for the private subnet"
}

variable "availability_zones" {
  type        = list
  description = "The az that the resources will be launched"
}

variable "ssh_public_key" {
  description = "The private key to use when connecting to an instances"
  type        = string
}

variable "owner_email" {
  description = "Owner email for tag"
  type        = string
}

variable "connector_iam_role" {
  description = "Connectlr IAM role"
  type        = string
}

variable "s3_bucket_name" {
  description = "Owner email for tag"
  type        = string
}

variable "msk_plugin_zip" {
  description = "Owner email for tag"
  type        = string
}

variable "collection_list" {
  description = "Mongo collection list"
  type        = list
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
