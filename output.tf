output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "node_public" {
    value = "${aws_instance.admin_host.public_ip}"
}
