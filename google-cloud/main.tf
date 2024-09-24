#reference - https://cloud.google.com/network-connectivity/docs/vpn/how-to/automate-vpn-setup-with-terraform
#specify the providers that will be used
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>5"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~>4"
    }
  }

}
#we are using Google Cloud Provider
provider "google" {
  project = var.project
  region  = var.region
}

#GCS bucket for state storage
terraform {
  backend "gcs" {
    bucket = "gpmgcp3q24"
    prefix = "terraform/state"
  }
}

#enable the required services for this project
resource "google_project_service" "project" {
  project = var.project

  for_each = toset(var.services)
  service  = each.value

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

#Create the VPC that will function as OnPrem network
resource "google_compute_network" "vpc_on_prem" {
  project                 = var.project
  name                    = var.vpc_on_prem
  auto_create_subnetworks = false
  mtu                     = 1460
}

#Create a subnet allocation for OnPrem VPC
resource "google_compute_subnetwork" "snet_on_prem" {
  name          = var.subnet_on_prem
  ip_cidr_range = var.subnet_cidr_on_prem
  region        = var.region
  network       = google_compute_network.vpc_on_prem.id
  depends_on    = [google_compute_network.vpc_on_prem]
}

#Create a VPC in Google for our migrated workload
resource "google_compute_network" "vpc_google" {
  project                 = var.project
  name                    = var.vpc_google
  auto_create_subnetworks = false
  mtu                     = 1460
}

#Create a subnet in Google for our migrated workload
resource "google_compute_subnetwork" "snet_google" {
  name          = var.subnet_google
  ip_cidr_range = var.subnet_cidr_google
  region        = var.region
  network       = google_compute_network.vpc_google.id
  depends_on    = [google_compute_network.vpc_google]
}

#Private IP address for Cloud SQL instances
resource "google_compute_global_address" "private_ip_address" {
  provider      = google-beta
  project       = var.project
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_google.id
  depends_on    = [google_compute_network.vpc_google]
}

#Private VPC connection for access to Cloud SQL with Private instance
resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.vpc_google.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

#Create the On-Prem router 
resource "google_compute_router" "onprem_router" {
  name       = var.router_on_prem
  network    = google_compute_network.vpc_on_prem.name
  depends_on = [google_compute_network.vpc_on_prem]
  bgp {
    asn               = var.router_asn_on_prem
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = var.subnet_cidr_on_prem
    }
  }
}

#Create the Google Cloud router 
resource "google_compute_router" "router_google" {
  name       = var.router_google
  network    = google_compute_network.vpc_google.name
  depends_on = [google_compute_network.vpc_google]
  bgp {
    asn               = var.router_asn_google
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = var.subnet_cidr_google
    }
  }
}

#Create the OnPrem VPN Gwy
resource "google_compute_ha_vpn_gateway" "ha_gwy_onprem" {
  region     = var.region
  name       = var.vpn_ha_gwy_on_prem
  network    = google_compute_network.vpc_on_prem.id
  depends_on = [google_compute_network.vpc_on_prem]
  stack_type = "IPV4_ONLY"
}

#Create the Google VPN Gwy
resource "google_compute_ha_vpn_gateway" "ha_gwy_google" {
  region     = var.region
  name       = var.vpn_ha_gwy_google
  network    = google_compute_network.vpc_google.id
  depends_on = [google_compute_network.vpc_google]
  stack_type = "IPV4_ONLY"
}

#Create tunnel 1 for On Prem Router
resource "google_compute_vpn_tunnel" "onprem_tunnel1" {
  name   = var.tunnels_onprem[0]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_google.id
  shared_secret         = var.secret_message
  router                = google_compute_router.onprem_router.id
  vpn_gateway_interface = 0
  depends_on            = [google_compute_router.onprem_router]
}

#Create tunnel 2 for On Prem Router
resource "google_compute_vpn_tunnel" "onprem_tunnel2" {
  name   = var.tunnels_onprem[1]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_google.id
  shared_secret         = var.secret_message
  router                = google_compute_router.onprem_router.id
  vpn_gateway_interface = 1
  depends_on            = [google_compute_router.onprem_router]
}

#Create tunnel 1 for Google Router
resource "google_compute_vpn_tunnel" "google_tunnel1" {
  name   = var.tunnels_google[0]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_google.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  shared_secret         = var.secret_message
  router                = google_compute_router.router_google.id
  vpn_gateway_interface = 0
  depends_on            = [google_compute_router.router_google]
}

#Create tunnel 2 for Google Router
resource "google_compute_vpn_tunnel" "google_tunnel2" {
  name   = var.tunnels_google[1]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_google.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  shared_secret         = var.secret_message
  router                = google_compute_router.router_google.id
  vpn_gateway_interface = 1
  depends_on            = [google_compute_router.router_google]
}

