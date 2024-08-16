#
#

module "cluster" {
  source = "./modules/cluster"
  availability_zones = var.availability_zones
  environment = var.environment
  msk_password = var.msk_password
  msk_user = var.msk_user
  owner_email = var.owner_email
  private_subnets_cidr = var.private_subnets_cidr
  public_subnets_cidr = var.public_subnets_cidr
  region = var.region
  ssh_public_key = var.ssh_public_key
  vpc_cidr = var.vpc_cidr
}

module "connector" {
  source = "./modules/connector"
  connector_iam_role = var.connector_iam_role
  environment = var.environment
  mongo_hostname = var.mongo_hostname
  mongo_password = var.mongo_password
  mongo_username = var.mongo_username
  msk_plugin_zip = var.msk_plugin_zip
  region = var.region
  s3_bucket_name = var.s3_bucket_name
  vpc_id = module.cluster.vpc_id
  security_group_id = module.cluster.security_group_id
  msk_cluster_bootstrap = module.cluster.bootstrap_brokers_iam
  private_subnets = module.cluster.private_subnets
}

module "configure" {
  source = "./modules/configure"
  msk_cluster_name = module.cluster.cluster_name
  msk_cluster_arn = module.cluster.cluster_arn
  msk_cluster_id = module.cluster.cluster_id
  msk_configuration_name = module.cluster.config_name
  msk_connector_id = module.connector.connector_id
  region = var.region
}
