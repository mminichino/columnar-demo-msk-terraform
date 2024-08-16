terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
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

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_security_group" "default" {
  id = var.security_group_id
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
    "connector.class"                                 = "com.mongodb.kafka.connect.MongoSourceConnector"
    "tasks.max"                                       = 1
    "connection.uri"                                  = "mongodb+srv://${var.mongo_username}:${var.mongo_password}@${var.mongo_hostname}"
    "batch.size"                                      = 0
    "change.stream.full.document"                     = "default"
    "change.stream.full.document.before.change"       = "default"
    "heartbeat.interval.ms"                           = 0
    "heartbeat.topic.name"                            = "__mongodb_heartbeats"
    "output.format.key"                               = "json"
    "output.format.value"                             = "json"
    "output.json.formatter"                           = "com.mongodb.kafka.connect.source.json.formatter.SimplifiedJson"
    "output.schema.infer.value"                       = true
    "pipeline"                                        = "[]"
    "poll.await.time.ms"                              = 5000
    "poll.max.batch.size"                             = 100
    "publish.full.document.only"                      = true
    "publish.full.document.only.tombstone.on.delete"  = true
    "server.api.deprecationErrors"                    = false
    "server.api.strict"                               = false
    "startup.mode"                                    = "copy_existing"
    "topic.prefix"                                    = "mongo"
    "topic.separator"                                 = "."
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = var.msk_cluster_bootstrap

      vpc {
        security_groups = [data.aws_security_group.default.id]
        subnets         = var.private_subnets
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
