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
  type        = list(string)
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "The CIDR block for the private subnet"
}

variable "availability_zones" {
  type        = list(string)
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

variable "msk_user" {
  description = "Username for MSK"
  type        = string
}

variable "msk_password" {
  description = "Password for MSK"
  type        = string
}
