output "cluster_name" {
  value = aws_msk_cluster.kafka.cluster_name
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnets" {
  value = aws_subnet.private_subnet[*].id
}

output "security_group_id" {
  value = aws_security_group.default.id
}

output "node_public" {
  value = aws_instance.admin_host.public_ip
}

output "cluster_arn" {
  value = aws_msk_cluster.kafka.arn
}

output "cluster_id" {
  value = aws_msk_cluster.kafka.id
}

output "current_version" {
  value = aws_msk_cluster.kafka.current_version
}

output "config_name" {
  value = aws_msk_configuration.kafka_config.name
}

output "bootstrap_brokers_vpc_connectivity_sasl_iam" {
  value = aws_msk_cluster.kafka.bootstrap_brokers_vpc_connectivity_sasl_iam
}

output "bootstrap_brokers_iam" {
  value = aws_msk_cluster.kafka.bootstrap_brokers_sasl_iam
}

output "bootstrap_brokers_public_iam" {
  value = aws_msk_cluster.kafka.bootstrap_brokers_public_sasl_iam
}

output "bootstrap_brokers_public_scram" {
  value = aws_msk_cluster.kafka.bootstrap_brokers_public_sasl_scram
}
