output "vpc_id" {
  value = module.cluster.vpc_id
}

output "node_public" {
    value = module.cluster.node_public
}

output "cluster_arn" {
  value = module.cluster.cluster_arn
}

output "current_version" {
  value = module.cluster.current_version
}

output "bootstrap_iam" {
  value = module.cluster.bootstrap_brokers_iam
}

output "bootstrap_vpc_iam" {
  value = module.cluster.bootstrap_brokers_vpc_connectivity_sasl_iam
}
