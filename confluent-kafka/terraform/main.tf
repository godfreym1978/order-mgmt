#set the following environment variables to get it running
# export CONFLUENT_CLOUD_API_KEY="<cloud_api_key>"
# export CONFLUENT_CLOUD_API_SECRET="<cloud_api_secret>"
# terraform import confluent_environment.my_env env-abc123

# Configure the Confluent Provider
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.2.0"
    }
  }
}

/*
variable "confluent_cloud_api_key" {
  
}

variable "confluent_cloud_api_secret" {
  
}
*/
# Option #1: Manage multiple clusters in the same Terraform workspace
provider "confluent" {
  //cloud_api_key    = "${var.confluent_cloud_api_key}"    # optionally use CONFLUENT_CLOUD_API_KEY env var
  //cloud_api_secret = "${var.confluent_cloud_api_secret}" # optionally use CONFLUENT_CLOUD_API_SECRET env var

}

#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_environment
resource "confluent_environment" "development" {
  display_name = var.environment

  stream_governance {
    package = var.stream_gov_package
  }

  lifecycle {
    prevent_destroy = false
  }
}

/* If peering between Confluent Cluster VPC and GCP VPC is needed
#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_peering
resource "confluent_network" "gcp-peering" {
  display_name = "GCP Peering Network"
  cloud = "GCP"
  region = "us-central1"
  cidr = "10.2.0.0/16"
  connection_types = ["PEERING"]
  environment {
    id = confluent_environment.development.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_peering" "gcp" {
  display_name = "GCP Peering"
  gcp {
    project = "steam-insight-430414-n9"
    vpc_network = "confluent-vpc"
    #customer_region = "us-central1"
  }
  environment {
    id = confluent_environment.development.id
  }
  network {
    id = confluent_network.gcp-peering.id
  }

  lifecycle {
    prevent_destroy = false
  }
}
*/

#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
resource "confluent_kafka_cluster" "dedicated" {
  display_name = var.display_name
  availability = var.availability
  cloud        = var.cloud
  region       = var.region
  standard {} //GCP Peering does not work with Standard cluster
  /* required if using GCP Peering. It does not work with standard
  network {
    id = confluent_network.gcp-peering.id
  }
  dedicated {
    cku = 2
  }
  */
  environment {
    id = confluent_environment.development.id
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [confluent_environment.development]
}

#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_service_account
resource "confluent_service_account" "orders-app-sa" {
  display_name = var.service_account
  description  = "Service Account for orders app"
  depends_on   = [confluent_kafka_cluster.dedicated]
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = var.service_account_kafka_api_key
  description  = "Kafka API Key that is owned by 'app-manager' service account"

  owner {
    id          = confluent_service_account.orders-app-sa.id
    api_version = confluent_service_account.orders-app-sa.api_version
    kind        = confluent_service_account.orders-app-sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.development.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
  depends_on = [confluent_service_account.orders-app-sa]
}



#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_role_binding
resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.orders-app-sa.id}"
  role_name   = var.role_name
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
  depends_on  = [confluent_kafka_cluster.dedicated, confluent_service_account.orders-app-sa]
}


/*Module to create the topic
#https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_topic
resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name    = "orders"
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
  #basic-cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

*/


resource "confluent_connector" "mysql-cdc-source" {
  environment {
    id = confluent_environment.development.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }

  // Block for custom *sensitive* configuration properties that are labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-source-cdc-debezium.html#configuration-properties
  config_sensitive = {
    "database.password" = var.mysql_password
  }

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-source-cdc-debezium.html#configuration-properties
  config_nonsensitive = {
    "connector.class"                                        = "MySqlCdcSourceV2"
    "name"                                                   = "MySqlCdcSourceV2Connector_0"
    "kafka.auth.mode"                                        = "SERVICE_ACCOUNT"
    "kafka.service.account.id"                               = confluent_service_account.orders-app-sa.id
    "database.hostname"                                      = var.mysql_host
    "database.port"                                          = var.mysql_port
    "database.user"                                          = var.mysql_user
    "database.ssl.mode"                                      = "preferred"
    "output.data.format"                                     = "JSON"
    "output.key.format"                                      = "JSON"
    "json.output.decimal.format"                             = "BASE64"
    "after.state.only"                                       = "true"
    "tombstones.on.delete"                                   = "true"
    "topic.prefix"                                           = var.mysql_topic_prefix
    "snapshot.mode"                                          = "initial"
    "snapshot.locking.mode"                                  = "minimal"
    "database.include.list"                                  = var.mysql_database
    "table.include.list"                                     = var.mysql_table
    "event.processing.failure.handling.mode"                 = "fail"
    "schema.name.adjustment.mode"                            = "none"
    "field.name.adjustment.mode"                             = "none"
    "heartbeat.interval.ms"                                  = "0"
    "inconsistent.schema.handling.mode"                      = "fail"
    "schema.history.internal.skip.unparseable.ddl"           = "false"
    "schema.history.internal.store.only.captured.tables.ddl" = "false"
    "schema.context.name"                                    = "default"
    "decimal.handling.mode"                                  = "precise"
    "time.precision.mode"                                    = "adaptive_time_microseconds"
    "tasks.max"                                              = "1"
  }

  depends_on = [confluent_environment.development, confluent_kafka_cluster.dedicated, confluent_service_account.orders-app-sa]
}


resource "confluent_connector" "mongo-db-source" {
  environment {
    id = confluent_environment.development.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }

  // Block for custom *sensitive* configuration properties that are labelled with "Type= password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-source.html#configuration-properties
  config_sensitive = {
    "connection.password"                            = var.mongodb_conn_pwd
  }

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-source.html#configuration-properties
  config_nonsensitive = {
    
    "connector.class"                                = "MongoDbAtlasSource"
    "name"                                           = "MongoDbAtlasSourceConnector_0"
    "kafka.auth.mode"                                = "SERVICE_ACCOUNT"
    "kafka.service.account.id"                       = confluent_service_account.orders-app-sa.id
    "schema.context.name"                            = "default"
    "topic.prefix"                                   = var.mongodb_topic_prefix
    "connection.host"                                = var.mongodb_conn_host
    "connection.user"                                = var.mongodb_conn_user
    
    "database"                                       = var.mongodb_db
    "collection"                                     = var.mongodb_db_collection
    "poll.await.time.ms"                             = "5000"
    "poll.max.batch.size"                            = "100"
    "pipeline"                                       = "[]"
    "batch.size"                                     = "0"
    "linger.ms"                                      = "0"
    "producer.batch.size"                            = "16384"
    "output.data.format"                             = "JSON"
    "publish.full.document.only"                     = "false"
    "publish.full.document.only.tombstone.on.delete" = "false"
    "json.output.decimal.format"                     = "BASE64"
    "change.stream.full.document"                    = "default"
    "change.stream.full.document.before.change"      = "default"
    "output.json.format"                             = "DefaultJson"
    "topic.separator"                                = "."
    "value.subject.name.strategy"                    = "TopicNameStrategy"
    "output.schema.infer.value"                      = "true"
    "heartbeat.interval.ms"                          = "0"
    "heartbeat.topic.name"                           = "__mongodb_heartbeats"
    "mongo.errors.tolerance"                         = "NONE"
    "server.api.deprecation.errors"                  = "false"
    "server.api.strict"                              = "false"
    "tasks.max"                                      = "1"
    

  }

  depends_on = [confluent_environment.development, confluent_kafka_cluster.dedicated, confluent_service_account.orders-app-sa]
}
