#reference - https://cloud.google.com/network-connectivity/docs/vpn/how-to/automate-vpn-setup-with-terraform
#we are using Google Cloud Provider
provider "google" {
  project = var.project
  region  = var.region
}

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
}

#Create the On-Prem router 
resource "google_compute_router" "onprem_router" {
  name    = var.router_on_prem
  network = google_compute_network.vpc_on_prem.name
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
  name    = var.router_google
  network = google_compute_network.vpc_google.name
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
  stack_type = "IPV4_ONLY"
}

#Create the Google VPN Gwy
resource "google_compute_ha_vpn_gateway" "ha_gwy_google" {
  region     = var.region
  name       = var.vpn_ha_gwy_google
  network    = google_compute_network.vpc_google.id
  stack_type = "IPV4_ONLY"
}


resource "google_compute_vpn_tunnel" "onprem_tunnel1" {
  name   = var.tunnels_onprem[0]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_google.id
  shared_secret         = var.secret_message
  router                = google_compute_router.onprem_router.id
  vpn_gateway_interface = 0

}

resource "google_compute_vpn_tunnel" "onprem_tunnel2" {
  name   = var.tunnels_onprem[1]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_google.id
  shared_secret         = var.secret_message
  router                = google_compute_router.onprem_router.id
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "google_tunnel1" {
  name   = var.tunnels_google[0]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_google.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  shared_secret         = var.secret_message
  router                = google_compute_router.router_google.id
  vpn_gateway_interface = 0

}

resource "google_compute_vpn_tunnel" "google_tunnel2" {
  name   = var.tunnels_google[1]
  region = var.region

  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gwy_google.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gwy_onprem.id
  shared_secret         = var.secret_message
  router                = google_compute_router.router_google.id
  vpn_gateway_interface = 1
}

resource "google_compute_router_interface" "onprem_router_interface1" {
  name       = var.router_interface_onprem[0]
  router     = google_compute_router.onprem_router.name
  region     = var.region
  ip_range   = var.onprem_router_ip_range[0]
  vpn_tunnel = google_compute_vpn_tunnel.onprem_tunnel1.name
}

resource "google_compute_router_peer" "onprem_router_peer1" {
  name                      = var.router_peer_onprem[0]
  router                    = google_compute_router.onprem_router.name
  region                    = var.region
  peer_ip_address           = var.onprem_router_peer_ip_address[0]
  peer_asn                  = var.router_asn_google
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.onprem_router_interface1.name
}

resource "google_compute_router_interface" "onprem_router_interface2" {
  name       = var.router_interface_onprem[1]
  router     = google_compute_router.onprem_router.name
  region     = var.region
  ip_range   = var.onprem_router_ip_range[1]
  vpn_tunnel = google_compute_vpn_tunnel.onprem_tunnel2.name
}

resource "google_compute_router_peer" "onprem_router_peer2" {
  name                      = var.router_peer_onprem[1]
  router                    = google_compute_router.onprem_router.name
  region                    = var.region
  peer_ip_address           = var.onprem_router_peer_ip_address[1]
  peer_asn                  = var.router_asn_google
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.onprem_router_interface2.name
}

resource "google_compute_router_interface" "router_google_interface1" {
  name       = var.router_interface_google[0]
  router     = google_compute_router.router_google.name
  region     = var.region
  ip_range   = var.google_router_ip_range[0]
  vpn_tunnel = google_compute_vpn_tunnel.google_tunnel1.name
}

resource "google_compute_router_peer" "router_google_peer1" {
  name                      = var.router_peer_google[0]
  router                    = google_compute_router.router_google.name
  region                    = var.region
  peer_ip_address           = var.google_router_peer_ip_address[0]
  peer_asn                  = var.router_asn_on_prem
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_google_interface1.name
}

resource "google_compute_router_interface" "router_google_interface2" {
  name       = var.router_interface_google[1]
  router     = google_compute_router.router_google.name
  region     = var.region
  ip_range   = var.google_router_ip_range[1]
  vpn_tunnel = google_compute_vpn_tunnel.google_tunnel2.name
}

resource "google_compute_router_peer" "router_google_peer2" {
  name                      = var.router_peer_google[1]
  router                    = google_compute_router.router_google.name
  region                    = var.region
  peer_ip_address           = var.google_router_peer_ip_address[1]
  peer_asn                  = var.router_asn_on_prem
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router_google_interface2.name
}



/*

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
*/
