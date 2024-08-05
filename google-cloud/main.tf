provider "google" {
  project     = var.project
  region      = var.region
}



resource "google_project_service" "project" {
  project     = var.project
  
  for_each = toset(var.services)
  service = each.value

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}


resource "google_sql_database" "database" {
  name     = "order-mgmt"
  instance = google_sql_database_instance.instance.name
}

# See versions at https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#database_version
resource "google_sql_database_instance" "instance" {
  name             = "order-mgmt"
  region      = var.region
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
  }

  deletion_protection  = "false"
}


resource "google_sql_user" "users" {
  name     = "root"
  instance = google_sql_database_instance.instance.name
  host     = "%"
  password = "passw0rd"
}