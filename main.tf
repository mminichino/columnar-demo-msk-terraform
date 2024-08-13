provider "aws" {
  region  = var.region
  profile = var.aws_auth_profile
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name = "name"
    values = ["al2023-ami-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
}

data "aws_s3_object" "file_name" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = var.msk_plugin_zip
}

data "aws_iam_role" "connector_role" {
  name = var.connector_iam_role
}

resource "aws_key_pair" "admin_key" {
  key_name   = "${var.environment}-ssh-key"
  public_key = file(var.ssh_public_key)
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    user        = var.owner_email
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    user        = var.owner_email
  }
}

resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.ig]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name        = "nat"
    Environment = var.environment
    user        = var.owner_email
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr,   count.index)
  availability_zone       = element(var.availability_zones,   count.index)
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = var.environment
    Tier        = "Public"
    user        = var.owner_email
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones,   count.index)
  map_public_ip_on_launch = false
  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = var.environment
    Tier        = "Private"
    user        = var.owner_email
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = var.environment
    user        = var.owner_email
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = var.environment
    user        = var.owner_email
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow network traffic from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9194
    to_port     = 9194
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9196
    to_port     = 9196
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9198
    to_port     = 9198
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_subnets_cidr
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.public_subnets_cidr
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = var.environment
    user        = var.owner_email
  }
}

#################
# Kafka Cluster
#################

resource "aws_kms_key" "kafka_kms_key" {
  description = "Key for Apache Kafka"
}

resource "aws_cloudwatch_log_group" "kafka_log_group" {
  name = "${var.environment}-msk-log-group"
}

resource "aws_msk_configuration" "kafka_config" {
  kafka_versions    = ["3.5.1"] 
  name              = "${var.environment}-msk-config"
  server_properties = <<EOF
auto.create.topics.enable = true
delete.topic.enable = true
allow.everyone.if.no.acl.found = true
EOF
}

resource "aws_msk_scram_secret_association" "secret_association" {
  cluster_arn     = aws_msk_cluster.kafka.arn
  secret_arn_list = [aws_secretsmanager_secret.aws_secret.arn]

  depends_on = [aws_secretsmanager_secret_version.msk_secret]
}

resource "aws_secretsmanager_secret" "aws_secret" {
  name       = "AmazonMSK_${var.environment}"
  kms_key_id = aws_kms_key.kafka_kms_key.key_id
}

resource "aws_secretsmanager_secret_version" "msk_secret" {
  secret_id     = aws_secretsmanager_secret.aws_secret.id
  secret_string = jsonencode({ username = var.msk_user, password = var.msk_password })
}

data "aws_iam_policy_document" "example" {
  statement {
    sid    = "AWSKafkaResourcePolicy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["kafka.amazonaws.com"]
    }

    actions   = ["secretsmanager:getSecretValue"]
    resources = [aws_secretsmanager_secret.aws_secret.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "example" {
  secret_arn = aws_secretsmanager_secret.aws_secret.arn
  policy     = data.aws_iam_policy_document.example.json
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = "${var.environment}-msk-cluster"
  kafka_version          = "3.5.1"
  number_of_broker_nodes = length(var.availability_zones)

  broker_node_group_info {
    instance_type = "kafka.m7g.xlarge"
    client_subnets = aws_subnet.public_subnet.*.id
    security_groups = [aws_security_group.default.id]

    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }

    connectivity_info {
      public_access {
        type = "DISABLED"
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
    }
    encryption_at_rest_kms_key_arn = aws_kms_key.kafka_kms_key.arn
  }

  client_authentication {
    sasl {
      iam = true
      scram = true
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.kafka_config.arn
    revision = aws_msk_configuration.kafka_config.latest_revision
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.kafka_log_group.name
      }
    }
  }

  tags = {
    Environment = var.environment
    user        = var.owner_email
  }
}

###############
# Admin Server
###############

resource "aws_instance" "admin_host" {
  depends_on             = [aws_msk_cluster.kafka]
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "m5.xlarge"
  key_name               = aws_key_pair.admin_key.key_name
  subnet_id              = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [aws_security_group.default.id]
  user_data = templatefile("adminhost.tftpl", {
    bootstrap_server_1 = split(",", aws_msk_cluster.kafka.bootstrap_brokers_sasl_scram)[0]
    bootstrap_server_2 = split(",", aws_msk_cluster.kafka.bootstrap_brokers_sasl_scram)[1]
    bootstrap_server_3 = split(",", aws_msk_cluster.kafka.bootstrap_brokers_sasl_scram)[2]
    msk_user_name      = var.msk_user
    msk_user_pass      = var.msk_password
  })
  root_block_device {
    volume_type = "gp3"
    volume_size = 256
  }
  tags = {
    Name        = "${var.environment}-admin-host"
    Environment = var.environment
    user        = var.owner_email
  }
}

############
# Connector
############

resource "aws_cloudwatch_log_group" "connector_log_group" {
  name = "${var.environment}-connector-log-group"
}

resource "aws_mskconnect_custom_plugin" "debezium_plugin" {
  name         = "${var.environment}-debezium-plugin"
  content_type = "ZIP"
  location {
    s3 {
      bucket_arn = data.aws_s3_bucket.bucket.arn
      file_key   = data.aws_s3_object.file_name.key
    }
  }
}

resource "aws_mskconnect_worker_configuration" "kafka_worker_config" {
  name                    = "${var.environment}-msk-worker-config"
  properties_file_content = <<EOT
key.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter=org.apache.kafka.connect.json.JsonConverter
value.converter.schemas.enable=false
EOT
}

resource "aws_mskconnect_connector" "src_connector" {
  depends_on = [
    data.aws_iam_role.connector_role,
    aws_mskconnect_custom_plugin.debezium_plugin
  ]
  name  = "${var.environment}-src-connector"

  kafkaconnect_version = "2.7.1"

  capacity {
    autoscaling {
      mcu_count        = 1
      min_worker_count = 1
      max_worker_count = 2

      scale_in_policy {
        cpu_utilization_percentage = 20
      }

      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  connector_configuration = {
    "connector.class"                               = "io.debezium.connector.mongodb.MongoDbConnector"
    "capture.mode"                                  = "change_streams_update_full"
    "mongodb.ssl.enabled"                           = true
    "value.converter"                               = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter.schemas.enable"                = false
    "key.converter.schemas.enable"                  = false
    "key.converter"                                 = "org.apache.kafka.connect.storage.StringConverter"
    "offset.flush.interval.ms"                      = 5000
    "topic.creation.default.partitions"             = "-1"
    "topic.creation.default.replication.factor"     = "-1"
    "topic.prefix"                                  = "mongo"
    "collection.include.list"                       = join(",", var.collection_list)
    "mongodb.connection.string"                     = "mongodb+srv://${var.mongo_username}:${var.mongo_password}@${var.mongo_hostname}"
    "tasks.max"                                     = 1
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.kafka.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.default.id]
        subnets         = aws_subnet.private_subnet.*.id
      }
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.connector_log_group.name
      }
    }
  }

  worker_configuration {
    arn      = aws_mskconnect_worker_configuration.kafka_worker_config.arn
    revision = aws_mskconnect_worker_configuration.kafka_worker_config.latest_revision
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.debezium_plugin.arn
      revision = aws_mskconnect_custom_plugin.debezium_plugin.latest_revision
    }
  }

  service_execution_role_arn = data.aws_iam_role.connector_role.arn
}
