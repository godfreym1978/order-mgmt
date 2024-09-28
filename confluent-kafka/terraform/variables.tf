variable "environment" {
  type = string
}

variable "stream_gov_package" {
  type = string
}

variable "display_name" {
  type = string
}
variable "availability" {
  type = string
}
variable "cloud" {
  type = string
}
variable "region" {
  type = string
}

variable "service_account" {
  type = string
}

variable "service_account_kafka_api_key" {
  type = string
}

variable "role_name" {
  type = string
}

variable "mysql_host" {
  type = string
}
variable "mysql_port" {
  type = string
}
variable "mysql_user" {
  type = string
}
variable "mysql_password" {
  type = string
}
variable "mysql_topic_prefix" {
  type = string
}
variable "mysql_database" {
  type = string
}
variable "mysql_table" {
  type = string
}


variable "mongodb_topic_prefix" {
  type = string
}
variable "mongodb_conn_host" {
  type = string
}
variable "mongodb_conn_user" {
  type = string
}
variable "mongodb_conn_pwd" {
  type = string
}

variable "mongodb_db" {
  type = string
}


variable "mongodb_db_collection" {
  type = string
}