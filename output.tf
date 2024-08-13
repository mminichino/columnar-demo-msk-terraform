output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "node_public" {
    value = aws_instance.admin_host.public_ip
}

output "cluster_arn" {
  value = aws_msk_cluster.kafka.arn
}

output "current_version" {
  value = aws_msk_cluster.kafka.current_version
}
