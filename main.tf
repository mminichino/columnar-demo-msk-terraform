#
#
provider "aws" {
  alias = "primary"
  region  = var.aws_region
}

module "cluster" {
  source = "./modules/cluster"
  providers = {
    aws = aws.primary
  }
  availability_zones = var.aws_availability_zones
  environment = var.kafka_environment
  owner_email = var.owner_email_tag
  private_subnets_cidr = var.aws_private_subnets_cidr
  public_subnets_cidr = var.aws_public_subnets_cidr
  region = var.aws_region
  ssh_public_key = var.admin_ssh_public_key
  vpc_cidr = var.aws_vpc_cidr
}

module "connector" {
  source = "./modules/connector"
  providers = {
    aws = aws.primary
  }
  connector_iam_role = var.connector_aws_iam_role
  environment = var.kafka_environment
  mongo_hostname = var.mongodb_hostname
  mongo_password = var.mongodb_password
  mongo_username = var.mongodb_username
  msk_plugin_file = var.plugin_file_name
  region = var.aws_region
  s3_bucket_name = var.plugin_bucket_name
  vpc_id = module.cluster.vpc_id
  security_group_id = module.cluster.security_group_id
  msk_cluster_bootstrap = module.cluster.bootstrap_brokers_iam
  private_subnets = module.cluster.private_subnets
  depends_on = [module.cluster]
}

# module "configure" {
#   source = "./modules/configure"
#   providers = {
#     aws = aws.primary
#   }
#   msk_cluster_name = module.cluster.cluster_name
#   msk_cluster_arn = module.cluster.cluster_arn
#   msk_cluster_id = module.cluster.cluster_id
#   msk_configuration_name = module.cluster.config_name
#   msk_connector_id = module.connector.connector_id
#   msk_cluster_version = module.cluster.current_version
#   region = var.aws_region
#   depends_on = [ module.cluster, module.connector]
# }
