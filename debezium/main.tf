provider "aws" {
  region  = var.region
  profile = var.aws_auth_profile
}

data "aws_iam_role" "connector_role" {
  name = var.connector_iam_role
}

data "aws_msk_cluster" "kafka" {
  cluster_name = "${var.environment}-msk-cluster"
}

data "aws_security_group" "default" {
  name = "${var.environment}-default-sg"
}

data "aws_vpc" "env_vpc" {
  cidr_block = var.vpc_cidr
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.env_vpc.id]
  }

  tags = {
    Tier = "Private"
  }
}

data "aws_cloudwatch_log_group" "log_group" {
  name = "${var.environment}-msk-log-group"
}

data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
}

data "aws_s3_object" "file_name" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = var.msk_plugin_zip
}

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
      "connector.class"                                = "io.debezium.connector.mongodb.MongoDbConnector"
       "capture.mode"                                  = "change_streams_update_full"
       "mongodb.ssl.enabled"                           = true
       "value.converter"                               = "org.apache.kafka.connect.json.JsonConverter"
       "value.converter.schemas.enable"                = false
       "key.converter.schemas.enable"                  = false
       "key.converter"                                 = "org.apache.kafka.connect.json.JsonConverter"
       "offset.flush.interval.ms"                      = "10000"
       "topic.creation.default.partitions"             = "-1"
       "topic.creation.default.replication.factor"     = "-1"
       "topic.prefix"                                  = "mongo"
       "collection.include.list"                       = join(",", var.collection_list)
       "mongodb.connection.string"                     = "mongodb+srv://${var.mongo_username}:${var.mongo_password}@${var.mongo_hostname}"
       "tasks.max"                                     = "1"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = data.aws_msk_cluster.kafka.bootstrap_brokers

      vpc {
        security_groups = [data.aws_security_group.default.id]
        subnets         = data.aws_subnets.subnets.ids
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
    authentication_type = "NONE"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "PLAINTEXT"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.debezium_plugin.arn
      revision = aws_mskconnect_custom_plugin.debezium_plugin.latest_revision
    }
  }

  service_execution_role_arn = data.aws_iam_role.connector_role.arn
}