#Create Router Interface 1 for OnPrem Router
resource "google_compute_router_interface" "onprem_router_interface1" {
  name       = var.router_interface_onprem[0]
  router     = google_compute_router.onprem_router.name
  region     = var.region
  ip_range   = var.onprem_router_ip_range[0]
  vpn_tunnel = google_compute_vpn_tunnel.onprem_tunnel1.name
  depends_on = [google_compute_router.onprem_router]
}

#Create OnPrem Router's Peer 1
resource "google_compute_router_peer" "onprem_router_peer1" {
  name                      = var.router_peer_onprem[0]
  router                    = google_compute_router.onprem_router.name
  region                    = var.region
  peer_ip_address           = var.onprem_router_peer_ip_address[0]
  peer_asn                  = var.router_asn_google
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.onprem_router_interface1.name
  depends_on                = [google_compute_router_interface.onprem_router_interface1]
}

#Create Router Interface 2 for OnPrem Router
resource "google_compute_router_interface" "onprem_router_interface2" {
  name       = var.router_interface_onprem[1]
  router     = google_compute_router.onprem_router.name
  region     = var.region
  ip_range   = var.onprem_router_ip_range[1]
  vpn_tunnel = google_compute_vpn_tunnel.onprem_tunnel2.name
  depends_on = [google_compute_router.onprem_router]
}

#Create OnPrem Router's Peer 2
resource "google_compute_router_peer" "onprem_router_peer2" {
  name                      = var.router_peer_onprem[1]
  router                    = google_compute_router.onprem_router.name
  region                    = var.region
  peer_ip_address           = var.onprem_router_peer_ip_address[1]
  peer_asn                  = var.router_asn_google
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.onprem_router_interface2.name
  depends_on                = [google_compute_router_interface.onprem_router_interface2]
}

#Create Router Interface 1 for Google Router
resource "google_compute_router_interface" "router_google_interface1" {
  name       = var.router_interface_google[0]
  router     = google_compute_router.router_google.name
  region     = var.region
  ip_range   = var.google_router_ip_range[0]
  vpn_tunnel = google_compute_vpn_tunnel.google_tunnel1.name
  depends_on = [google_compute_router.router_google]
}

#Create Google Router's Peer 1
resource "google_compute_router_peer" "router_google_peer1" {
  name                      = var.router_peer_google[0]
  router                    = google_compute_router.router_google.name
  region                    = var.region
  peer_ip_address           = var.google_router_peer_ip_address[0]
  peer_asn                  = var.router_asn_on_prem
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_google_interface1.name
  depends_on                = [google_compute_router_interface.router_google_interface1]
}

#Create Router Interface 2 for Google Router
resource "google_compute_router_interface" "router_google_interface2" {
  name       = var.router_interface_google[1]
  router     = google_compute_router.router_google.name
  region     = var.region
  ip_range   = var.google_router_ip_range[1]
  vpn_tunnel = google_compute_vpn_tunnel.google_tunnel2.name
  depends_on = [google_compute_router.router_google]
}

#Create Google Router's Peer 2
resource "google_compute_router_peer" "router_google_peer2" {
  name                      = var.router_peer_google[1]
  router                    = google_compute_router.router_google.name
  region                    = var.region
  peer_ip_address           = var.google_router_peer_ip_address[1]
  peer_asn                  = var.router_asn_on_prem
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_google_interface2.name
  depends_on                = [google_compute_router_interface.router_google_interface2]
}

#Create the compute engine to mimic OnPrem MySQL instance
resource "google_compute_instance" "default-mysql" {
  name         = "instance-mysql"
  machine_type = "n2-standard-4"
  zone         = "us-central1-a"

  tags = ["mysql"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2204-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network    = var.vpc_on_prem
    subnetwork = var.subnet_on_prem
    #to enable external IP address and enable outside connectivity
    access_config {
      // Ephemeral IP
    }
  }
  depends_on = [google_compute_network.vpc_on_prem]
  metadata = {
    startup-script = file("startupscript")
  }

}

#Create firewall for allowing access to OnPrem VPC resources
resource "google_compute_firewall" "default" {
  name       = "firewall-onprem"
  network    = var.vpc_on_prem
  depends_on = [google_compute_network.vpc_on_prem]
  allow {
    protocol = "tcp"
    ports    = ["22", "3306"]
  }

  target_tags   = ["mysql"]
  source_ranges = ["0.0.0.0/0"]
}

/*
#Create the instance that will be Cloud SQL migrated version of OnPrem Instance
resource "google_sql_database" "database" {
  name     = "order-mgmt"
  instance = google_sql_database_instance.instance.name
}
*/
# See versions at https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#database_version
#Create the instance for Cloud SQL
resource "google_sql_database_instance" "instance" {
  name             = "order-mgmt"
  region           = var.region
  database_version = "MYSQL_8_0"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc_google.id
      enable_private_path_for_google_cloud_services = true
    }
  }

  deletion_protection = "false"
}
/*
#Create the user for Cloud SQL Instance
resource "google_sql_user" "users" {
  name       = "root"
  instance   = google_sql_database_instance.instance.name
  host       = "%"
  password   = "passw0rd"
  depends_on = [google_sql_database_instance.instance]
}
*/