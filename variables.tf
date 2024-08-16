variable "aws_region" {
  description = "AWS Deployment region"
  type        = string
}

variable "kafka_environment" {
  description = "Environment"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "aws_public_subnets_cidr" {
  type        = list(string)
  description = "The CIDR block for the public subnet"
}

variable "aws_private_subnets_cidr" {
  type        = list(string)
  description = "The CIDR block for the private subnet"
}

variable "aws_availability_zones" {
  type        = list(string)
  description = "The az that the resources will be launched"
}

variable "admin_ssh_public_key" {
  description = "The private key to use when connecting to an instances"
  type        = string
}

variable "owner_email_tag" {
  description = "Owner email for tag"
  type        = string
}

variable "msk_user" {
  description = "Username for MSK"
  type        = string
}

variable "msk_password" {
  description = "Password for MSK"
  type        = string
}

variable "connector_aws_iam_role" {
  description = "Connector IAM role"
  type        = string
}

variable "plugin_bucket_name" {
  description = "Owner email for tag"
  type        = string
}

variable "plugin_file_name" {
  description = "Owner email for tag"
  type        = string
}

variable "mongodb_username" {
  description = "Mongo connect string"
  type        = string
}

variable "mongodb_password" {
  description = "Mongo connect string"
  type        = string
}

variable "mongodb_hostname" {
  description = "Mongo connect string"
  type        = string
}
